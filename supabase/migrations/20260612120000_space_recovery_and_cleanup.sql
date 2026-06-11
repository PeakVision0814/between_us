begin;

-- ================================================================
-- Space recovery and auto-cleanup
-- ================================================================
-- 1. delete_closed_space(uuid) hard-deletes a closed space and all
--    associated data in FK-safe order. It is used internally by
--    accept_couple_invite to clean up stale closed spaces.
-- 2. accept_couple_invite(text) supports reunion by reactivating a
--    previously closed space between the same two users, while still
--    allowing a fresh pairing to join the inviter's current pending
--    space directly.
-- ================================================================

create or replace function public.delete_closed_space(p_space_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Only allow deleting closed spaces to prevent accidental data loss.
  if not exists (
    select 1
    from public.couple_spaces
    where id = p_space_id
      and status = 'closed'
  ) then
    raise exception 'can only delete closed spaces';
  end if;

  -- Break the circular FK between plans and calendar_events first.
  update public.plans
  set scheduled_event_id = null
  where couple_space_id = p_space_id;

  update public.calendar_events
  set source_plan_id = null
  where couple_space_id = p_space_id;

  -- Delete child tables in FK-safe order.
  delete from public.cycle_records where couple_space_id = p_space_id;
  delete from public.anniversaries where couple_space_id = p_space_id;
  delete from public.couple_space_exit_requests
  where couple_space_id = p_space_id;
  delete from public.notes where couple_space_id = p_space_id;
  delete from public.plans where couple_space_id = p_space_id;
  delete from public.calendar_events where couple_space_id = p_space_id;
  delete from public.couple_invites where couple_space_id = p_space_id;
  delete from public.couple_memberships where couple_space_id = p_space_id;

  delete from public.couple_spaces where id = p_space_id;
end;
$$;

revoke all on function public.delete_closed_space(uuid) from public;
revoke all on function public.delete_closed_space(uuid) from anon;
grant execute on function public.delete_closed_space(uuid) to authenticated;

create or replace function public.accept_couple_invite(
  p_plain_code text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_invite public.couple_invites%rowtype;
  v_existing_space_id uuid;
  v_reactivate_space_id uuid;
  v_inviter_id uuid;
begin
  if auth.uid() is null then
    raise exception 'authentication required';
  end if;

  if not public.is_active_profile(auth.uid()) then
    raise exception 'account deleted';
  end if;

  if p_plain_code is null or btrim(p_plain_code) = '' then
    raise exception 'invite code is required';
  end if;

  -- If the accepting user owns a single-member pending space, close it
  -- first so they can join another relationship space.
  select memberships.couple_space_id
    into v_existing_space_id
  from public.couple_memberships memberships
  where memberships.profile_id = auth.uid()
    and memberships.status = 'active'
    and memberships.left_at is null
  limit 1;

  if v_existing_space_id is not null then
    if exists (
      select 1
      from public.couple_memberships memberships
      join public.couple_spaces spaces
        on spaces.id = memberships.couple_space_id
      where memberships.couple_space_id = v_existing_space_id
        and memberships.profile_id = auth.uid()
        and memberships.role = 'owner'
        and memberships.status = 'active'
        and memberships.left_at is null
        and spaces.status = 'pending_partner'
        and spaces.closed_at is null
        and (
          select count(*)
          from public.couple_memberships active_memberships
          where active_memberships.couple_space_id = memberships.couple_space_id
            and active_memberships.status = 'active'
            and active_memberships.left_at is null
        ) = 1
    ) then
      update public.couple_memberships
      set status = 'left',
          left_at = timezone('utc', now())
      where couple_space_id = v_existing_space_id
        and profile_id = auth.uid()
        and status = 'active'
        and left_at is null;

      update public.couple_spaces
      set status = 'closed',
          closed_at = timezone('utc', now()),
          updated_at = timezone('utc', now())
      where id = v_existing_space_id
        and status = 'pending_partner'
        and closed_at is null;
    else
      raise exception 'user already belongs to an active couple_space';
    end if;
  end if;

  select invites.*
    into v_invite
  from public.couple_invites invites
  join public.couple_spaces spaces
    on spaces.id = invites.couple_space_id
  where invites.code_hash = encode(
          extensions.digest(btrim(p_plain_code), 'sha256'),
          'hex'
        )
    and invites.accepted_at is null
    and invites.revoked_at is null
    and invites.expires_at > timezone('utc', now())
    and spaces.closed_at is null
    and spaces.status in ('pending_partner', 'active')
  for update;

  if not found then
    raise exception 'invite is invalid, expired, or already used';
  end if;

  if (
    select count(*)
    from public.couple_memberships memberships
    where memberships.couple_space_id = v_invite.couple_space_id
      and memberships.status = 'active'
      and memberships.left_at is null
  ) >= 2 then
    raise exception 'couple_space already has two active members';
  end if;

  select spaces.created_by
    into v_inviter_id
  from public.couple_spaces spaces
  where spaces.id = v_invite.couple_space_id;

  -- Check whether these two users already have a closed historical space
  -- that should be reactivated instead of using the new pending invite space.
  select memberships.couple_space_id
    into v_reactivate_space_id
  from public.couple_memberships memberships
  where memberships.profile_id = auth.uid()
    and memberships.status = 'left'
    and memberships.left_at is not null
    and exists (
      select 1
      from public.couple_memberships partner
      where partner.couple_space_id = memberships.couple_space_id
        and partner.profile_id = v_inviter_id
        and partner.status = 'left'
        and partner.left_at is not null
    )
    and exists (
      select 1
      from public.couple_spaces spaces
      where spaces.id = memberships.couple_space_id
        and spaces.status = 'closed'
        and spaces.closed_at is not null
    )
  order by memberships.left_at desc
  limit 1;

  if v_reactivate_space_id is not null then
    -- Preserve the inviter's pending invite space unless reunion is
    -- confirmed. Once reunion is chosen, close both users' current
    -- pending spaces so the old closed space can be reactivated.
    update public.couple_memberships m
    set status = 'left',
        left_at = timezone('utc', now())
    from public.couple_spaces s
    where s.id = m.couple_space_id
      and s.status = 'pending_partner'
      and s.closed_at is null
      and m.status = 'active'
      and m.left_at is null
      and m.profile_id in (auth.uid(), v_inviter_id);

    update public.couple_spaces s
    set status = 'closed',
        closed_at = timezone('utc', now()),
        updated_at = timezone('utc', now())
    where s.status = 'pending_partner'
      and s.closed_at is null
      and not exists (
        select 1
        from public.couple_memberships m
        where m.couple_space_id = s.id
          and m.status = 'active'
          and m.left_at is null
      );

    -- REUNION: reactivate the old closed space.
    update public.couple_spaces
    set status = 'active',
        closed_at = null,
        updated_at = timezone('utc', now())
    where id = v_reactivate_space_id
      and status = 'closed';

    update public.couple_memberships
    set status = 'active',
        left_at = null
    where couple_space_id = v_reactivate_space_id
      and status = 'left'
      and left_at is not null;

    perform public.delete_closed_space(cs.id)
    from public.couple_spaces cs
    join public.couple_memberships cm
      on cm.couple_space_id = cs.id
    where cm.profile_id = auth.uid()
      and cm.status = 'left'
      and cm.left_at is not null
      and cs.status = 'closed'
      and cs.id <> v_reactivate_space_id;

    update public.couple_invites
    set accepted_by = auth.uid(),
        accepted_at = timezone('utc', now())
    where id = v_invite.id;

    if v_invite.couple_space_id <> v_reactivate_space_id then
      if exists (
        select 1
        from public.couple_spaces
        where id = v_invite.couple_space_id
          and status = 'closed'
      ) then
        perform public.delete_closed_space(v_invite.couple_space_id);
      end if;
    end if;

    return v_reactivate_space_id;
  end if;

  -- Fresh pairing: keep the inviter's current pending invite space intact
  -- and join it directly.
  insert into public.couple_memberships (
    couple_space_id,
    profile_id,
    role
  )
  values (
    v_invite.couple_space_id,
    auth.uid(),
    'partner'
  );

  update public.couple_invites
  set accepted_by = auth.uid(),
      accepted_at = timezone('utc', now())
  where id = v_invite.id;

  update public.couple_spaces
  set status = 'active',
      updated_at = timezone('utc', now())
  where id = v_invite.couple_space_id
    and status = 'pending_partner';

  perform public.delete_closed_space(cs.id)
  from public.couple_spaces cs
  join public.couple_memberships cm
    on cm.couple_space_id = cs.id
  where cm.profile_id = auth.uid()
    and cm.status = 'left'
    and cm.left_at is not null
    and cs.status = 'closed';

  return v_invite.couple_space_id;
end;
$$;

revoke all on function public.accept_couple_invite(text) from public;
revoke all on function public.accept_couple_invite(text) from anon;
grant execute on function public.accept_couple_invite(text) to authenticated;

commit;

-- Allow a user to accept an invite when they only belong to an auto-created
-- placeholder space that has no partner yet.

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
begin
  if auth.uid() is null then
    raise exception 'authentication required';
  end if;

  if p_plain_code is null or btrim(p_plain_code) = '' then
    raise exception 'invite code is required';
  end if;

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
  where invites.code_hash = encode(extensions.digest(btrim(p_plain_code), 'sha256'), 'hex')
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

  return v_invite.couple_space_id;
end;
$$;

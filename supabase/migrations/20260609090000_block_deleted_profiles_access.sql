begin;

create or replace function public.is_active_profile(
  p_user_id uuid default auth.uid()
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles profiles
    where profiles.id = p_user_id
      and profiles.deleted_at is null
  );
$$;

drop function if exists public.get_my_profile();

create function public.get_my_profile()
returns table (
  id uuid,
  display_name text,
  avatar_url text,
  gender text,
  birthday date,
  preferred_locale text,
  theme_preference text,
  notification_preview_enabled boolean,
  cycle_sharing_enabled boolean
)
language sql
stable
security definer
set search_path = public
as $$
  select
    profiles.id,
    profiles.display_name,
    profiles.avatar_url,
    profiles.gender,
    profiles.birthday,
    profiles.preferred_locale,
    profiles.theme_preference::text,
    profiles.notification_preview_enabled,
    profiles.cycle_sharing_enabled
  from public.profiles profiles
  where profiles.id = auth.uid()
    and profiles.deleted_at is null
$$;

revoke all on function public.get_my_profile() from public;
revoke all on function public.get_my_profile() from anon;
grant execute on function public.get_my_profile() to authenticated;

create or replace function public.get_partner_public_profile(
  p_profile_id uuid
)
returns table (
  id uuid,
  display_name text,
  avatar_url text
)
language sql
stable
security definer
set search_path = public
as $$
  select
    profiles.id,
    profiles.display_name,
    profiles.avatar_url
  from public.profiles profiles
  where profiles.id = p_profile_id
    and profiles.deleted_at is null
    and p_profile_id != auth.uid()
    and public.is_active_profile(auth.uid())
    and exists (
      select 1
      from public.couple_memberships m1
      join public.couple_memberships m2
        on m2.couple_space_id = m1.couple_space_id
        and m2.profile_id = p_profile_id
        and m2.status = 'active'
        and m2.left_at is null
      join public.couple_spaces s
        on s.id = m1.couple_space_id
      where m1.profile_id = auth.uid()
        and m1.status = 'active'
        and m1.left_at is null
        and s.status = 'active'
        and s.closed_at is null
    )
$$;

create or replace function public.is_active_member(
  p_couple_space_id uuid,
  p_profile_id uuid default auth.uid()
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.is_active_profile(p_profile_id)
    and exists (
      select 1
      from public.couple_memberships memberships
      join public.couple_spaces spaces
        on spaces.id = memberships.couple_space_id
      where memberships.couple_space_id = p_couple_space_id
        and memberships.profile_id = p_profile_id
        and memberships.status = 'active'
        and memberships.left_at is null
        and spaces.closed_at is null
        and spaces.status in ('pending_partner', 'active')
    );
$$;

create or replace function public.is_active_couple_member(
  p_couple_space_id uuid,
  p_profile_id uuid default auth.uid()
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.is_active_profile(p_profile_id)
    and exists (
      select 1
      from public.couple_memberships memberships
      join public.couple_spaces spaces
        on spaces.id = memberships.couple_space_id
      where memberships.couple_space_id = p_couple_space_id
        and memberships.profile_id = p_profile_id
        and memberships.status = 'active'
        and memberships.left_at is null
        and spaces.status = 'active'
        and spaces.closed_at is null
        and (
          select count(*)
          from public.couple_memberships m2
          where m2.couple_space_id = p_couple_space_id
            and m2.status = 'active'
            and m2.left_at is null
        ) >= 2
    );
$$;

create or replace function public.create_couple_space(
  p_space_name text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_space_id uuid;
  v_user_id uuid;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  if not public.is_active_profile(v_user_id) then
    raise exception 'account deleted';
  end if;

  -- Keep the existing create_couple_space(text) behavior from
  -- 20260605100000_add_anniversaries_table.sql. This migration only adds the
  -- deleted-profile guard above.
  if exists (
    select 1 from couple_memberships
    where profile_id = v_user_id and status = 'active'
  ) then
    raise exception 'User already belongs to an active couple_space';
  end if;

  insert into couple_spaces (created_by, space_name, status)
  values (v_user_id, p_space_name, 'pending_partner')
  returning id into v_space_id;

  insert into couple_memberships (couple_space_id, profile_id, role, status)
  values (v_space_id, v_user_id, 'owner', 'active');

  insert into anniversaries (couple_space_id, type, title, date, is_custom)
  values
    (v_space_id, 'first_met', '相识纪念日', current_date, false),
    (v_space_id, 'relationship_start', '恋爱纪念日', current_date, false);

  return v_space_id;
end;
$$;

revoke all on function public.create_couple_space(text) from public;
revoke all on function public.create_couple_space(text) from anon;
grant execute on function public.create_couple_space(text) to authenticated;

create or replace function public.create_couple_invite(
  p_couple_space_id uuid,
  p_plain_code text,
  p_expires_in interval default interval '24 hours'
)
returns table (id uuid, expires_at timestamptz)
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'authentication required';
  end if;

  if not public.is_active_profile(auth.uid()) then
    raise exception 'account deleted';
  end if;

  if not exists (
    select 1
    from public.couple_memberships memberships
    where memberships.couple_space_id = p_couple_space_id
      and memberships.profile_id = auth.uid()
      and memberships.role = 'owner'
      and memberships.status = 'active'
      and memberships.left_at is null
  ) then
    raise exception 'only the active owner can create an invite';
  end if;

  if (
    select count(*)
    from public.couple_memberships memberships
    where memberships.couple_space_id = p_couple_space_id
      and memberships.status = 'active'
      and memberships.left_at is null
  ) >= 2 then
    raise exception 'couple_space already has two active members';
  end if;

  update public.couple_invites as invites
  set revoked_at = timezone('utc', now())
  where invites.couple_space_id = p_couple_space_id
    and invites.accepted_at is null
    and invites.revoked_at is null
    and invites.expires_at > timezone('utc', now());

  return query
  insert into public.couple_invites as ci (
    couple_space_id,
    created_by,
    code_hash,
    expires_at
  )
  values (
    p_couple_space_id,
    auth.uid(),
    encode(extensions.digest(btrim(p_plain_code), 'sha256'), 'hex'),
    timezone('utc', now()) + p_expires_in
  )
  returning ci.id, ci.expires_at;
end;
$$;

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

  if not public.is_active_profile(auth.uid()) then
    raise exception 'account deleted';
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

create or replace function public.revoke_couple_invite(
  p_invite_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_space_id uuid;
begin
  if auth.uid() is null then
    raise exception 'authentication required';
  end if;

  if not public.is_active_profile(auth.uid()) then
    raise exception 'account deleted';
  end if;

  select invites.couple_space_id
    into v_space_id
  from public.couple_invites invites
  join public.couple_memberships memberships
    on memberships.couple_space_id = invites.couple_space_id
  where invites.id = p_invite_id
    and invites.accepted_at is null
    and invites.revoked_at is null
    and memberships.profile_id = auth.uid()
    and memberships.role = 'owner'
    and memberships.status = 'active'
    and memberships.left_at is null
  for update;

  if not found then
    raise exception 'invite cannot be revoked';
  end if;

  update public.couple_invites
  set revoked_at = timezone('utc', now())
  where id = p_invite_id;

  return v_space_id;
end;
$$;

create or replace function public.request_couple_space_exit()
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_space_id uuid;
  v_existing_id uuid;
begin
  if auth.uid() is null then
    raise exception 'authentication required';
  end if;

  if not public.is_active_profile(auth.uid()) then
    raise exception 'account deleted';
  end if;

  select m.couple_space_id
    into v_space_id
  from public.couple_memberships m
  join public.couple_spaces s
    on s.id = m.couple_space_id
  where m.profile_id = auth.uid()
    and m.status = 'active'
    and m.left_at is null
    and s.status = 'active'
    and s.closed_at is null
    and (
      select count(*)
      from public.couple_memberships m2
      where m2.couple_space_id = m.couple_space_id
        and m2.status = 'active'
        and m2.left_at is null
    ) >= 2;

  if v_space_id is null then
    raise exception 'no active couple space found';
  end if;

  select id
    into v_existing_id
  from public.couple_space_exit_requests
  where couple_space_id = v_space_id
    and status = 'pending'
  limit 1;

  if v_existing_id is not null then
    return v_existing_id;
  end if;

  insert into public.couple_space_exit_requests (
    couple_space_id,
    requested_by
  )
  values (
    v_space_id,
    auth.uid()
  )
  returning id into v_existing_id;

  return v_existing_id;
end;
$$;

create or replace function public.approve_couple_space_exit(
  p_request_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_request public.couple_space_exit_requests%rowtype;
  v_approver_is_member boolean;
begin
  if auth.uid() is null then
    raise exception 'authentication required';
  end if;

  if not public.is_active_profile(auth.uid()) then
    raise exception 'account deleted';
  end if;

  if p_request_id is null then
    raise exception 'request_id is required';
  end if;

  select *
    into v_request
  from public.couple_space_exit_requests
  where id = p_request_id
    and status = 'pending'
  for update;

  if not found then
    raise exception 'exit request not found or not pending';
  end if;

  if v_request.requested_by = auth.uid() then
    raise exception 'requester cannot approve their own exit request';
  end if;

  select exists (
    select 1
    from public.couple_memberships m
    join public.couple_spaces s
      on s.id = m.couple_space_id
    where m.couple_space_id = v_request.couple_space_id
      and m.profile_id = auth.uid()
      and m.status = 'active'
      and m.left_at is null
      and s.status = 'active'
      and s.closed_at is null
      and (
        select count(*)
        from public.couple_memberships m2
        where m2.couple_space_id = v_request.couple_space_id
          and m2.status = 'active'
          and m2.left_at is null
      ) >= 2
  ) into v_approver_is_member;

  if not v_approver_is_member then
    raise exception 'approver is not an active member of this couple space';
  end if;

  update public.couple_space_exit_requests
  set status = 'approved',
      responded_by = auth.uid(),
      responded_at = timezone('utc', now())
  where id = v_request.id;

  update public.couple_memberships
  set status = 'left',
      left_at = timezone('utc', now())
  where couple_space_id = v_request.couple_space_id
    and status = 'active'
    and left_at is null;

  update public.couple_spaces
  set status = 'closed',
      closed_at = timezone('utc', now())
  where id = v_request.couple_space_id
    and status = 'active';

  return v_request.couple_space_id;
end;
$$;

create or replace function public.can_write_cycle_record(
  p_couple_space_id uuid,
  p_owner_profile_id uuid,
  p_requesting_profile_id uuid default auth.uid()
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    public.is_active_profile(p_requesting_profile_id)
    and p_owner_profile_id = p_requesting_profile_id
    and public.is_active_couple_member(p_couple_space_id, p_requesting_profile_id)
    and exists (
      select 1
      from public.profiles profiles
      where profiles.id = p_owner_profile_id
        and profiles.deleted_at is null
        and profiles.gender = 'female'
    );
$$;

create or replace function public.can_read_partner_cycle_record(
  p_couple_space_id uuid,
  p_owner_profile_id uuid,
  p_requesting_profile_id uuid default auth.uid()
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    public.is_active_profile(p_requesting_profile_id)
    and p_owner_profile_id <> p_requesting_profile_id
    and public.is_active_couple_member(p_couple_space_id, p_requesting_profile_id)
    and exists (
      select 1
      from public.profiles profiles
      where profiles.id = p_owner_profile_id
        and profiles.deleted_at is null
        and profiles.cycle_sharing_enabled = true
    );
$$;

drop policy if exists "profiles_update_self" on public.profiles;
create policy "profiles_update_self"
  on public.profiles
  for update
  to authenticated
  using (id = auth.uid() and deleted_at is null)
  with check (id = auth.uid() and deleted_at is null);

drop policy if exists "calendar_events_insert_active_members" on public.calendar_events;
drop policy if exists "calendar_events_insert_active_couple" on public.calendar_events;
create policy "calendar_events_insert_active_couple"
  on public.calendar_events
  for insert
  to authenticated
  with check (
    public.is_active_profile(auth.uid())
    and created_by = auth.uid()
    and public.is_active_couple_member(couple_space_id)
  );

drop policy if exists "calendar_events_update_active_members" on public.calendar_events;
drop policy if exists "calendar_events_update_active_couple" on public.calendar_events;
create policy "calendar_events_update_active_couple"
  on public.calendar_events
  for update
  to authenticated
  using (
    public.is_active_profile(auth.uid())
    and deleted_at is null
    and created_by = auth.uid()
    and public.is_active_couple_member(couple_space_id)
  )
  with check (
    public.is_active_profile(auth.uid())
    and created_by = auth.uid()
    and public.is_active_couple_member(couple_space_id)
  );

drop policy if exists "plans_insert_active_members" on public.plans;
drop policy if exists "plans_insert_active_couple" on public.plans;
create policy "plans_insert_active_couple"
  on public.plans
  for insert
  to authenticated
  with check (
    public.is_active_profile(auth.uid())
    and created_by = auth.uid()
    and public.is_active_couple_member(couple_space_id)
  );

drop policy if exists "plans_update_active_members" on public.plans;
drop policy if exists "plans_update_active_couple" on public.plans;
create policy "plans_update_active_couple"
  on public.plans
  for update
  to authenticated
  using (
    public.is_active_profile(auth.uid())
    and deleted_at is null
    and created_by = auth.uid()
    and public.is_active_couple_member(couple_space_id)
  )
  with check (
    public.is_active_profile(auth.uid())
    and created_by = auth.uid()
    and public.is_active_couple_member(couple_space_id)
  );

drop policy if exists "notes_insert_author_only" on public.notes;
drop policy if exists "notes_insert_active_couple_author" on public.notes;
create policy "notes_insert_active_couple_author"
  on public.notes
  for insert
  to authenticated
  with check (
    public.is_active_profile(auth.uid())
    and author_profile_id = auth.uid()
    and public.is_active_couple_member(couple_space_id)
  );

drop policy if exists "notes_update_author_only" on public.notes;
drop policy if exists "notes_update_active_couple_author" on public.notes;
create policy "notes_update_active_couple_author"
  on public.notes
  for update
  to authenticated
  using (
    public.is_active_profile(auth.uid())
    and deleted_at is null
    and author_profile_id = auth.uid()
    and public.is_active_couple_member(couple_space_id)
  )
  with check (
    public.is_active_profile(auth.uid())
    and author_profile_id = auth.uid()
    and public.is_active_couple_member(couple_space_id)
  );

drop policy if exists "anniversaries_insert_active_couple" on public.anniversaries;
create policy "anniversaries_insert_active_couple"
  on public.anniversaries
  for insert
  to authenticated
  with check (
    public.is_active_profile(auth.uid())
    and public.is_active_couple_member(couple_space_id)
  );

drop policy if exists "anniversaries_update_active_couple" on public.anniversaries;
create policy "anniversaries_update_active_couple"
  on public.anniversaries
  for update
  to authenticated
  using (
    public.is_active_profile(auth.uid())
    and public.is_active_couple_member(couple_space_id)
  )
  with check (
    public.is_active_profile(auth.uid())
    and public.is_active_couple_member(couple_space_id)
  );

drop policy if exists "anniversaries_delete_active_couple" on public.anniversaries;
create policy "anniversaries_delete_active_couple"
  on public.anniversaries
  for delete
  to authenticated
  using (
    public.is_active_profile(auth.uid())
    and public.is_active_couple_member(couple_space_id)
  );

drop policy if exists "cycle_records_owner_insert" on public.cycle_records;
create policy "cycle_records_owner_insert"
  on public.cycle_records
  for insert
  to authenticated
  with check (
    public.can_write_cycle_record(couple_space_id, owner_profile_id)
  );

drop policy if exists "cycle_records_owner_update" on public.cycle_records;
create policy "cycle_records_owner_update"
  on public.cycle_records
  for update
  to authenticated
  using (
    public.can_write_cycle_record(couple_space_id, owner_profile_id)
  )
  with check (
    public.can_write_cycle_record(couple_space_id, owner_profile_id)
  );

grant execute on function public.is_active_profile(uuid) to authenticated;

commit;

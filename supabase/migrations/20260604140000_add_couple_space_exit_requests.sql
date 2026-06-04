begin;

-- Couple space exit requests.
--
-- Lifecycle: A requests exit -> B approves -> space closes -> both return
-- to single mode. Shared data (calendar_events, plans, notes) is NOT
-- deleted; it becomes inaccessible because the RLS policies on those
-- tables require is_active_couple_member(), which returns false once
-- the space is closed and memberships are set to 'left'.

-- 1. Table

create table public.couple_space_exit_requests (
  id uuid primary key default extensions.gen_random_uuid(),
  couple_space_id uuid not null references public.couple_spaces (id) on delete restrict,
  requested_by uuid not null references public.profiles (id) on delete restrict,
  status text not null default 'pending',
  request_count int not null default 1,
  requested_at timestamptz not null default timezone('utc', now()),
  responded_by uuid references public.profiles (id) on delete restrict,
  responded_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint exit_requests_status_check
    check (status in ('pending', 'approved', 'cancelled')),
  constraint exit_requests_responded_pair_check
    check (
      (status = 'pending' and responded_by is null and responded_at is null)
      or (status <> 'pending' and responded_by is not null and responded_at is not null)
    )
);

-- At most one pending request per couple space.
create unique index exit_requests_one_pending_per_space_idx
  on public.couple_space_exit_requests (couple_space_id)
  where status = 'pending';

-- 2. Triggers

create trigger couple_space_exit_requests_set_updated_at
before update on public.couple_space_exit_requests
for each row execute function public.set_updated_at();

create trigger couple_space_exit_requests_protect_immutable_fields
before update on public.couple_space_exit_requests
for each row execute function public.protect_immutable_fields();

-- 3. RLS

alter table public.couple_space_exit_requests enable row level security;

-- Active couple space members can read exit requests for their space.
create policy "exit_requests_select_active_couple"
  on public.couple_space_exit_requests
  for select
  to authenticated
  using (public.is_active_couple_member(couple_space_id));

-- No direct insert/update/delete policies. All mutations go through
-- SECURITY DEFINER RPCs below.

-- 4. Grants

grant select on public.couple_space_exit_requests to authenticated;
-- No insert/update/delete grants for client.

-- 5. RPC: request_couple_space_exit()

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

  -- Find the caller's active couple space (must be a full active double space).
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

  -- If a pending request already exists, return it.
  select id
    into v_existing_id
  from public.couple_space_exit_requests
  where couple_space_id = v_space_id
    and status = 'pending'
  limit 1;

  if v_existing_id is not null then
    return v_existing_id;
  end if;

  -- Create a new pending exit request.
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

-- 6. RPC: approve_couple_space_exit()

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

  if p_request_id is null then
    raise exception 'request_id is required';
  end if;

  -- Lock the request row.
  select *
    into v_request
  from public.couple_space_exit_requests
  where id = p_request_id
    and status = 'pending'
  for update;

  if not found then
    raise exception 'exit request not found or not pending';
  end if;

  -- The approver must not be the requester.
  if v_request.requested_by = auth.uid() then
    raise exception 'requester cannot approve their own exit request';
  end if;

  -- The approver must be an active member of the same couple space,
  -- and the space must still be a full active double space.
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

  -- Mark the request as approved.
  update public.couple_space_exit_requests
  set status = 'approved',
      responded_by = auth.uid(),
      responded_at = timezone('utc', now())
  where id = v_request.id;

  -- Set all active memberships in this space to 'left'.
  update public.couple_memberships
  set status = 'left',
      left_at = timezone('utc', now())
  where couple_space_id = v_request.couple_space_id
    and status = 'active'
    and left_at is null;

  -- Close the couple space.
  update public.couple_spaces
  set status = 'closed',
      closed_at = timezone('utc', now())
  where id = v_request.couple_space_id
    and status = 'active';

  return v_request.couple_space_id;
end;
$$;

-- 7. Update protect_immutable_fields to handle couple_space_exit_requests.

create or replace function public.protect_immutable_fields()
returns trigger
language plpgsql
as $$
begin
  if tg_table_name = 'profiles' then
    if new.id <> old.id or new.created_at <> old.created_at then
      raise exception 'profiles immutable fields cannot be changed';
    end if;
  elsif tg_table_name = 'couple_spaces' then
    if
      new.id <> old.id
      or new.created_by <> old.created_by
      or new.created_at <> old.created_at
      or (
        current_user not in ('postgres', 'service_role')
        and (
          new.status <> old.status
          or new.closed_at is distinct from old.closed_at
        )
      )
    then
      raise exception 'couple_spaces lifecycle fields cannot be changed directly';
    end if;
  elsif tg_table_name = 'couple_space_exit_requests' then
    if
      new.id <> old.id
      or new.couple_space_id <> old.couple_space_id
      or new.requested_by <> old.requested_by
      or new.requested_at <> old.requested_at
      or new.created_at <> old.created_at
    then
      raise exception 'couple_space_exit_requests immutable fields cannot be changed';
    end if;
  elsif tg_table_name = 'calendar_events' then
    if
      new.id <> old.id
      or new.couple_space_id <> old.couple_space_id
      or new.created_by <> old.created_by
      or new.created_at <> old.created_at
    then
      raise exception 'calendar_events ownership fields cannot be changed';
    end if;
  elsif tg_table_name = 'plans' then
    if
      new.id <> old.id
      or new.couple_space_id <> old.couple_space_id
      or new.created_by <> old.created_by
      or new.created_at <> old.created_at
    then
      raise exception 'plans ownership fields cannot be changed';
    end if;
  elsif tg_table_name = 'notes' then
    if
      new.id <> old.id
      or new.couple_space_id <> old.couple_space_id
      or new.author_profile_id <> old.author_profile_id
      or new.created_at <> old.created_at
    then
      raise exception 'notes ownership fields cannot be changed';
    end if;
  end if;

  return new;
end;
$$;

-- 8. Grants for RPCs

revoke all on function public.request_couple_space_exit() from public;
revoke all on function public.request_couple_space_exit() from anon;
grant execute on function public.request_couple_space_exit() to authenticated;

revoke all on function public.approve_couple_space_exit(uuid) from public;
revoke all on function public.approve_couple_space_exit(uuid) from anon;
grant execute on function public.approve_couple_space_exit(uuid) to authenticated;

commit;

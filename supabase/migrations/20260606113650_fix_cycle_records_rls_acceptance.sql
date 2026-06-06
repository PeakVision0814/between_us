begin;

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
    p_owner_profile_id = p_requesting_profile_id
    and public.is_active_couple_member(p_couple_space_id, p_requesting_profile_id)
    and exists (
      select 1
      from public.profiles profiles
      where profiles.id = p_owner_profile_id
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
    p_owner_profile_id <> p_requesting_profile_id
    and public.is_active_couple_member(p_couple_space_id, p_requesting_profile_id)
    and exists (
      select 1
      from public.profiles profiles
      where profiles.id = p_owner_profile_id
        and profiles.cycle_sharing_enabled = true
    );
$$;

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

drop policy if exists "cycle_records_partner_select" on public.cycle_records;
create policy "cycle_records_partner_select"
  on public.cycle_records
  for select
  to authenticated
  using (
    deleted_at is null
    and shared_with_partner = true
    and public.can_read_partner_cycle_record(couple_space_id, owner_profile_id)
  );

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
  elsif tg_table_name = 'cycle_records' then
    if
      new.id <> old.id
      or new.couple_space_id <> old.couple_space_id
      or new.owner_profile_id <> old.owner_profile_id
      or new.created_at <> old.created_at
    then
      raise exception 'cycle_records ownership fields cannot be changed';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists cycle_records_protect_immutable_fields
  on public.cycle_records;
create trigger cycle_records_protect_immutable_fields
before update on public.cycle_records
for each row execute function public.protect_immutable_fields();

alter publication supabase_realtime add table public.cycle_records;

revoke all on function public.can_write_cycle_record(uuid, uuid, uuid) from public;
revoke all on function public.can_write_cycle_record(uuid, uuid, uuid) from anon;
grant execute on function public.can_write_cycle_record(uuid, uuid, uuid) to authenticated;

revoke all on function public.can_read_partner_cycle_record(uuid, uuid, uuid) from public;
revoke all on function public.can_read_partner_cycle_record(uuid, uuid, uuid) from anon;
grant execute on function public.can_read_partner_cycle_record(uuid, uuid, uuid) to authenticated;

commit;

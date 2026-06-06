begin;

create table public.cycle_records (
  id uuid primary key default extensions.gen_random_uuid(),
  couple_space_id uuid not null references public.couple_spaces (id) on delete restrict,
  owner_profile_id uuid not null references public.profiles (id) on delete restrict,
  period_start_date date not null,
  period_end_date date null,
  note text null,
  shared_with_partner boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  deleted_at timestamptz null,
  constraint cycle_records_period_end_check
    check (period_end_date is null or period_end_date >= period_start_date),
  constraint cycle_records_note_check
    check (note is null or char_length(note) <= 500)
);

comment on table public.cycle_records is
  'Sensitive menstrual cycle records. Owner controls sharing; defaults to private.';
comment on column public.cycle_records.shared_with_partner is
  'When true, the active partner in the same couple space can read the record.';

create index cycle_records_couple_space_id_idx
  on public.cycle_records (couple_space_id);
create index cycle_records_owner_profile_id_idx
  on public.cycle_records (owner_profile_id);
create index cycle_records_period_start_date_idx
  on public.cycle_records (period_start_date);
create index cycle_records_visible_range_idx
  on public.cycle_records (couple_space_id, period_start_date, period_end_date)
  where deleted_at is null;

create trigger cycle_records_set_updated_at
before update on public.cycle_records
for each row
execute function public.set_updated_at();

alter table public.cycle_records enable row level security;

create policy "cycle_records_owner_select"
  on public.cycle_records
  for select
  to authenticated
  using (
    deleted_at is null
    and owner_profile_id = auth.uid()
  );

create policy "cycle_records_owner_insert"
  on public.cycle_records
  for insert
  to authenticated
  with check (
    owner_profile_id = auth.uid()
    and public.is_active_couple_member(couple_space_id)
  );

create policy "cycle_records_owner_update"
  on public.cycle_records
  for update
  to authenticated
  using (
    owner_profile_id = auth.uid()
    and public.is_active_couple_member(couple_space_id)
  )
  with check (
    owner_profile_id = auth.uid()
    and public.is_active_couple_member(couple_space_id)
  );

create policy "cycle_records_owner_delete"
  on public.cycle_records
  for delete
  to authenticated
  using (
    owner_profile_id = auth.uid()
    and public.is_active_couple_member(couple_space_id)
  );

create policy "cycle_records_partner_select"
  on public.cycle_records
  for select
  to authenticated
  using (
    deleted_at is null
    and shared_with_partner = true
    and owner_profile_id <> auth.uid()
    and public.is_active_couple_member(couple_space_id)
  );

grant select, insert, update, delete on public.cycle_records to authenticated;

commit;

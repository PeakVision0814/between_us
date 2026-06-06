begin;

create or replace function public.prevent_overlapping_cycle_records()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.deleted_at is not null then
    return new;
  end if;

  if exists (
    select 1
    from public.cycle_records existing
    where existing.owner_profile_id = new.owner_profile_id
      and existing.deleted_at is null
      and existing.id <> new.id
      and daterange(
        existing.period_start_date,
        coalesce(existing.period_end_date, existing.period_start_date) + 1,
        '[)'
      ) && daterange(
        new.period_start_date,
        coalesce(new.period_end_date, new.period_start_date) + 1,
        '[)'
      )
  ) then
    raise exception 'cycle_records period overlaps an existing record'
      using errcode = '23P01';
  end if;

  return new;
end;
$$;

drop trigger if exists cycle_records_prevent_overlap
  on public.cycle_records;
create trigger cycle_records_prevent_overlap
before insert or update of period_start_date, period_end_date, deleted_at
on public.cycle_records
for each row execute function public.prevent_overlapping_cycle_records();

drop policy if exists "cycle_records_owner_update" on public.cycle_records;
create policy "cycle_records_owner_update"
  on public.cycle_records
  for update
  to authenticated
  using (
    owner_profile_id = auth.uid()
    and public.is_active_couple_member(couple_space_id)
  )
  with check (
    public.can_write_cycle_record(couple_space_id, owner_profile_id)
  );

drop policy if exists "calendar_events_update_active_couple"
  on public.calendar_events;
create policy "calendar_events_update_active_couple"
  on public.calendar_events
  for update
  to authenticated
  using (
    deleted_at is null
    and created_by = auth.uid()
    and public.is_active_couple_member(couple_space_id)
  )
  with check (
    created_by = auth.uid()
    and public.is_active_couple_member(couple_space_id)
  );

revoke all on function public.prevent_overlapping_cycle_records() from public;
revoke all on function public.prevent_overlapping_cycle_records() from anon;

commit;

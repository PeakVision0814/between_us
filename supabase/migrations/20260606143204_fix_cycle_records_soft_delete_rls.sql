begin;

drop policy if exists "cycle_records_owner_select"
  on public.cycle_records;

create policy "cycle_records_owner_select"
  on public.cycle_records
  for select
  to authenticated
  using (
    owner_profile_id = auth.uid()
  );

commit;

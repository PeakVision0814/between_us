begin;

-- UPDATE with RLS also checks that the updated row remains visible through a
-- SELECT policy. Soft deletion sets deleted_at, so the prior SELECT policy
-- (`deleted_at is null`) made owner soft delete fail even when the UPDATE
-- policy itself matched.
drop policy if exists "calendar_events_select_active_couple"
  on public.calendar_events;
create policy "calendar_events_select_active_couple"
  on public.calendar_events
  for select
  to authenticated
  using (
    public.is_active_couple_member(couple_space_id)
    and (
      deleted_at is null
      or created_by = auth.uid()
    )
  );

commit;

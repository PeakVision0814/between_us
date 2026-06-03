begin;

-- Tighten SELECT policies: only active couple space members can read shared business data.
-- pending_partner spaces can no longer read calendar_events, plans, or notes.

-- calendar_events
drop policy if exists "calendar_events_select_active_members" on public.calendar_events;
create policy "calendar_events_select_active_couple"
  on public.calendar_events
  for select
  to authenticated
  using (
    deleted_at is null
    and public.is_active_couple_member(couple_space_id)
  );

-- plans
drop policy if exists "plans_select_active_members" on public.plans;
create policy "plans_select_active_couple"
  on public.plans
  for select
  to authenticated
  using (
    deleted_at is null
    and public.is_active_couple_member(couple_space_id)
  );

-- notes
drop policy if exists "notes_select_active_members" on public.notes;
create policy "notes_select_active_couple"
  on public.notes
  for select
  to authenticated
  using (
    deleted_at is null
    and public.is_active_couple_member(couple_space_id)
  );

commit;

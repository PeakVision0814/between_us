begin;

-- 1. New helper function: only active couple spaces with 2 members can write shared data.
-- This is stricter than is_active_member(), which also allows pending_partner spaces.

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
  select exists (
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

-- 2. calendar_events: tighten insert + update to active couple only

drop policy if exists "calendar_events_insert_active_members" on public.calendar_events;
create policy "calendar_events_insert_active_couple"
  on public.calendar_events
  for insert
  to authenticated
  with check (
    created_by = auth.uid()
    and public.is_active_couple_member(couple_space_id)
  );

drop policy if exists "calendar_events_update_active_members" on public.calendar_events;
create policy "calendar_events_update_active_couple"
  on public.calendar_events
  for update
  to authenticated
  using (
    deleted_at is null
    and public.is_active_couple_member(couple_space_id)
  )
  with check (public.is_active_couple_member(couple_space_id));

-- 3. plans: tighten insert + update to active couple only

drop policy if exists "plans_insert_active_members" on public.plans;
create policy "plans_insert_active_couple"
  on public.plans
  for insert
  to authenticated
  with check (
    created_by = auth.uid()
    and public.is_active_couple_member(couple_space_id)
  );

drop policy if exists "plans_update_active_members" on public.plans;
create policy "plans_update_active_couple"
  on public.plans
  for update
  to authenticated
  using (
    deleted_at is null
    and public.is_active_couple_member(couple_space_id)
  )
  with check (public.is_active_couple_member(couple_space_id));

-- 4. notes: tighten insert + update to active couple only, keep author restrictions

drop policy if exists "notes_insert_author_only" on public.notes;
create policy "notes_insert_active_couple_author"
  on public.notes
  for insert
  to authenticated
  with check (
    author_profile_id = auth.uid()
    and public.is_active_couple_member(couple_space_id)
  );

drop policy if exists "notes_update_author_only" on public.notes;
create policy "notes_update_active_couple_author"
  on public.notes
  for update
  to authenticated
  using (
    deleted_at is null
    and author_profile_id = auth.uid()
    and public.is_active_couple_member(couple_space_id)
  )
  with check (
    author_profile_id = auth.uid()
    and public.is_active_couple_member(couple_space_id)
  );

-- 5. Grants
-- Revoke from all roles first, then grant only to authenticated.
-- SECURITY DEFINER functions must not be callable by anon.

revoke all on function public.is_active_couple_member(uuid, uuid) from public;
revoke all on function public.is_active_couple_member(uuid, uuid) from anon;
grant execute on function public.is_active_couple_member(uuid, uuid) to authenticated;

commit;

begin;

create or replace function public.is_space_lifecycle_member(
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
      where memberships.couple_space_id = p_couple_space_id
        and memberships.profile_id = p_profile_id
        and memberships.status in ('active', 'left', 'removed')
    );
$$;

drop policy if exists "couple_spaces_select_active_members"
  on public.couple_spaces;
drop policy if exists "couple_spaces_select_lifecycle_members"
  on public.couple_spaces;
create policy "couple_spaces_select_lifecycle_members"
  on public.couple_spaces
  for select
  to authenticated
  using (public.is_space_lifecycle_member(id));

drop policy if exists "couple_memberships_select_active_members"
  on public.couple_memberships;
drop policy if exists "couple_memberships_select_lifecycle_members"
  on public.couple_memberships;
create policy "couple_memberships_select_lifecycle_members"
  on public.couple_memberships
  for select
  to authenticated
  using (public.is_space_lifecycle_member(couple_space_id));

drop policy if exists "exit_requests_select_active_couple"
  on public.couple_space_exit_requests;
drop policy if exists "exit_requests_select_lifecycle_members"
  on public.couple_space_exit_requests;
create policy "exit_requests_select_lifecycle_members"
  on public.couple_space_exit_requests
  for select
  to authenticated
  using (public.is_space_lifecycle_member(couple_space_id));

revoke all on function public.is_space_lifecycle_member(uuid, uuid) from public;
revoke all on function public.is_space_lifecycle_member(uuid, uuid) from anon;
grant execute on function public.is_space_lifecycle_member(uuid, uuid)
  to authenticated;

commit;

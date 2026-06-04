begin;

-- ─────────────────────────────────────────────────────────────────────
-- Partner profile visibility via SECURITY DEFINER functions.
--
-- Postgres RLS is row-level, not column-level. A row policy on profiles
-- would expose ALL columns (including gender, birthday) to the partner.
-- Instead, we use SECURITY DEFINER functions as the access layer:
--
--   get_my_profile()           → full self-profile (all fields)
--   get_partner_public_profile → only display_name + avatar_url
--
-- The AppController calls these functions instead of querying profiles
-- directly. No RLS policy changes on the profiles table are needed.
-- ─────────────────────────────────────────────────────────────────────

-- 1. get_my_profile: returns the current user's full profile.
-- SECURITY DEFINER bypasses RLS so the user can always read their own row.

create or replace function public.get_my_profile()
returns table (
  id uuid,
  display_name text,
  avatar_url text,
  gender text,
  birthday date,
  preferred_locale text,
  theme_preference text,
  notification_preview_enabled boolean
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
    profiles.notification_preview_enabled
  from public.profiles profiles
  where profiles.id = auth.uid()
$$;

-- 2. get_partner_public_profile: returns only the safe public fields
-- for a partner in the same active couple space.
-- Validates that the caller and target are in the same active space.

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
    and p_profile_id != auth.uid()
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
        and s.status = 'active'
        and s.closed_at is null
      where m1.profile_id = auth.uid()
        and m1.status = 'active'
        and m1.left_at is null
    )
$$;

-- 3. Grants
-- Revoke from both public and anon explicitly, then grant only to authenticated.
-- SECURITY DEFINER functions must not be callable by anon.

revoke all on function public.get_my_profile() from public;
revoke all on function public.get_my_profile() from anon;
grant execute on function public.get_my_profile() to authenticated;

revoke all on function public.get_partner_public_profile(uuid) from public;
revoke all on function public.get_partner_public_profile(uuid) from anon;
grant execute on function public.get_partner_public_profile(uuid) to authenticated;

commit;

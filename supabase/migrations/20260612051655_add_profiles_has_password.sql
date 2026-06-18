begin;

alter table public.profiles
  add column has_password boolean not null default false;

comment on column public.profiles.has_password is
  'Whether this account has configured a password for password sign-in.';

update public.profiles profiles
set has_password = true
from auth.users users
where users.id = profiles.id
  and coalesce(users.encrypted_password, '') <> '';

grant update (has_password) on public.profiles to authenticated;

drop function if exists public.get_my_profile();

create function public.get_my_profile()
returns table (
  id uuid,
  display_name text,
  avatar_url text,
  gender text,
  birthday date,
  preferred_locale text,
  theme_preference text,
  notification_preview_enabled boolean,
  cycle_sharing_enabled boolean,
  has_password boolean,
  recovery_email text,
  recovery_email_verified_at timestamptz,
  recovery_email_pending text
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
    profiles.notification_preview_enabled,
    profiles.cycle_sharing_enabled,
    profiles.has_password,
    profiles.recovery_email,
    profiles.recovery_email_verified_at,
    profiles.recovery_email_pending
  from public.profiles profiles
  where profiles.id = auth.uid()
    and profiles.deleted_at is null
$$;

revoke all on function public.get_my_profile() from public;
revoke all on function public.get_my_profile() from anon;
grant execute on function public.get_my_profile() to authenticated;

commit;

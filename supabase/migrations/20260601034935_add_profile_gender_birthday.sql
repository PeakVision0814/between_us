begin;

alter table public.profiles
  add column gender text not null default 'unset',
  add column birthday date null;

alter table public.profiles
  add constraint profiles_gender_check
    check (gender in ('male', 'female', 'unset'));

comment on column public.profiles.gender is
  'Current user gender for onboarding and future feature gating. Existing users are backfilled to unset until they complete profile setup.';

comment on column public.profiles.birthday is
  'Optional birthday for reminders and future profile display.';

commit;

begin;

create temp table temp_profile_placeholder_validation (
  sample text not null,
  user_id uuid not null,
  email text not null,
  metadata_display_name text,
  profile_display_name text
) on commit drop;

with unnamed_user as (
  insert into auth.users (
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    phone_confirmed_at,
    last_sign_in_at,
    raw_app_meta_data,
    raw_user_meta_data,
    is_super_admin,
    created_at,
    updated_at,
    is_sso_user,
    is_anonymous
  )
  values (
    gen_random_uuid(),
    'authenticated',
    'authenticated',
    concat(
      'placeholder-validation-unnamed-',
      replace(gen_random_uuid()::text, '-', ''),
      '@example.com'
    ),
    '',
    null,
    null,
    null,
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{}'::jsonb,
    false,
    timezone('utc', now()),
    timezone('utc', now()),
    false,
    false
  )
  returning id, email, raw_user_meta_data
)
insert into temp_profile_placeholder_validation (sample, user_id, email, metadata_display_name)
select
  'unnamed_user',
  unnamed_user.id,
  unnamed_user.email,
  unnamed_user.raw_user_meta_data ->> 'display_name'
from unnamed_user
;

with named_user as (
  insert into auth.users (
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    phone_confirmed_at,
    last_sign_in_at,
    raw_app_meta_data,
    raw_user_meta_data,
    is_super_admin,
    created_at,
    updated_at,
    is_sso_user,
    is_anonymous
  )
  values (
    gen_random_uuid(),
    'authenticated',
    'authenticated',
    concat(
      'placeholder-validation-named-',
      replace(gen_random_uuid()::text, '-', ''),
      '@example.com'
    ),
    '',
    null,
    null,
    null,
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"display_name":"Ache"}'::jsonb,
    false,
    timezone('utc', now()),
    timezone('utc', now()),
    false,
    false
  )
  returning id, email, raw_user_meta_data
)
insert into temp_profile_placeholder_validation (sample, user_id, email, metadata_display_name)
select
  'named_user',
  named_user.id,
  named_user.email,
  named_user.raw_user_meta_data ->> 'display_name'
from named_user;

update temp_profile_placeholder_validation validation
set profile_display_name = profiles.display_name
from public.profiles profiles
where profiles.id = validation.user_id;

select sample, email, metadata_display_name, profile_display_name
from temp_profile_placeholder_validation
order by sample;

rollback;

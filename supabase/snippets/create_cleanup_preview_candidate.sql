with inserted as (
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
    'cleanup-preview-candidate@example.com',
    '',
    null,
    null,
    null,
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{}'::jsonb,
    false,
    timezone('utc', now()) - interval '25 hours',
    timezone('utc', now()) - interval '25 hours',
    false,
    false
  )
  returning id, email, created_at
)
select
  inserted.id,
  inserted.email,
  inserted.created_at as auth_created_at,
  profiles.created_at as profile_created_at,
  profiles.display_name
from inserted
left join public.profiles profiles
  on profiles.id = inserted.id;

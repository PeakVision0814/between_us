begin;

alter table public.profiles
  add column recovery_email text,
  add column recovery_email_verified_at timestamptz,
  add column recovery_email_pending text;

comment on column public.profiles.recovery_email is
  'Verified auxiliary email for account security and future recovery. It is not a Supabase Auth login email.';
comment on column public.profiles.recovery_email_verified_at is
  'Timestamp when recovery_email was verified.';
comment on column public.profiles.recovery_email_pending is
  'Normalized auxiliary email waiting for verification.';

alter table public.profiles
  add constraint profiles_recovery_email_format_check
    check (
      recovery_email is null
      or (
        recovery_email = lower(btrim(recovery_email))
        and recovery_email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'
      )
    ),
  add constraint profiles_recovery_email_pending_format_check
    check (
      recovery_email_pending is null
      or (
        recovery_email_pending = lower(btrim(recovery_email_pending))
        and recovery_email_pending ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'
      )
    ),
  add constraint profiles_recovery_email_verified_consistency_check
    check (
      (recovery_email is null and recovery_email_verified_at is null)
      or (recovery_email is not null and recovery_email_verified_at is not null)
    ),
  add constraint profiles_recovery_email_pending_differs_check
    check (
      recovery_email_pending is null
      or recovery_email is null
      or recovery_email_pending <> recovery_email
    );

create unique index profiles_recovery_email_unique_idx
  on public.profiles (recovery_email)
  where recovery_email is not null and deleted_at is null;

create index profiles_recovery_email_pending_idx
  on public.profiles (recovery_email_pending)
  where recovery_email_pending is not null and deleted_at is null;

create table private.account_recovery_email_challenges (
  profile_id uuid primary key references public.profiles (id) on delete cascade,
  recovery_email_pending text not null,
  otp_hash text not null,
  expires_at timestamptz not null,
  created_at timestamptz not null default timezone('utc', now()),
  constraint account_recovery_email_challenges_pending_format_check
    check (
      recovery_email_pending = lower(btrim(recovery_email_pending))
      and recovery_email_pending ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'
    ),
  constraint account_recovery_email_challenges_hash_check
    check (char_length(otp_hash) = 64)
);

comment on table private.account_recovery_email_challenges is
  'Private short-lived auxiliary email verification challenges. Not exposed to anon/authenticated Data API.';
comment on column private.account_recovery_email_challenges.otp_hash is
  'SHA-256 hash of the short-lived recovery email verification token.';

revoke all on table private.account_recovery_email_challenges from public;
revoke all on table private.account_recovery_email_challenges from anon;
revoke all on table private.account_recovery_email_challenges from authenticated;
grant select, insert, update, delete on table private.account_recovery_email_challenges
  to service_role;

revoke update on public.profiles from authenticated;
grant update (
  display_name,
  avatar_url,
  timezone,
  preferred_locale,
  theme_preference,
  notification_preview_enabled,
  cycle_sharing_enabled,
  gender,
  birthday,
  updated_at
) on public.profiles to authenticated;

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

create or replace function public.request_recovery_email_change(
  p_email text
)
returns table (
  recovery_email_pending text,
  expires_at timestamptz
)
language plpgsql
security definer
set search_path = public, auth, extensions
as $$
declare
  v_user_id uuid := auth.uid();
  v_email text := lower(btrim(coalesce(p_email, '')));
  v_login_email text;
  v_current_recovery_email text;
  v_token text;
  v_token_hash text;
  v_expires_at timestamptz := timezone('utc', now()) + interval '15 minutes';
begin
  if v_user_id is null then
    raise exception 'not_authenticated' using errcode = 'P0001';
  end if;

  if not public.is_active_profile(v_user_id) then
    raise exception 'account_deleted' using errcode = 'P0001';
  end if;

  if v_email = '' or v_email !~* '^[^@\s]+@[^@\s]+\.[^@\s]+$' then
    raise exception 'invalid_email' using errcode = 'P0001';
  end if;

  select lower(users.email)
    into v_login_email
  from auth.users users
  where users.id = v_user_id;

  select profiles.recovery_email
    into v_current_recovery_email
  from public.profiles profiles
  where profiles.id = v_user_id
    and profiles.deleted_at is null;

  if v_email = v_login_email or v_email = v_current_recovery_email then
    raise exception 'same_recovery_email' using errcode = 'P0001';
  end if;

  if exists (
    select 1
    from public.profiles profiles
    where profiles.id <> v_user_id
      and profiles.deleted_at is null
      and profiles.recovery_email = v_email
  ) then
    raise exception 'recovery_email_in_use' using errcode = 'P0001';
  end if;

  v_token := lpad(
    (
      (
        get_byte(gen_random_bytes(4), 0)::bigint * 16777216
        + get_byte(gen_random_bytes(4), 1)::bigint * 65536
        + get_byte(gen_random_bytes(4), 2)::bigint * 256
        + get_byte(gen_random_bytes(4), 3)::bigint
      ) % 1000000
    )::text,
    6,
    '0'
  );
  v_token_hash := encode(digest(v_token, 'sha256'), 'hex');

  update public.profiles
  set recovery_email_pending = v_email,
      updated_at = timezone('utc', now())
  where id = v_user_id
    and deleted_at is null;

  insert into private.account_recovery_email_challenges (
    profile_id,
    recovery_email_pending,
    otp_hash,
    expires_at
  )
  values (
    v_user_id,
    v_email,
    v_token_hash,
    v_expires_at
  )
  on conflict (profile_id) do update
  set recovery_email_pending = excluded.recovery_email_pending,
      otp_hash = excluded.otp_hash,
      expires_at = excluded.expires_at,
      created_at = timezone('utc', now());

  return query
  select v_email, v_expires_at;
end;
$$;

create or replace function public.verify_recovery_email_change(
  p_token text
)
returns table (
  recovery_email text,
  recovery_email_verified_at timestamptz
)
language plpgsql
security definer
set search_path = public, private, extensions
as $$
declare
  v_user_id uuid := auth.uid();
  v_token text := btrim(coalesce(p_token, ''));
  v_pending_email text;
  v_token_hash text;
  v_expires_at timestamptz;
  v_verified_at timestamptz := timezone('utc', now());
begin
  if v_user_id is null then
    raise exception 'not_authenticated' using errcode = 'P0001';
  end if;

  if not public.is_active_profile(v_user_id) then
    raise exception 'account_deleted' using errcode = 'P0001';
  end if;

  if v_token !~ '^\d{6}$' then
    raise exception 'invalid_token' using errcode = 'P0001';
  end if;

  select
    challenges.recovery_email_pending,
    challenges.otp_hash,
    challenges.expires_at
  into v_pending_email, v_token_hash, v_expires_at
  from private.account_recovery_email_challenges challenges
  join public.profiles profiles
    on profiles.id = challenges.profile_id
  where challenges.profile_id = v_user_id
    and profiles.deleted_at is null
    and profiles.recovery_email_pending = challenges.recovery_email_pending;

  if v_pending_email is null or v_token_hash is null or v_expires_at is null then
    raise exception 'missing_pending_recovery_email' using errcode = 'P0001';
  end if;

  if v_expires_at <= timezone('utc', now()) then
    raise exception 'recovery_email_token_expired' using errcode = 'P0001';
  end if;

  if encode(digest(v_token, 'sha256'), 'hex') <> v_token_hash then
    raise exception 'invalid_token' using errcode = 'P0001';
  end if;

  if exists (
    select 1
    from public.profiles profiles
    where profiles.id <> v_user_id
      and profiles.deleted_at is null
      and profiles.recovery_email = v_pending_email
  ) then
    raise exception 'recovery_email_in_use' using errcode = 'P0001';
  end if;

  update public.profiles
  set recovery_email = v_pending_email,
      recovery_email_verified_at = v_verified_at,
      recovery_email_pending = null,
      updated_at = timezone('utc', now())
  where id = v_user_id
    and deleted_at is null;

  delete from private.account_recovery_email_challenges
  where profile_id = v_user_id;

  return query
  select v_pending_email, v_verified_at;
end;
$$;

revoke all on function public.request_recovery_email_change(text) from public;
revoke all on function public.request_recovery_email_change(text) from anon;
grant execute on function public.request_recovery_email_change(text) to authenticated;

revoke all on function public.verify_recovery_email_change(text) from public;
revoke all on function public.verify_recovery_email_change(text) from anon;
grant execute on function public.verify_recovery_email_change(text) to authenticated;

commit;

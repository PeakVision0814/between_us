begin;

alter table public.profiles
  drop constraint if exists profiles_recovery_email_format_check,
  drop constraint if exists profiles_recovery_email_pending_format_check;

alter table public.profiles
  add constraint profiles_recovery_email_format_check
    check (
      recovery_email is null
      or (
        recovery_email = lower(btrim(recovery_email))
        and recovery_email ~* '^[^<>\s@]+@[^<>\s@]+\.[^<>\s@]+$'
      )
    ),
  add constraint profiles_recovery_email_pending_format_check
    check (
      recovery_email_pending is null
      or (
        recovery_email_pending = lower(btrim(recovery_email_pending))
        and recovery_email_pending ~* '^[^<>\s@]+@[^<>\s@]+\.[^<>\s@]+$'
      )
    );

alter table private.account_recovery_email_challenges
  drop constraint if exists account_recovery_email_challenges_pending_format_check;

alter table private.account_recovery_email_challenges
  add constraint account_recovery_email_challenges_pending_format_check
    check (
      recovery_email_pending = lower(btrim(recovery_email_pending))
      and recovery_email_pending ~* '^[^<>\s@]+@[^<>\s@]+\.[^<>\s@]+$'
    );

create or replace function private.create_recovery_email_challenge(
  p_user_id uuid,
  p_email text
)
returns table (
  recovery_email_pending text,
  expires_at timestamptz,
  token text
)
language plpgsql
security definer
set search_path = public, auth, private, extensions
as $$
declare
  v_email text := lower(btrim(coalesce(p_email, '')));
  v_login_email text;
  v_current_recovery_email text;
  v_random bytea;
  v_token text;
  v_token_hash text;
  v_expires_at timestamptz := timezone('utc', now()) + interval '15 minutes';
begin
  if p_user_id is null then
    raise exception 'not_authenticated' using errcode = 'P0001';
  end if;

  if not public.is_active_profile(p_user_id) then
    raise exception 'account_deleted' using errcode = 'P0001';
  end if;

  if v_email = '' or v_email !~* '^[^<>\s@]+@[^<>\s@]+\.[^<>\s@]+$' then
    raise exception 'invalid_email' using errcode = 'P0001';
  end if;

  select lower(users.email)
    into v_login_email
  from auth.users users
  where users.id = p_user_id;

  select profiles.recovery_email
    into v_current_recovery_email
  from public.profiles profiles
  where profiles.id = p_user_id
    and profiles.deleted_at is null;

  if v_email = v_login_email or v_email = v_current_recovery_email then
    raise exception 'same_recovery_email' using errcode = 'P0001';
  end if;

  if exists (
    select 1
    from public.profiles profiles
    where profiles.id <> p_user_id
      and profiles.deleted_at is null
      and profiles.recovery_email = v_email
  ) then
    raise exception 'recovery_email_in_use' using errcode = 'P0001';
  end if;

  v_random := gen_random_bytes(4);
  v_token := lpad(
    (
      (
        get_byte(v_random, 0)::bigint * 16777216
        + get_byte(v_random, 1)::bigint * 65536
        + get_byte(v_random, 2)::bigint * 256
        + get_byte(v_random, 3)::bigint
      ) % 1000000
    )::text,
    6,
    '0'
  );
  v_token_hash := encode(digest(v_token, 'sha256'), 'hex');

  update public.profiles
  set recovery_email_pending = v_email,
      updated_at = timezone('utc', now())
  where id = p_user_id
    and deleted_at is null;

  insert into private.account_recovery_email_challenges (
    profile_id,
    recovery_email_pending,
    otp_hash,
    expires_at
  )
  values (
    p_user_id,
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
  select v_email, v_expires_at, v_token;
end;
$$;

comment on function private.create_recovery_email_challenge(uuid, text) is
  'Creates a recovery email OTP challenge and returns the plaintext token only to trusted server-side callers.';

revoke all on function private.create_recovery_email_challenge(uuid, text) from public;
revoke all on function private.create_recovery_email_challenge(uuid, text) from anon;
revoke all on function private.create_recovery_email_challenge(uuid, text) from authenticated;
grant execute on function private.create_recovery_email_challenge(uuid, text) to service_role;

create or replace function public.create_recovery_email_challenge_for_service(
  p_user_id uuid,
  p_email text
)
returns table (
  recovery_email_pending text,
  expires_at timestamptz,
  token text
)
language plpgsql
security definer
set search_path = public, private, auth, extensions
as $$
begin
  if coalesce(auth.jwt() ->> 'role', current_setting('request.jwt.claim.role', true), '') <> 'service_role' then
    raise exception 'service_role_required' using errcode = 'P0001';
  end if;

  return query
  select
    challenges.recovery_email_pending,
    challenges.expires_at,
    challenges.token
  from private.create_recovery_email_challenge(p_user_id, p_email) challenges;
end;
$$;

comment on function public.create_recovery_email_challenge_for_service(uuid, text) is
  'Service-role-only RPC used by the recovery email OTP Edge Function. Returns plaintext token to the server only.';

revoke all on function public.create_recovery_email_challenge_for_service(uuid, text) from public;
revoke all on function public.create_recovery_email_challenge_for_service(uuid, text) from anon;
revoke all on function public.create_recovery_email_challenge_for_service(uuid, text) from authenticated;
grant execute on function public.create_recovery_email_challenge_for_service(uuid, text) to service_role;

create or replace function public.request_recovery_email_change(
  p_email text
)
returns table (
  recovery_email_pending text,
  expires_at timestamptz
)
language plpgsql
security definer
set search_path = public, private, auth, extensions
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'not_authenticated' using errcode = 'P0001';
  end if;

  return query
  select
    challenges.recovery_email_pending,
    challenges.expires_at
  from private.create_recovery_email_challenge(v_user_id, p_email) challenges;
end;
$$;

revoke all on function public.request_recovery_email_change(text) from public;
revoke all on function public.request_recovery_email_change(text) from anon;
grant execute on function public.request_recovery_email_change(text) to authenticated;

commit;

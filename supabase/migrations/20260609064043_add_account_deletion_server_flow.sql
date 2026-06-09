begin;

create table public.account_deletion_requests (
  id uuid primary key default extensions.gen_random_uuid(),
  profile_id uuid references public.profiles (id) on delete set null,
  requested_at timestamptz not null default timezone('utc', now()),
  completed_at timestamptz,
  status text not null default 'requested',
  reason_code text,
  constraint account_deletion_requests_status_check
    check (status in ('requested', 'completed', 'failed')),
  constraint account_deletion_requests_reason_code_check
    check (reason_code is null or char_length(reason_code) <= 80)
);

comment on table public.account_deletion_requests is
  'Audit records for user-initiated account deletion. Does not store email, phone, or other credential plaintext.';

alter table public.account_deletion_requests enable row level security;

create index account_deletion_requests_profile_id_idx
  on public.account_deletion_requests (profile_id);

alter table public.profiles
  add column deleted_at timestamptz;

comment on column public.profiles.deleted_at is
  'Set by the service-role account deletion flow. The profile row is retained so shared-history foreign keys remain intact.';

create or replace function public.prepare_account_deletion(p_user_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_active_space_count integer;
  v_request_id uuid;
begin
  if p_user_id is null then
    raise exception 'missing user id';
  end if;

  select count(*)
  into v_active_space_count
  from public.couple_memberships memberships
  join public.couple_spaces spaces
    on spaces.id = memberships.couple_space_id
  where memberships.profile_id = p_user_id
    and memberships.status = 'active'
    and memberships.left_at is null
    and spaces.status = 'active'
    and spaces.closed_at is null;

  if v_active_space_count > 0 then
    raise exception 'active_couple_space_required_exit'
      using errcode = 'P0001';
  end if;

  -- A single-user pending space only exists to hold the user's pre-pairing
  -- shell. Close it before deleting the auth user so restrictive profile
  -- foreign keys do not block the auth -> profiles cascade.
  update public.couple_memberships memberships
  set status = 'left',
      left_at = timezone('utc', now())
  from public.couple_spaces spaces
  where spaces.id = memberships.couple_space_id
    and memberships.profile_id = p_user_id
    and memberships.status = 'active'
    and memberships.left_at is null
    and spaces.status = 'pending_partner'
    and spaces.closed_at is null
    and not exists (
      select 1
      from public.couple_memberships other_memberships
      where other_memberships.couple_space_id = memberships.couple_space_id
        and other_memberships.profile_id <> p_user_id
        and other_memberships.status = 'active'
        and other_memberships.left_at is null
    );

  update public.couple_spaces spaces
  set status = 'closed',
      closed_at = timezone('utc', now())
  where spaces.status = 'pending_partner'
    and spaces.closed_at is null
    and spaces.created_by = p_user_id
    and not exists (
      select 1
      from public.couple_memberships memberships
      where memberships.couple_space_id = spaces.id
        and memberships.status = 'active'
        and memberships.left_at is null
    );

  update public.couple_invites invites
  set revoked_at = timezone('utc', now())
  from public.couple_spaces spaces
  where spaces.id = invites.couple_space_id
    and spaces.status = 'closed'
    and spaces.created_by = p_user_id
    and invites.created_by = p_user_id
    and invites.accepted_at is null
    and invites.revoked_at is null;

  update public.profiles
  set deleted_at = timezone('utc', now()),
      display_name = 'Deleted user',
      avatar_url = null,
      notification_preview_enabled = false,
      cycle_sharing_enabled = false
  where id = p_user_id
    and deleted_at is null;

  insert into public.account_deletion_requests (profile_id, status)
  values (
    p_user_id,
    'requested'
  )
  returning id into v_request_id;

  return v_request_id;
end;
$$;

revoke all on table public.account_deletion_requests from public;
revoke all on table public.account_deletion_requests from anon;
revoke all on table public.account_deletion_requests from authenticated;

revoke all on function public.prepare_account_deletion(uuid) from public;
revoke all on function public.prepare_account_deletion(uuid) from anon;
revoke all on function public.prepare_account_deletion(uuid) from authenticated;
grant execute on function public.prepare_account_deletion(uuid) to service_role;

commit;

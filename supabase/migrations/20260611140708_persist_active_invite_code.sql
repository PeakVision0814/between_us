begin;

alter table public.couple_invites
  add column if not exists plain_code text;

alter table public.couple_invites
  drop constraint if exists couple_invites_plain_code_nonempty_check;

alter table public.couple_invites
  add constraint couple_invites_plain_code_nonempty_check
  check (plain_code is null or btrim(plain_code) <> '');

update public.couple_invites
set plain_code = null
where accepted_at is not null
   or revoked_at is not null
   or expires_at <= timezone('utc', now());

drop function if exists public.create_couple_invite(uuid, text, interval);

create or replace function public.create_couple_invite(
  p_couple_space_id uuid,
  p_plain_code text,
  p_expires_in interval default interval '12 hours'
)
returns table (id uuid, plain_code text, expires_at timestamptz)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_existing public.couple_invites%rowtype;
begin
  if auth.uid() is null then
    raise exception 'authentication required';
  end if;

  if not public.is_active_profile(auth.uid()) then
    raise exception 'account deleted';
  end if;

  if p_plain_code is null or btrim(p_plain_code) = '' then
    raise exception 'invite code is required';
  end if;

  if not exists (
    select 1
    from public.couple_memberships memberships
    where memberships.couple_space_id = p_couple_space_id
      and memberships.profile_id = auth.uid()
      and memberships.role = 'owner'
      and memberships.status = 'active'
      and memberships.left_at is null
  ) then
    raise exception 'only the active owner can create an invite';
  end if;

  if (
    select count(*)
    from public.couple_memberships memberships
    where memberships.couple_space_id = p_couple_space_id
      and memberships.status = 'active'
      and memberships.left_at is null
  ) >= 2 then
    raise exception 'couple_space already has two active members';
  end if;

  select invites.*
    into v_existing
  from public.couple_invites invites
  where invites.couple_space_id = p_couple_space_id
    and invites.accepted_at is null
    and invites.revoked_at is null
    and invites.expires_at > timezone('utc', now())
  order by invites.created_at desc
  limit 1;

  if found and v_existing.plain_code is not null then
    return query
    select v_existing.id, v_existing.plain_code, v_existing.expires_at;
    return;
  end if;

  update public.couple_invites as invites
  set revoked_at = timezone('utc', now()),
      plain_code = null
  where invites.couple_space_id = p_couple_space_id
    and invites.accepted_at is null
    and invites.revoked_at is null
    and invites.expires_at > timezone('utc', now());

  return query
  insert into public.couple_invites as ci (
    couple_space_id,
    created_by,
    code_hash,
    plain_code,
    expires_at
  )
  values (
    p_couple_space_id,
    auth.uid(),
    encode(extensions.digest(btrim(p_plain_code), 'sha256'), 'hex'),
    btrim(p_plain_code),
    timezone('utc', now()) + p_expires_in
  )
  returning ci.id, ci.plain_code, ci.expires_at;
end;
$$;

create or replace function public.get_active_couple_invite(
  p_couple_space_id uuid
)
returns table (id uuid, plain_code text, expires_at timestamptz)
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'authentication required';
  end if;

  if not public.is_active_profile(auth.uid()) then
    raise exception 'account deleted';
  end if;

  if not exists (
    select 1
    from public.couple_memberships memberships
    where memberships.couple_space_id = p_couple_space_id
      and memberships.profile_id = auth.uid()
      and memberships.role = 'owner'
      and memberships.status = 'active'
      and memberships.left_at is null
  ) then
    raise exception 'only the active owner can view the invite';
  end if;

  return query
  select invites.id, invites.plain_code, invites.expires_at
  from public.couple_invites invites
  where invites.couple_space_id = p_couple_space_id
    and invites.accepted_at is null
    and invites.revoked_at is null
    and invites.expires_at > timezone('utc', now())
    and invites.plain_code is not null
  order by invites.created_at desc
  limit 1;
end;
$$;

revoke all on function public.create_couple_invite(uuid, text, interval)
  from public;
revoke all on function public.create_couple_invite(uuid, text, interval)
  from anon;
grant execute on function public.create_couple_invite(uuid, text, interval)
  to authenticated;

revoke all on function public.get_active_couple_invite(uuid) from public;
revoke all on function public.get_active_couple_invite(uuid) from anon;
grant execute on function public.get_active_couple_invite(uuid)
  to authenticated;

commit;

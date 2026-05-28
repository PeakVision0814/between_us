-- Qualify table columns inside create_couple_invite to avoid ambiguity with
-- RETURNS TABLE output variables such as expires_at.

create or replace function public.create_couple_invite(
  p_couple_space_id uuid,
  p_plain_code text,
  p_expires_in interval default interval '24 hours'
)
returns table (id uuid, expires_at timestamptz)
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'authentication required';
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

  update public.couple_invites as invites
  set revoked_at = timezone('utc', now())
  where invites.couple_space_id = p_couple_space_id
    and invites.accepted_at is null
    and invites.revoked_at is null
    and invites.expires_at > timezone('utc', now());

  return query
  insert into public.couple_invites as ci (
    couple_space_id,
    created_by,
    code_hash,
    expires_at
  )
  values (
    p_couple_space_id,
    auth.uid(),
    encode(extensions.digest(btrim(p_plain_code), 'sha256'), 'hex'),
    timezone('utc', now()) + p_expires_in
  )
  returning ci.id, ci.expires_at;
end;
$$;

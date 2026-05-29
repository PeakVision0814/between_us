begin;

create or replace function private.cleanup_stale_unverified_email_otp_users(
  p_older_than interval default interval '24 hours',
  p_limit integer default 100,
  p_delete boolean default false
)
returns table (
  user_id uuid,
  email text,
  auth_created_at timestamptz,
  profile_created_at timestamptz,
  deletion_reason text,
  deleted boolean
)
language plpgsql
security definer
set search_path = auth, public, private
as $$
begin
  if p_older_than is null or p_older_than < interval '1 hour' then
    raise exception 'p_older_than must be at least 1 hour';
  end if;

  if p_limit is null or p_limit < 1 or p_limit > 1000 then
    raise exception 'p_limit must be between 1 and 1000';
  end if;

  if p_delete then
    return query
    with candidates as (
      select
        users.id::uuid as user_id,
        users.email::text as email,
        users.created_at::timestamptz as auth_created_at,
        profiles.created_at::timestamptz as profile_created_at,
        'email_unverified_never_signed_in_and_unused'::text as deletion_reason
      from auth.users users
      left join public.profiles profiles
        on profiles.id = users.id
      where users.email is not null
        and users.email_confirmed_at is null
        and users.phone_confirmed_at is null
        and users.last_sign_in_at is null
        and users.created_at < timezone('utc', now()) - p_older_than
        and not exists (
          select 1
          from public.couple_spaces spaces
          where spaces.created_by = users.id
        )
        and not exists (
          select 1
          from public.couple_memberships memberships
          where memberships.profile_id = users.id
        )
        and not exists (
          select 1
          from public.couple_invites invites
          where invites.created_by = users.id
             or invites.accepted_by = users.id
        )
        and not exists (
          select 1
          from public.calendar_events events
          where events.created_by = users.id
        )
        and not exists (
          select 1
          from public.plans plans
          where plans.created_by = users.id
        )
        and not exists (
          select 1
          from public.notes notes
          where notes.author_profile_id = users.id
        )
      order by users.created_at asc
      limit p_limit
    ),
    deleted_users as (
      delete from auth.users users
      using candidates
      where users.id = candidates.user_id
      returning users.id
    )
    select
      candidates.user_id,
      candidates.email,
      candidates.auth_created_at,
      candidates.profile_created_at,
      candidates.deletion_reason,
      true as deleted
    from candidates
    join deleted_users
      on deleted_users.id = candidates.user_id
    order by candidates.auth_created_at asc;
  else
    return query
    select
      users.id::uuid as user_id,
      users.email::text as email,
      users.created_at::timestamptz as auth_created_at,
      profiles.created_at::timestamptz as profile_created_at,
      'email_unverified_never_signed_in_and_unused'::text as deletion_reason,
      false as deleted
    from auth.users users
    left join public.profiles profiles
      on profiles.id = users.id
    where users.email is not null
      and users.email_confirmed_at is null
      and users.phone_confirmed_at is null
      and users.last_sign_in_at is null
      and users.created_at < timezone('utc', now()) - p_older_than
      and not exists (
        select 1
        from public.couple_spaces spaces
        where spaces.created_by = users.id
      )
      and not exists (
        select 1
        from public.couple_memberships memberships
        where memberships.profile_id = users.id
      )
      and not exists (
        select 1
        from public.couple_invites invites
        where invites.created_by = users.id
           or invites.accepted_by = users.id
      )
      and not exists (
        select 1
        from public.calendar_events events
        where events.created_by = users.id
      )
      and not exists (
        select 1
        from public.plans plans
        where plans.created_by = users.id
      )
      and not exists (
        select 1
        from public.notes notes
        where notes.author_profile_id = users.id
      )
    order by users.created_at asc
    limit p_limit;
  end if;
end;
$$;

commit;

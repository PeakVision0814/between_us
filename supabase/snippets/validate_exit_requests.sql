-- Validation script for couple space exit requests.
-- Run after supabase db reset --local.
--
-- Usage (via Docker):
--   docker exec -i supabase_db_between_us psql -U postgres -d postgres \
--     < supabase/snippets/validate_exit_requests.sql

-- =============================================================
-- Part A: Anon / authenticated permission checks (plain SQL).
-- =============================================================

-- Test 11: anon has NO execute on request_couple_space_exit().
do $$
declare
  v_has_priv boolean;
begin
  select has_function_privilege(
    'anon',
    'public.request_couple_space_exit()',
    'execute'
  ) into v_has_priv;

  if v_has_priv then
    raise exception 'FAIL: Test 11 - anon should NOT have execute on request_couple_space_exit()';
  end if;

  raise notice 'PASS: Test 11 - anon cannot execute request_couple_space_exit()';
end;
$$;

-- Test 12: anon has NO execute on approve_couple_space_exit(uuid).
do $$
declare
  v_has_priv boolean;
begin
  select has_function_privilege(
    'anon',
    'public.approve_couple_space_exit(uuid)',
    'execute'
  ) into v_has_priv;

  if v_has_priv then
    raise exception 'FAIL: Test 12 - anon should NOT have execute on approve_couple_space_exit(uuid)';
  end if;

  raise notice 'PASS: Test 12 - anon cannot execute approve_couple_space_exit(uuid)';
end;
$$;

-- Test 13: authenticated HAS execute on request_couple_space_exit().
do $$
declare
  v_has_priv boolean;
begin
  select has_function_privilege(
    'authenticated',
    'public.request_couple_space_exit()',
    'execute'
  ) into v_has_priv;

  if not v_has_priv then
    raise exception 'FAIL: Test 13 - authenticated should have execute on request_couple_space_exit()';
  end if;

  raise notice 'PASS: Test 13 - authenticated can execute request_couple_space_exit()';
end;
$$;

-- Test 14: authenticated HAS execute on approve_couple_space_exit(uuid).
do $$
declare
  v_has_priv boolean;
begin
  select has_function_privilege(
    'authenticated',
    'public.approve_couple_space_exit(uuid)',
    'execute'
  ) into v_has_priv;

  if not v_has_priv then
    raise exception 'FAIL: Test 14 - authenticated should have execute on approve_couple_space_exit(uuid)';
  end if;

  raise notice 'PASS: Test 14 - authenticated can execute approve_couple_space_exit(uuid)';
end;
$$;

-- =============================================================
-- Part B: Functional tests (single DO block).
-- =============================================================

do $$
declare
  v_user_a uuid;
  v_user_b uuid;
  v_random_user uuid;
  v_space_id uuid;
  v_request_id uuid;
  v_second_request_id uuid;
  v_closed_space_id uuid;
  v_plan_id uuid;
  v_note_id uuid;
  v_cal_id uuid;
  v_count int;
  v_status text;
begin
  -- Setup: create two test users and a couple space.

  insert into auth.users (id, email, raw_user_meta_data)
  values (
    extensions.gen_random_uuid(),
    'exit-test-a@example.com',
    '{"display_name": "UserA"}'::jsonb
  )
  returning id into v_user_a;

  insert into auth.users (id, email, raw_user_meta_data)
  values (
    extensions.gen_random_uuid(),
    'exit-test-b@example.com',
    '{"display_name": "UserB"}'::jsonb
  )
  returning id into v_user_b;

  v_random_user := extensions.gen_random_uuid();

  -- Create couple space as user A (bypass RLS via postgres role).
  set local role postgres;
  insert into public.couple_spaces (created_by, space_name, status)
  values (v_user_a, 'TestSpace', 'active')
  returning id into v_space_id;

  insert into public.couple_memberships (couple_space_id, profile_id, role, status)
  values (v_space_id, v_user_a, 'owner', 'active');

  insert into public.couple_memberships (couple_space_id, profile_id, role, status)
  values (v_space_id, v_user_b, 'partner', 'active');

  -- Shared data for later visibility checks.
  insert into public.plans (couple_space_id, created_by, title, body, status)
  values (v_space_id, v_user_a, 'TestPlan', 'body', 'idea')
  returning id into v_plan_id;

  insert into public.notes (couple_space_id, author_profile_id, body, author_local_date)
  values (v_space_id, v_user_a, 'TestNote', current_date)
  returning id into v_note_id;

  insert into public.calendar_events (couple_space_id, created_by, event_type, title, starts_at, all_day)
  values (v_space_id, v_user_a, 'reminder', 'TestEvent', now(), true)
  returning id into v_cal_id;

  reset role;

  raise notice '=== Setup complete ===';
  raise notice 'User A: %', v_user_a;
  raise notice 'User B: %', v_user_b;
  raise notice 'Space: %', v_space_id;

  -- Test 1: Single-mode user cannot request exit.

  begin
    execute format(
      'set local role authenticated; set local request.jwt.claims = %L',
      jsonb_build_object('sub', v_random_user::text)::text
    );
    perform public.request_couple_space_exit();
    raise exception 'FAIL: Test 1 - single-mode user should not be able to request exit';
  exception
    when others then
      if sqlerrm like '%no active couple space found%' then
        raise notice 'PASS: Test 1 - single-mode user correctly rejected';
      else
        raise;
      end if;
  end;

  reset role;

  -- Test 2: Active couple space member A can request exit.

  execute format(
    'set local role authenticated; set local request.jwt.claims = %L',
    jsonb_build_object('sub', v_user_a::text)::text
  );
  v_request_id := public.request_couple_space_exit();
  reset role;

  if v_request_id is null then
    raise exception 'FAIL: Test 2 - request_couple_space_exit returned null';
  end if;

  set local role postgres;
  select status into v_status
  from public.couple_space_exit_requests
  where id = v_request_id;
  reset role;

  if v_status <> 'pending' then
    raise exception 'FAIL: Test 2 - request status is %, expected pending', v_status;
  end if;

  raise notice 'PASS: Test 2 - user A requested exit (request_id: %)', v_request_id;

  -- Test 3: Calling request again returns the same pending request.

  execute format(
    'set local role authenticated; set local request.jwt.claims = %L',
    jsonb_build_object('sub', v_user_a::text)::text
  );
  v_second_request_id := public.request_couple_space_exit();
  reset role;

  if v_second_request_id <> v_request_id then
    raise exception 'FAIL: Test 3 - second request returned different id (% vs %)', v_second_request_id, v_request_id;
  end if;

  raise notice 'PASS: Test 3 - duplicate request returns existing pending request';

  -- Test 4: A cannot approve their own request.

  begin
    execute format(
      'set local role authenticated; set local request.jwt.claims = %L',
      jsonb_build_object('sub', v_user_a::text)::text
    );
    perform public.approve_couple_space_exit(v_request_id);
    raise exception 'FAIL: Test 4 - requester should not be able to approve own request';
  exception
    when others then
      if sqlerrm like '%requester cannot approve%' then
        raise notice 'PASS: Test 4 - self-approval correctly rejected';
      else
        raise;
      end if;
  end;

  reset role;

  -- Test 5: B can approve A's exit request.

  execute format(
    'set local role authenticated; set local request.jwt.claims = %L',
    jsonb_build_object('sub', v_user_b::text)::text
  );
  v_closed_space_id := public.approve_couple_space_exit(v_request_id);
  reset role;

  if v_closed_space_id <> v_space_id then
    raise exception 'FAIL: Test 5 - returned space id mismatch';
  end if;

  raise notice 'PASS: Test 5 - user B approved exit request';

  -- Test 6: couple_spaces.status is now 'closed'.

  set local role postgres;
  select status into v_status
  from public.couple_spaces
  where id = v_space_id;
  reset role;

  if v_status <> 'closed' then
    raise exception 'FAIL: Test 6 - couple_spaces.status is %, expected closed', v_status;
  end if;

  raise notice 'PASS: Test 6 - couple_spaces.status = closed';

  -- Test 7: Both memberships are 'left'.

  set local role postgres;
  select count(*) into v_count
  from public.couple_memberships
  where couple_space_id = v_space_id
    and status = 'active'
    and left_at is null;

  if v_count <> 0 then
    raise exception 'FAIL: Test 7a - still have % active memberships', v_count;
  end if;

  select count(*) into v_count
  from public.couple_memberships
  where couple_space_id = v_space_id
    and status = 'left'
    and left_at is not null;

  if v_count <> 2 then
    raise exception 'FAIL: Test 7b - expected 2 left memberships, got %', v_count;
  end if;

  reset role;

  raise notice 'PASS: Test 7 - both memberships are left';

  -- Test 8: Shared data is no longer visible to authenticated users.

  execute format(
    'set local role authenticated; set local request.jwt.claims = %L',
    jsonb_build_object('sub', v_user_a::text)::text
  );

  select count(*) into v_count
  from public.plans
  where couple_space_id = v_space_id;

  if v_count <> 0 then
    raise exception 'FAIL: Test 8a - plans still visible (% rows)', v_count;
  end if;

  select count(*) into v_count
  from public.notes
  where couple_space_id = v_space_id;

  if v_count <> 0 then
    raise exception 'FAIL: Test 8b - notes still visible (% rows)', v_count;
  end if;

  select count(*) into v_count
  from public.calendar_events
  where couple_space_id = v_space_id;

  if v_count <> 0 then
    raise exception 'FAIL: Test 8c - calendar_events still visible (% rows)', v_count;
  end if;

  reset role;

  raise notice 'PASS: Test 8 - shared data is not visible after space closure';

  -- Test 9: Data still exists (not physically deleted).

  set local role postgres;

  select count(*) into v_count
  from public.plans
  where couple_space_id = v_space_id;

  if v_count <> 1 then
    raise exception 'FAIL: Test 9a - plans data missing (count=%)', v_count;
  end if;

  select count(*) into v_count
  from public.notes
  where couple_space_id = v_space_id;

  if v_count <> 1 then
    raise exception 'FAIL: Test 9b - notes data missing (count=%)', v_count;
  end if;

  select count(*) into v_count
  from public.calendar_events
  where couple_space_id = v_space_id;

  if v_count <> 1 then
    raise exception 'FAIL: Test 9c - calendar_events data missing (count=%)', v_count;
  end if;

  reset role;

  raise notice 'PASS: Test 9 - shared data still exists (not physically deleted)';

  -- Test 10: Exit request is now 'approved'.

  set local role postgres;
  select status into v_status
  from public.couple_space_exit_requests
  where id = v_request_id;
  reset role;

  if v_status <> 'approved' then
    raise exception 'FAIL: Test 10 - exit request status is %, expected approved', v_status;
  end if;

  raise notice 'PASS: Test 10 - exit request status = approved';

  -- Test 15: immutable field protection on couple_space_exit_requests.

  begin
    set local role postgres;
    update public.couple_space_exit_requests
    set requested_by = v_user_b
    where id = v_request_id;
    raise exception 'FAIL: Test 15 - immutable field protection should block requested_by change';
  exception
    when others then
      if sqlerrm like '%immutable fields cannot be changed%' then
        raise notice 'PASS: Test 15 - immutable field protection works on exit requests';
      else
        raise;
      end if;
  end;

  reset role;

  -- Cleanup.

  set local role postgres;
  delete from public.couple_space_exit_requests where couple_space_id = v_space_id;
  delete from public.calendar_events where couple_space_id = v_space_id;
  delete from public.notes where couple_space_id = v_space_id;
  delete from public.plans where couple_space_id = v_space_id;
  delete from public.couple_memberships where couple_space_id = v_space_id;
  delete from public.couple_spaces where id = v_space_id;
  delete from auth.users where id in (v_user_a, v_user_b);
  reset role;

  raise notice '=== All functional tests passed ===';
end;
$$;

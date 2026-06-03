-- ============================================================
-- RLS 验证脚本：restrict_shared_writes_to_active_couple
-- 执行方式：supabase db query --local --file docs/rls_verify_20260603.sql
-- 整个脚本为单条 DO 块，兼容 prepared statement 执行方式
-- ============================================================

DO $$
DECLARE
  v_count int;
BEGIN
  -- ── 准备 ──
  DELETE FROM public.notes WHERE body LIKE 'rls-test-%';
  DELETE FROM public.plans WHERE title LIKE 'rls-test-%';
  DELETE FROM public.calendar_events WHERE title LIKE 'rls-test-%';
  DELETE FROM public.couple_memberships WHERE couple_space_id IN (
    SELECT id FROM public.couple_spaces WHERE space_name LIKE 'rls-test-%'
  );
  DELETE FROM public.couple_spaces WHERE space_name LIKE 'rls-test-%';
  DELETE FROM public.profiles WHERE id IN (
    '11111111-1111-1111-1111-111111111111',
    '22222222-2222-2222-2222-222222222222'
  );
  DELETE FROM auth.users WHERE id IN (
    '11111111-1111-1111-1111-111111111111',
    '22222222-2222-2222-2222-222222222222'
  );

  INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, raw_user_meta_data)
  VALUES
    ('11111111-1111-1111-1111-111111111111', 'rls-u1@example.com', crypt('test', gen_salt('bf')), now(), '{}'),
    ('22222222-2222-2222-2222-222222222222', 'rls-u2@example.com', crypt('test', gen_salt('bf')), now(), '{}');

  INSERT INTO public.profiles (id, display_name) VALUES
    ('11111111-1111-1111-1111-111111111111', 'TestUser1'),
    ('22222222-2222-2222-2222-222222222222', 'TestUser2')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.couple_spaces (id, created_by, space_name, status)
  VALUES ('aaaa0000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'rls-test-pending', 'pending_partner');

  INSERT INTO public.couple_memberships (couple_space_id, profile_id, role)
  VALUES ('aaaa0000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'owner');

  RAISE NOTICE '=== Setup done ===';

  -- ── 场景 1：pending_partner 空间写入应全部失败 ──

  PERFORM set_config('role', 'authenticated', true);
  PERFORM set_config('request.jwt.claims', '{"sub":"11111111-1111-1111-1111-111111111111"}', true);

  BEGIN
    INSERT INTO public.calendar_events (couple_space_id, created_by, event_type, title, starts_at)
    VALUES ('aaaa0000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'reminder', 'rls-test-event', now());
    RAISE EXCEPTION 'EXPECTED FAIL: pending insert calendar_events not blocked';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM LIKE 'EXPECTED FAIL%' THEN RAISE; END IF;
    RAISE NOTICE 'PASS: pending insert calendar_events blocked';
  END;

  BEGIN
    INSERT INTO public.plans (couple_space_id, created_by, title)
    VALUES ('aaaa0000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'rls-test-plan');
    RAISE EXCEPTION 'EXPECTED FAIL: pending insert plans not blocked';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM LIKE 'EXPECTED FAIL%' THEN RAISE; END IF;
    RAISE NOTICE 'PASS: pending insert plans blocked';
  END;

  BEGIN
    INSERT INTO public.notes (couple_space_id, author_profile_id, body, author_local_date)
    VALUES ('aaaa0000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'rls-test-note', current_date);
    RAISE EXCEPTION 'EXPECTED FAIL: pending insert notes not blocked';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM LIKE 'EXPECTED FAIL%' THEN RAISE; END IF;
    RAISE NOTICE 'PASS: pending insert notes blocked';
  END;

  PERFORM set_config('role', 'postgres', true);

  -- ── 场景 2：active 双人空间写入应成功 ──

  UPDATE public.couple_spaces SET status = 'active' WHERE id = 'aaaa0000-0000-0000-0000-000000000001';
  INSERT INTO public.couple_memberships (couple_space_id, profile_id, role)
  VALUES ('aaaa0000-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', 'partner');

  PERFORM set_config('role', 'authenticated', true);
  PERFORM set_config('request.jwt.claims', '{"sub":"11111111-1111-1111-1111-111111111111"}', true);

  INSERT INTO public.calendar_events (couple_space_id, created_by, event_type, title, starts_at)
  VALUES ('aaaa0000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'reminder', 'rls-test-event-active', now());
  RAISE NOTICE 'PASS: active insert calendar_events succeeded';

  INSERT INTO public.plans (couple_space_id, created_by, title)
  VALUES ('aaaa0000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'rls-test-plan-active');
  RAISE NOTICE 'PASS: active insert plans succeeded';

  INSERT INTO public.notes (couple_space_id, author_profile_id, body, author_local_date)
  VALUES ('aaaa0000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'rls-test-note-active', current_date);
  RAISE NOTICE 'PASS: active insert notes succeeded';

  PERFORM set_config('role', 'postgres', true);

  -- ── 场景 3：notes 作者权限 ──

  -- 作者 update 自己的 note（应成功）
  PERFORM set_config('role', 'authenticated', true);
  PERFORM set_config('request.jwt.claims', '{"sub":"11111111-1111-1111-1111-111111111111"}', true);


  UPDATE public.notes SET body = 'rls-test-note-updated'
  WHERE body = 'rls-test-note-active';
  GET DIAGNOSTICS v_count = ROW_COUNT;
  IF v_count = 1 THEN
    RAISE NOTICE 'PASS: author update own note succeeded';
  ELSE
    RAISE EXCEPTION 'FAIL: author update should affect 1 row, got %', v_count;
  END IF;

  PERFORM set_config('role', 'postgres', true);

  -- 非作者 update 别人的 note（应返回 0 行）
  PERFORM set_config('role', 'authenticated', true);
  PERFORM set_config('request.jwt.claims', '{"sub":"22222222-2222-2222-2222-222222222222"}', true);

  UPDATE public.notes SET body = 'rls-test-note-hacked'
  WHERE body = 'rls-test-note-updated';
  GET DIAGNOSTICS v_count = ROW_COUNT;
  IF v_count = 0 THEN
    RAISE NOTICE 'PASS: non-author update note blocked (0 rows)';
  ELSE
    RAISE EXCEPTION 'FAIL: non-author update should affect 0 rows, got %', v_count;
  END IF;

  PERFORM set_config('role', 'postgres', true);

  -- ── 场景 4：active 空间 update calendar_events / plans ──

  PERFORM set_config('role', 'authenticated', true);
  PERFORM set_config('request.jwt.claims', '{"sub":"11111111-1111-1111-1111-111111111111"}', true);

  UPDATE public.calendar_events SET title = 'rls-test-event-updated'
  WHERE title = 'rls-test-event-active';
  GET DIAGNOSTICS v_count = ROW_COUNT;
  IF v_count = 1 THEN
    RAISE NOTICE 'PASS: active update calendar_events succeeded';
  ELSE
    RAISE EXCEPTION 'FAIL: active update calendar_events should affect 1 row, got %', v_count;
  END IF;

  UPDATE public.plans SET title = 'rls-test-plan-updated'
  WHERE title = 'rls-test-plan-active';
  GET DIAGNOSTICS v_count = ROW_COUNT;
  IF v_count = 1 THEN
    RAISE NOTICE 'PASS: active update plans succeeded';
  ELSE
    RAISE EXCEPTION 'FAIL: active update plans should affect 1 row, got %', v_count;
  END IF;

  PERFORM set_config('role', 'postgres', true);

  -- ── 场景 5：pending_partner 空间 select 应返回 0 行 ──
  -- 先降级空间回 pending_partner，移除第二个成员
  DELETE FROM public.couple_memberships
  WHERE couple_space_id = 'aaaa0000-0000-0000-0000-000000000001'
    AND profile_id = '22222222-2222-2222-2222-222222222222';
  UPDATE public.couple_spaces SET status = 'pending_partner'
  WHERE id = 'aaaa0000-0000-0000-0000-000000000001';

  -- 插入一些测试数据（以 postgres 绕过 RLS）
  INSERT INTO public.calendar_events (couple_space_id, created_by, event_type, title, starts_at)
  VALUES ('aaaa0000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'reminder', 'rls-test-select-event', now());
  INSERT INTO public.plans (couple_space_id, created_by, title)
  VALUES ('aaaa0000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'rls-test-select-plan');
  INSERT INTO public.notes (couple_space_id, author_profile_id, body, author_local_date)
  VALUES ('aaaa0000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'rls-test-select-note', current_date);

  -- 以 user1 身份 select（pending_partner，应返回 0 行）
  PERFORM set_config('role', 'authenticated', true);
  PERFORM set_config('request.jwt.claims', '{"sub":"11111111-1111-1111-1111-111111111111"}', true);

  SELECT count(*) INTO v_count FROM public.calendar_events WHERE title = 'rls-test-select-event';
  IF v_count = 0 THEN
    RAISE NOTICE 'PASS: pending_partner select calendar_events returns 0 rows';
  ELSE
    RAISE EXCEPTION 'FAIL: pending_partner select calendar_events should return 0 rows, got %', v_count;
  END IF;

  SELECT count(*) INTO v_count FROM public.plans WHERE title = 'rls-test-select-plan';
  IF v_count = 0 THEN
    RAISE NOTICE 'PASS: pending_partner select plans returns 0 rows';
  ELSE
    RAISE EXCEPTION 'FAIL: pending_partner select plans should return 0 rows, got %', v_count;
  END IF;

  SELECT count(*) INTO v_count FROM public.notes WHERE body = 'rls-test-select-note';
  IF v_count = 0 THEN
    RAISE NOTICE 'PASS: pending_partner select notes returns 0 rows';
  ELSE
    RAISE EXCEPTION 'FAIL: pending_partner select notes should return 0 rows, got %', v_count;
  END IF;

  PERFORM set_config('role', 'postgres', true);

  -- ── 场景 6：active 双人空间 select 应可见 ──
  UPDATE public.couple_spaces SET status = 'active'
  WHERE id = 'aaaa0000-0000-0000-0000-000000000001';
  INSERT INTO public.couple_memberships (couple_space_id, profile_id, role)
  VALUES ('aaaa0000-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', 'partner');

  PERFORM set_config('role', 'authenticated', true);
  PERFORM set_config('request.jwt.claims', '{"sub":"11111111-1111-1111-1111-111111111111"}', true);

  SELECT count(*) INTO v_count FROM public.calendar_events WHERE title = 'rls-test-select-event';
  IF v_count = 1 THEN
    RAISE NOTICE 'PASS: active couple select calendar_events returns 1 row';
  ELSE
    RAISE EXCEPTION 'FAIL: active couple select calendar_events should return 1 row, got %', v_count;
  END IF;

  SELECT count(*) INTO v_count FROM public.plans WHERE title = 'rls-test-select-plan';
  IF v_count = 1 THEN
    RAISE NOTICE 'PASS: active couple select plans returns 1 row';
  ELSE
    RAISE EXCEPTION 'FAIL: active couple select plans should return 1 row, got %', v_count;
  END IF;

  SELECT count(*) INTO v_count FROM public.notes WHERE body = 'rls-test-select-note';
  IF v_count = 1 THEN
    RAISE NOTICE 'PASS: active couple select notes returns 1 row';
  ELSE
    RAISE EXCEPTION 'FAIL: active couple select notes should return 1 row, got %', v_count;
  END IF;

  PERFORM set_config('role', 'postgres', true);

  -- ── 清理 ──
  DELETE FROM public.notes WHERE body LIKE 'rls-test-%';
  DELETE FROM public.plans WHERE title LIKE 'rls-test-%';
  DELETE FROM public.calendar_events WHERE title LIKE 'rls-test-%';
  DELETE FROM public.couple_memberships WHERE couple_space_id = 'aaaa0000-0000-0000-0000-000000000001';
  DELETE FROM public.couple_spaces WHERE id = 'aaaa0000-0000-0000-0000-000000000001';
  DELETE FROM public.profiles WHERE id IN ('11111111-1111-1111-1111-111111111111','22222222-2222-2222-2222-222222222222');
  DELETE FROM auth.users WHERE id IN ('11111111-1111-1111-1111-111111111111','22222222-2222-2222-2222-222222222222');

  RAISE NOTICE '=== All RLS verification tests completed ===';
END $$;

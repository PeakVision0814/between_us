import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String sql;
  late String deliverySql;

  setUpAll(() {
    sql = Directory('supabase/migrations')
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.sql'))
        .map((file) => file.readAsStringSync())
        .join('\n');
    deliverySql = File(
      'supabase/migrations/20260610013051_add_recovery_email_otp_delivery.sql',
    ).readAsStringSync();
  });

  test('recovery email has a verified unique constraint', () {
    expect(sql, contains('profiles_recovery_email_unique_idx'));
    expect(sql, contains('on public.profiles (recovery_email)'));
    expect(
      sql,
      contains('where recovery_email is not null and deleted_at is null'),
    );
  });

  test('recovery email RPCs use auth.uid and do not accept client user id', () {
    final requestRpc = RegExp(
      r'create or replace function public\.request_recovery_email_change\([\s\S]*?\$\$;',
    ).allMatches(sql).last.group(0)!;
    final verifyRpc = RegExp(
      r'create or replace function public\.verify_recovery_email_change\([\s\S]*?\$\$;',
    ).firstMatch(sql)!.group(0)!;

    expect(requestRpc, contains('v_user_id uuid := auth.uid()'));
    expect(requestRpc, contains('request_recovery_email_change('));
    expect(requestRpc, contains('p_email text'));
    expect(verifyRpc, contains('verify_recovery_email_change('));
    expect(verifyRpc, contains('p_token text'));
    expect(requestRpc, isNot(contains('p_user_id')));
    expect(verifyRpc, isNot(contains('p_user_id')));
  });

  test('service-only recovery email challenge can return plaintext token', () {
    expect(sql, contains('request_recovery_email_change('));
    expect(sql, contains('private.create_recovery_email_challenge('));
    expect(sql, contains('create_recovery_email_challenge_for_service('));
    expect(sql, contains("auth.jwt() ->> 'role'"));
    expect(sql, contains("raise exception 'service_role_required'"));
    expect(
      sql,
      contains(
        'revoke all on function public.create_recovery_email_challenge_for_service(uuid, text) from authenticated',
      ),
    );
    expect(
      sql,
      contains(
        'grant execute on function public.create_recovery_email_challenge_for_service(uuid, text) to service_role',
      ),
    );
  });

  test('RLS and column grants block direct recovery email writes', () {
    expect(
      sql,
      contains('revoke update on public.profiles from authenticated'),
    );
    expect(sql, contains('grant update ('));
    final grantBlock = RegExp(
      r'grant update \([\s\S]*?\) on public\.profiles to authenticated;',
    ).firstMatch(sql)!.group(0)!;
    expect(grantBlock, isNot(contains('recovery_email')));
    expect(
      sql,
      contains(
        'grant execute on function public.request_recovery_email_change(text) to authenticated',
      ),
    );
    expect(
      sql,
      contains(
        'grant execute on function public.verify_recovery_email_change(text) to authenticated',
      ),
    );
  });

  test('token hash is stored only in a private challenge table', () {
    final profileColumnsBlock = RegExp(
      r'alter table public\.profiles[\s\S]*?;',
    ).firstMatch(sql)!.group(0)!;
    expect(profileColumnsBlock, isNot(contains('recovery_email_otp_hash')));
    expect(
      profileColumnsBlock,
      isNot(contains('recovery_email_otp_expires_at')),
    );
    expect(
      sql,
      contains('create table private.account_recovery_email_challenges'),
    );
    expect(sql, contains('otp_hash text not null'));
    expect(sql, contains("encode(digest(v_token, 'sha256'), 'hex')"));
    expect(
      sql,
      contains(
        'revoke all on table private.account_recovery_email_challenges from authenticated',
      ),
    );
    expect(sql, contains('recovery_email_pending text'));
    expect(sql, contains('expires_at timestamptz'));
    expect(sql, isNot(contains('development_token')));
    expect(sql, isNot(contains('raise log')));
  });

  test('recovery email format excludes SMTP envelope delimiters', () {
    expect(
      deliverySql,
      contains(
        'drop constraint if exists profiles_recovery_email_format_check',
      ),
    );
    expect(
      deliverySql,
      contains(
        'drop constraint if exists account_recovery_email_challenges_pending_format_check',
      ),
    );
    expect(
      deliverySql,
      contains(r"recovery_email ~* '^[^<>\s@]+@[^<>\s@]+\.[^<>\s@]+$'"),
    );
    expect(
      deliverySql,
      contains(r"recovery_email_pending ~* '^[^<>\s@]+@[^<>\s@]+\.[^<>\s@]+$'"),
    );
    expect(
      deliverySql,
      contains(
        r"v_email = '' or v_email !~* '^[^<>\s@]+@[^<>\s@]+\.[^<>\s@]+$'",
      ),
    );
  });

  test('deleted accounts cannot request or verify recovery email', () {
    expect(sql, contains('if not public.is_active_profile(v_user_id) then'));
    expect(sql, contains("raise exception 'account_deleted'"));
    expect(sql, contains('where profiles.id = auth.uid()'));
    expect(sql, contains('and profiles.deleted_at is null'));
  });
}

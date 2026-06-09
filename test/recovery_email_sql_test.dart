import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String sql;

  setUpAll(() {
    sql = File(
      'supabase/migrations/20260609152812_add_recovery_email_v1.sql',
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
    expect(sql, contains('v_user_id uuid := auth.uid()'));
    expect(sql, contains('request_recovery_email_change('));
    expect(sql, contains('p_email text'));
    expect(sql, contains('verify_recovery_email_change('));
    expect(sql, contains('p_token text'));
    expect(sql, isNot(contains('p_user_id')));
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
    expect(sql, isNot(contains('development_token')));
    expect(sql, isNot(contains('raise log')));
  });

  test('deleted accounts cannot request or verify recovery email', () {
    expect(sql, contains('if not public.is_active_profile(v_user_id) then'));
    expect(sql, contains("raise exception 'account_deleted'"));
    expect(sql, contains('where profiles.id = auth.uid()'));
    expect(sql, contains('and profiles.deleted_at is null'));
  });
}

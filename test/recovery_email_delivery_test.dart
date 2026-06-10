import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Flutter requests recovery email OTP through Edge Function', () {
    final source = File('lib/app/app_controller.dart').readAsStringSync();
    final start = source.indexOf('Future<bool> requestRecoveryEmailChange');
    final end = source.indexOf('Future<bool> verifyRecoveryEmailChange');
    final requestMethod = source.substring(start, end);

    expect(requestMethod, contains("functions.invoke("));
    expect(requestMethod, contains("'send-recovery-email-otp'"));
    expect(requestMethod, contains("body: {'email': normalizedEmail}"));
    expect(requestMethod, isNot(contains("'request_recovery_email_change'")));
    expect(requestMethod, isNot(contains("['token']")));
  });

  test('Edge Function is configured for JWT verified local delivery', () {
    final config = File('supabase/config.toml').readAsStringSync();

    expect(config, contains('[functions.send-recovery-email-otp]'));
    expect(config, contains('verify_jwt = true'));
    expect(config, contains('[inbucket]'));
    expect(config, contains('port = 54324'));
    expect(config, contains('smtp_port = 54325'));
  });

  test('Edge Function rejects SMTP envelope delimiters in email values', () {
    final source = File(
      'supabase/functions/send-recovery-email-otp/index.ts',
    ).readAsStringSync();

    expect(source, contains('function isSafeEmailAddress'));
    expect(source, contains(r'/^[^<>\s@]+@[^<>\s@]+\.[^<>\s@]+$/'));
    expect(source, contains('!isSafeEmailAddress(fromEmail)'));
  });
}

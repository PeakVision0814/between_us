import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_controller.dart';
import '../../app/app_strings.dart';

class EmailOtpSignInScreen extends StatefulWidget {
  const EmailOtpSignInScreen({super.key});

  @override
  State<EmailOtpSignInScreen> createState() => _EmailOtpSignInScreenState();
}

class _EmailOtpSignInScreenState extends State<EmailOtpSignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final controller = AppScope.read(context);
    final success = await controller.sendEmailOtp(_emailController.text);
    if (!mounted || !success) {
      return;
    }

    _codeController.clear();
    final strings = AppStrings.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          strings.isChinese
              ? '\u9a8c\u8bc1\u7801\u5df2\u53d1\u9001\uff0c\u8bf7\u5728 App \u5185\u8f93\u5165 6 \u4f4d\u9a8c\u8bc1\u7801'
              : 'Verification code sent. Enter the 6-digit code in the app.',
        ),
      ),
    );
  }

  Future<void> _verifyCode() async {
    final controller = AppScope.read(context);
    await controller.verifyEmailOtp(_codeController.text);
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final strings = AppStrings.of(context);
    final isChinese = strings.isChinese;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isOtpStep = controller.authStatus == AppAuthStatus.otpSent;
    final isBootstrapping = controller.authStatus == AppAuthStatus.initializing;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          Icons.lock_open_rounded,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        isChinese
                            ? '\u767b\u5f55\u540e\u624d\u80fd\u8fdb\u5165 Between Us'
                            : 'Sign in before entering Between Us',
                        key: const ValueKey('auth-login-title'),
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isChinese
                            ? '\u672c\u8f6e\u53ea\u5f00\u653e\u90ae\u7bb1\u9a8c\u8bc1\u7801\u767b\u5f55\uff0c\u624b\u673a\u53f7\u9a8c\u8bc1\u7801\u767b\u5f55\u4f1a\u5728\u540e\u7eed\u7248\u672c\u63d0\u4f9b\u3002'
                            : 'Email OTP is the only login method for now. Phone OTP will be added later.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      if (isBootstrapping) ...[
                        const Center(child: CircularProgressIndicator()),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            isChinese
                                ? '\u6b63\u5728\u68c0\u67e5\u767b\u5f55\u72b6\u6001...'
                                : 'Checking your session...',
                          ),
                        ),
                      ] else ...[
                        if (controller.authErrorCode case final errorCode?)
                          _AuthBanner(
                            message: _errorText(errorCode, isChinese),
                            retryLabel: isChinese ? '\u91cd\u8bd5' : 'Retry',
                            onRetry: controller.supabaseReady
                                ? null
                                : () => controller.bootstrap(),
                          ),
                        if (controller.authErrorCode != null)
                          const SizedBox(height: 16),
                        if (isOtpStep)
                          _OtpStep(
                            pendingEmail:
                                controller.pendingEmail ??
                                _emailController.text.trim(),
                            codeController: _codeController,
                            busy: controller.authBusy,
                            isChinese: isChinese,
                            onCodeChanged: (_) => controller.clearAuthError(),
                            onBack: () {
                              _codeController.clear();
                              controller.returnToEmailEntry();
                            },
                            onVerify: _verifyCode,
                          )
                        else
                          _EmailStep(
                            emailController: _emailController,
                            busy:
                                controller.authBusy ||
                                !controller.supabaseReady,
                            isChinese: isChinese,
                            onEmailChanged: (_) => controller.clearAuthError(),
                            onSubmit: _sendCode,
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _errorText(String errorCode, bool isChinese) {
    return switch (errorCode) {
      'initialize_failed' =>
        isChinese
            ? '\u767b\u5f55\u670d\u52a1\u521d\u59cb\u5316\u5931\u8d25\uff0c\u8bf7\u68c0\u67e5 Supabase \u914d\u7f6e\u540e\u91cd\u8bd5\u3002'
            : 'Failed to initialize auth. Check Supabase configuration and try again.',
      'invalid_email' =>
        isChinese
            ? '\u8bf7\u8f93\u5165\u6709\u6548\u7684\u90ae\u7bb1\u5730\u5740\u3002'
            : 'Enter a valid email address.',
      'otp_send_failed' =>
        isChinese
            ? '\u9a8c\u8bc1\u7801\u53d1\u9001\u5931\u8d25\uff0c\u8bf7\u7a0d\u540e\u91cd\u8bd5\u3002'
            : 'Failed to send the verification code. Please try again later.',
      'missing_pending_email' =>
        isChinese
            ? '\u8bf7\u5148\u8f93\u5165\u90ae\u7bb1\u5e76\u53d1\u9001\u9a8c\u8bc1\u7801\u3002'
            : 'Enter your email and request a code first.',
      'invalid_token_length' =>
        isChinese
            ? '\u8bf7\u8f93\u5165 6 \u4f4d\u9a8c\u8bc1\u7801\u3002'
            : 'Enter the 6-digit verification code.',
      'otp_verify_failed' =>
        isChinese
            ? '\u9a8c\u8bc1\u7801\u6821\u9a8c\u5931\u8d25\uff0c\u8bf7\u786e\u8ba4\u540e\u91cd\u8bd5\u3002'
            : 'Verification failed. Check the code and try again.',
      _ =>
        isChinese
            ? '\u767b\u5f55\u8fc7\u7a0b\u4e2d\u53d1\u751f\u5f02\u5e38\uff0c\u8bf7\u91cd\u8bd5\u3002'
            : 'Something went wrong during sign-in. Please try again.',
    };
  }
}

class _AuthBanner extends StatelessWidget {
  const _AuthBanner({
    required this.message,
    required this.retryLabel,
    this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onErrorContainer,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(retryLabel),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmailStep extends StatelessWidget {
  const _EmailStep({
    required this.emailController,
    required this.busy,
    required this.isChinese,
    required this.onEmailChanged,
    required this.onSubmit,
  });

  final TextEditingController emailController;
  final bool busy;
  final bool isChinese;
  final ValueChanged<String> onEmailChanged;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: const ValueKey('auth-email-field'),
          controller: emailController,
          enabled: !busy,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.email],
          decoration: InputDecoration(
            labelText: isChinese ? '\u90ae\u7bb1' : 'Email',
            hintText: isChinese
                ? '\u8f93\u5165\u63a5\u6536\u9a8c\u8bc1\u7801\u7684\u90ae\u7bb1'
                : 'Enter the email that should receive the code',
          ),
          onChanged: onEmailChanged,
          onSubmitted: (_) => onSubmit(),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: const ValueKey('auth-send-code-button'),
            onPressed: busy ? null : onSubmit,
            child: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    isChinese
                        ? '\u53d1\u9001 6 \u4f4d\u9a8c\u8bc1\u7801'
                        : 'Send 6-digit code',
                  ),
          ),
        ),
      ],
    );
  }
}

class _OtpStep extends StatelessWidget {
  const _OtpStep({
    required this.pendingEmail,
    required this.codeController,
    required this.busy,
    required this.isChinese,
    required this.onCodeChanged,
    required this.onBack,
    required this.onVerify,
  });

  final String pendingEmail;
  final TextEditingController codeController;
  final bool busy;
  final bool isChinese;
  final ValueChanged<String> onCodeChanged;
  final VoidCallback onBack;
  final Future<void> Function() onVerify;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isChinese
              ? '\u9a8c\u8bc1\u7801\u5df2\u53d1\u9001\u81f3 $pendingEmail'
              : 'A code has been sent to $pendingEmail',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          isChinese
              ? '\u8bf7\u5728 App \u5185\u8f93\u5165 6 \u4f4d\u9a8c\u8bc1\u7801\u5b8c\u6210\u767b\u5f55\u3002'
              : 'Enter the 6-digit code here to complete sign-in.',
        ),
        const SizedBox(height: 16),
        TextField(
          key: const ValueKey('auth-otp-field'),
          controller: codeController,
          enabled: !busy,
          autofocus: true,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          decoration: InputDecoration(
            labelText: isChinese ? '\u9a8c\u8bc1\u7801' : 'Verification code',
            hintText: isChinese
                ? '\u8f93\u5165 6 \u4f4d\u6570\u5b57'
                : 'Enter 6 digits',
          ),
          onChanged: onCodeChanged,
          onSubmitted: (_) => onVerify(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: busy ? null : onBack,
                child: Text(
                  isChinese ? '\u66f4\u6362\u90ae\u7bb1' : 'Change email',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                key: const ValueKey('auth-verify-code-button'),
                onPressed: busy ? null : onVerify,
                child: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        isChinese
                            ? '\u9a8c\u8bc1\u5e76\u767b\u5f55'
                            : 'Verify and sign in',
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

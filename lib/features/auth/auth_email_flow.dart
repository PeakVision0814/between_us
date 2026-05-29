import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_controller.dart';
import '../../app/app_strings.dart';

class AuthEmailFlowScaffold extends StatelessWidget {
  const AuthEmailFlowScaffold({
    super.key,
    required this.mode,
    required this.emailController,
    required this.codeController,
    required this.onPrimarySubmit,
    required this.onVerifyCode,
    required this.onSwitchMode,
  });

  final AuthEmailFlowMode mode;
  final TextEditingController emailController;
  final TextEditingController codeController;
  final Future<void> Function() onPrimarySubmit;
  final Future<void> Function() onVerifyCode;
  final VoidCallback onSwitchMode;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isOtpStep = controller.authStatus == AppAuthStatus.otpSent;
    final isBootstrapping = controller.authStatus == AppAuthStatus.initializing;
    final errorCode = controller.authErrorCode;

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
                          mode == AuthEmailFlowMode.signIn
                              ? Icons.lock_open_rounded
                              : Icons.person_add_alt_1_rounded,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        mode == AuthEmailFlowMode.signIn
                            ? strings.authSignInTitle
                            : strings.authRegisterTitle,
                        key: ValueKey(
                          mode == AuthEmailFlowMode.signIn
                              ? 'auth-login-title'
                              : 'auth-register-title',
                        ),
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        mode == AuthEmailFlowMode.signIn
                            ? strings.authSignInSubtitle
                            : strings.authRegisterSubtitle,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      if (isBootstrapping) ...[
                        const Center(child: CircularProgressIndicator()),
                        const SizedBox(height: 16),
                        Center(child: Text(strings.authCheckingSessionLabel)),
                      ] else ...[
                        if (errorCode != null)
                          _AuthBanner(
                            message: _errorText(strings, errorCode),
                            retryLabel: strings.authRetryLabel,
                            onRetry: controller.supabaseReady
                                ? null
                                : () => controller.bootstrap(),
                            actionLabel: _errorActionLabel(strings, errorCode),
                            onAction: _errorAction(strings, errorCode),
                          ),
                        if (errorCode != null) const SizedBox(height: 16),
                        if (isOtpStep)
                          _OtpStep(
                            pendingEmail:
                                controller.pendingEmail ??
                                emailController.text.trim(),
                            codeController: codeController,
                            busy: controller.authBusy,
                            strings: strings,
                            onCodeChanged: (_) => controller.clearAuthError(),
                            onBack: () {
                              codeController.clear();
                              controller.returnToEmailEntry();
                            },
                            onVerify: onVerifyCode,
                            ctaLabel: mode == AuthEmailFlowMode.signIn
                                ? strings.authVerifyAndSignInLabel
                                : strings.authVerifyAndCreateAccountLabel,
                          )
                        else
                          _EmailStep(
                            emailController: emailController,
                            busy:
                                controller.authBusy ||
                                !controller.supabaseReady,
                            strings: strings,
                            onEmailChanged: (_) => controller.clearAuthError(),
                            onSubmit: onPrimarySubmit,
                            submitLabel: mode == AuthEmailFlowMode.signIn
                                ? strings.authSendSignInCodeLabel
                                : strings.authSendRegisterCodeLabel,
                          ),
                        if (!isOtpStep) ...[
                          const SizedBox(height: 16),
                          Center(
                            child: TextButton(
                              key: ValueKey(
                                mode == AuthEmailFlowMode.signIn
                                    ? 'auth-go-register-button'
                                    : 'auth-go-login-button',
                              ),
                              onPressed: onSwitchMode,
                              child: Text(
                                mode == AuthEmailFlowMode.signIn
                                    ? strings.authGoRegisterLabel
                                    : strings.authGoSignInLabel,
                              ),
                            ),
                          ),
                        ],
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

  String _errorText(AppStrings strings, String errorCode) {
    return switch (errorCode) {
      'initialize_failed' => strings.authInitializeFailedMessage,
      'invalid_email' => strings.authInvalidEmailMessage,
      'otp_send_failed' => strings.authOtpSendFailedMessage,
      'signup_send_failed' => strings.authSignUpSendFailedMessage,
      'user_not_registered' => strings.authUserNotRegisteredMessage,
      'user_already_registered' => strings.authUserAlreadyRegisteredMessage,
      'missing_pending_email' => strings.authMissingPendingEmailMessage,
      'invalid_token_length' => strings.authInvalidTokenLengthMessage,
      'otp_verify_failed' => strings.authOtpVerifyFailedMessage,
      _ => strings.authUnknownErrorMessage,
    };
  }

  String? _errorActionLabel(AppStrings strings, String errorCode) {
    return switch (errorCode) {
      'user_not_registered' => strings.authGoRegisterLabel,
      'user_already_registered' => strings.authGoSignInLabel,
      _ => null,
    };
  }

  VoidCallback? _errorAction(AppStrings strings, String errorCode) {
    return switch (errorCode) {
      'user_not_registered' || 'user_already_registered' => onSwitchMode,
      _ => null,
    };
  }
}

enum AuthEmailFlowMode { signIn, register }

class _AuthBanner extends StatelessWidget {
  const _AuthBanner({
    required this.message,
    required this.retryLabel,
    this.onRetry,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String retryLabel;
  final VoidCallback? onRetry;
  final String? actionLabel;
  final VoidCallback? onAction;

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
          if (onRetry != null || onAction != null) const SizedBox(height: 12),
          if (onRetry != null)
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(retryLabel),
            ),
          if (onAction != null && actionLabel != null) ...[
            if (onRetry != null) const SizedBox(height: 8),
            FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
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
    required this.strings,
    required this.onEmailChanged,
    required this.onSubmit,
    required this.submitLabel,
  });

  final TextEditingController emailController;
  final bool busy;
  final AppStrings strings;
  final ValueChanged<String> onEmailChanged;
  final Future<void> Function() onSubmit;
  final String submitLabel;

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
            labelText: strings.authEmailLabel,
            hintText: strings.authEmailHint,
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
                : Text(submitLabel),
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
    required this.strings,
    required this.onCodeChanged,
    required this.onBack,
    required this.onVerify,
    required this.ctaLabel,
  });

  final String pendingEmail;
  final TextEditingController codeController;
  final bool busy;
  final AppStrings strings;
  final ValueChanged<String> onCodeChanged;
  final VoidCallback onBack;
  final Future<void> Function() onVerify;
  final String ctaLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.authCodeSentTo(pendingEmail),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(strings.authOtpStepSubtitle),
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
            labelText: strings.authOtpLabel,
            hintText: strings.authOtpHint,
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
                child: Text(strings.authChangeEmailLabel),
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
                    : Text(ctaLabel),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

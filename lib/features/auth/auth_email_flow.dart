import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_controller.dart';
import '../../app/app_strings.dart';
import 'auth_page_visuals.dart';

class AuthEmailFlowScaffold extends StatelessWidget {
  const AuthEmailFlowScaffold({
    super.key,
    required this.mode,
    required this.emailController,
    required this.phoneController,
    required this.codeController,
    required this.onPrimarySubmit,
    required this.onPhoneSubmit,
    required this.onVerifyCode,
    required this.onVerifyPhoneCode,
    required this.onSwitchMode,
  });

  final AuthEmailFlowMode mode;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController codeController;
  final Future<void> Function() onPrimarySubmit;
  final Future<void> Function() onPhoneSubmit;
  final Future<void> Function() onVerifyCode;
  final Future<void> Function() onVerifyPhoneCode;
  final VoidCallback onSwitchMode;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEmailOtpStep = controller.authStatus == AppAuthStatus.otpSent;
    final isPhoneOtpStep = controller.authStatus == AppAuthStatus.phoneOtpSent;
    final isOtpStep = isEmailOtpStep || isPhoneOtpStep;
    final isBootstrapping = controller.authStatus == AppAuthStatus.initializing;
    final errorCode = controller.authErrorCode;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuthPageBackground(
        child: SafeArea(
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
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Icon(
                            mode == AuthEmailFlowMode.signIn
                                ? Icons.lock_open_rounded
                                : Icons.person_add_alt_1_rounded,
                            color: colorScheme.onPrimaryContainer,
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
                              actionLabel: _errorActionLabel(
                                strings,
                                errorCode,
                              ),
                              onAction: _errorAction(strings, errorCode),
                            ),
                          if (errorCode != null) const SizedBox(height: 16),
                          if (isOtpStep)
                            _OtpStep(
                              destination: isPhoneOtpStep
                                  ? controller.pendingPhone ??
                                        phoneController.text.trim()
                                  : controller.pendingEmail ??
                                        emailController.text.trim(),
                              codeController: codeController,
                              busy: controller.authBusy,
                              strings: strings,
                              channel: isPhoneOtpStep
                                  ? AuthOtpChannel.phone
                                  : AuthOtpChannel.email,
                              onCodeChanged: (_) => controller.clearAuthError(),
                              onBack: () {
                                codeController.clear();
                                if (isPhoneOtpStep) {
                                  controller.returnToPhoneEntry();
                                } else {
                                  controller.returnToEmailEntry();
                                }
                              },
                              onVerify: isPhoneOtpStep
                                  ? onVerifyPhoneCode
                                  : onVerifyCode,
                              ctaLabel: mode == AuthEmailFlowMode.signIn
                                  ? strings.authVerifyAndSignInLabel
                                  : strings.authVerifyAndCreateAccountLabel,
                            )
                          else
                            _AuthEntryStep(
                              mode: mode,
                              emailController: emailController,
                              phoneController: phoneController,
                              busy:
                                  controller.authBusy ||
                                  !controller.supabaseReady,
                              strings: strings,
                              onChanged: (_) => controller.clearAuthError(),
                              onEmailSubmit: onPrimarySubmit,
                              onPhoneSubmit: onPhoneSubmit,
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
      ),
    );
  }

  String _errorText(AppStrings strings, String errorCode) {
    return switch (errorCode) {
      'initialize_failed' => strings.authInitializeFailedMessage,
      'invalid_email' => strings.authInvalidEmailMessage,
      'invalid_phone' => strings.authInvalidPhoneMessage,
      'otp_send_failed' => strings.authOtpSendFailedMessage,
      'signup_send_failed' => strings.authSignUpSendFailedMessage,
      'phone_otp_send_failed' => strings.authPhoneOtpSendFailedMessage,
      'phone_signup_send_failed' => strings.authPhoneSignUpSendFailedMessage,
      'user_not_registered' => strings.authUserNotRegisteredMessage,
      'user_already_registered' => strings.authUserAlreadyRegisteredMessage,
      'phone_user_not_registered' => strings.authPhoneUserNotRegisteredMessage,
      'phone_user_already_registered' =>
        strings.authPhoneUserAlreadyRegisteredMessage,
      'missing_pending_email' => strings.authMissingPendingEmailMessage,
      'missing_pending_phone' => strings.authMissingPendingPhoneMessage,
      'invalid_token_length' => strings.authInvalidTokenLengthMessage,
      'otp_verify_failed' => strings.authOtpVerifyFailedMessage,
      _ => strings.authUnknownErrorMessage,
    };
  }

  String? _errorActionLabel(AppStrings strings, String errorCode) {
    return switch (errorCode) {
      'user_not_registered' => strings.authGoRegisterLabel,
      'user_already_registered' => strings.authGoSignInLabel,
      'phone_user_not_registered' => strings.authGoRegisterLabel,
      'phone_user_already_registered' => strings.authGoSignInLabel,
      _ => null,
    };
  }

  VoidCallback? _errorAction(AppStrings strings, String errorCode) {
    return switch (errorCode) {
      'user_not_registered' ||
      'user_already_registered' ||
      'phone_user_not_registered' ||
      'phone_user_already_registered' => onSwitchMode,
      _ => null,
    };
  }
}

enum AuthEmailFlowMode { signIn, register }

enum AuthOtpChannel { email, phone }

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

class _AuthEntryStep extends StatefulWidget {
  const _AuthEntryStep({
    required this.mode,
    required this.emailController,
    required this.phoneController,
    required this.busy,
    required this.strings,
    required this.onChanged,
    required this.onEmailSubmit,
    required this.onPhoneSubmit,
  });

  final AuthEmailFlowMode mode;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final bool busy;
  final AppStrings strings;
  final ValueChanged<String> onChanged;
  final Future<void> Function() onEmailSubmit;
  final Future<void> Function() onPhoneSubmit;

  @override
  State<_AuthEntryStep> createState() => _AuthEntryStepState();
}

class _AuthEntryStepState extends State<_AuthEntryStep> {
  AuthOtpChannel _channel = AuthOtpChannel.email;

  @override
  Widget build(BuildContext context) {
    final isEmail = _channel == AuthOtpChannel.email;
    final submitLabel = switch ((widget.mode, _channel)) {
      (AuthEmailFlowMode.signIn, AuthOtpChannel.email) =>
        widget.strings.authSendSignInCodeLabel,
      (AuthEmailFlowMode.register, AuthOtpChannel.email) =>
        widget.strings.authSendRegisterCodeLabel,
      (AuthEmailFlowMode.signIn, AuthOtpChannel.phone) =>
        widget.strings.authSendPhoneSignInCodeLabel,
      (AuthEmailFlowMode.register, AuthOtpChannel.phone) =>
        widget.strings.authSendPhoneRegisterCodeLabel,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<AuthOtpChannel>(
          key: ValueKey(
            widget.mode == AuthEmailFlowMode.signIn
                ? 'auth-login-method-segment'
                : 'auth-register-method-segment',
          ),
          segments: [
            ButtonSegment<AuthOtpChannel>(
              value: AuthOtpChannel.email,
              icon: const Icon(Icons.alternate_email_rounded),
              label: Text(widget.strings.authEmailMethodLabel),
            ),
            ButtonSegment<AuthOtpChannel>(
              value: AuthOtpChannel.phone,
              icon: const Icon(Icons.phone_iphone_rounded),
              label: Text(widget.strings.authPhoneMethodLabel),
            ),
          ],
          selected: {_channel},
          onSelectionChanged: widget.busy
              ? null
              : (selection) {
                  setState(() {
                    _channel = selection.single;
                  });
                  widget.onChanged('');
                },
        ),
        const SizedBox(height: 16),
        TextField(
          key: ValueKey(isEmail ? 'auth-email-field' : 'auth-phone-field'),
          controller: isEmail ? widget.emailController : widget.phoneController,
          enabled: !widget.busy,
          keyboardType: isEmail
              ? TextInputType.emailAddress
              : TextInputType.phone,
          textInputAction: TextInputAction.done,
          autofillHints: isEmail
              ? const [AutofillHints.email]
              : const [AutofillHints.telephoneNumber],
          decoration: InputDecoration(
            labelText: isEmail
                ? widget.strings.authEmailLabel
                : widget.strings.authPhoneLabel,
            hintText: isEmail
                ? widget.strings.authEmailHint
                : widget.strings.authPhoneHint,
          ),
          onChanged: widget.onChanged,
          onSubmitted: (_) =>
              isEmail ? widget.onEmailSubmit() : widget.onPhoneSubmit(),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: ValueKey(
              isEmail ? 'auth-send-code-button' : 'auth-send-phone-code-button',
            ),
            onPressed: widget.busy
                ? null
                : isEmail
                ? widget.onEmailSubmit
                : widget.onPhoneSubmit,
            child: widget.busy
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
    required this.destination,
    required this.codeController,
    required this.busy,
    required this.strings,
    required this.channel,
    required this.onCodeChanged,
    required this.onBack,
    required this.onVerify,
    required this.ctaLabel,
  });

  final String destination;
  final TextEditingController codeController;
  final bool busy;
  final AppStrings strings;
  final AuthOtpChannel channel;
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
          channel == AuthOtpChannel.phone
              ? strings.authPhoneCodeSentTo(destination)
              : strings.authCodeSentTo(destination),
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
                child: Text(
                  channel == AuthOtpChannel.phone
                      ? strings.authChangePhoneLabel
                      : strings.authChangeEmailLabel,
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
                    : Text(ctaLabel),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

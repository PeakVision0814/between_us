import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_controller.dart';
import '../../app/app_strings.dart';
import 'auth_page_visuals.dart';
import 'email_register_screen.dart';

enum _AuthAccountType { email, phone }

enum _LoginMethod { password, otp }

class EmailOtpSignInScreen extends StatefulWidget {
  const EmailOtpSignInScreen({super.key});

  @override
  State<EmailOtpSignInScreen> createState() => _EmailOtpSignInScreenState();
}

class _EmailOtpSignInScreenState extends State<EmailOtpSignInScreen> {
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  _AuthAccountType _accountType = _AuthAccountType.email;
  _LoginMethod _loginMethod = _LoginMethod.password;
  bool _obscurePassword = true;
  bool _initializedFromController = false;
  int _countdown = 0;
  Timer? _countdownTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initializedFromController) {
      return;
    }
    final controller = AppScope.read(context);
    final isPhoneOtp = controller.authStatus == AppAuthStatus.phoneOtpSent;
    final isEmailOtp = controller.authStatus == AppAuthStatus.otpSent;
    if (isPhoneOtp || isEmailOtp) {
      _loginMethod = _LoginMethod.otp;
      _accountType = isPhoneOtp ? _AuthAccountType.phone : _AuthAccountType.email;
    }
    _initializedFromController = true;
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _accountController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final controller = AppScope.read(context);
    controller.clearAuthError();
    final success = switch (_accountType) {
      _AuthAccountType.email => await controller.sendEmailOtp(
        _accountController.text,
      ),
      _AuthAccountType.phone => await controller.sendPhoneOtpForSignIn(
        _accountController.text,
      ),
    };
    if (!mounted || !success) {
      return;
    }

    _codeController.clear();
    _startCountdown();
    final strings = AppStrings.of(context);
    final toast = _accountType == _AuthAccountType.email
        ? strings.authOtpSentToast
        : strings.authPhoneOtpSentToast;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(toast)));
  }

  Future<void> _submit() async {
    final controller = AppScope.read(context);
    controller.clearAuthError();

    if (_loginMethod == _LoginMethod.password) {
      if (_accountType == _AuthAccountType.email) {
        await controller.signInWithEmailPassword(
          _accountController.text,
          _passwordController.text,
        );
      } else {
        await controller.signInWithPhonePassword(
          _accountController.text,
          _passwordController.text,
        );
      }
      return;
    }

    if (_accountType == _AuthAccountType.email) {
      await controller.verifyEmailOtp(_codeController.text);
    } else {
      await controller.verifyPhoneOtp(_codeController.text);
    }
  }

  void _openRegister() {
    final controller = AppScope.read(context);
    controller.clearPendingAuthState();
    controller.clearAuthError();
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const EmailRegisterScreen()),
    );
  }

  void _toggleAccountType() {
    final controller = AppScope.read(context);
    controller.clearPendingAuthState();
    controller.clearAuthError();
    setState(() {
      _accountType = _accountType == _AuthAccountType.email
          ? _AuthAccountType.phone
          : _AuthAccountType.email;
      _accountController.clear();
      _codeController.clear();
      _countdown = 0;
    });
    _countdownTimer?.cancel();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _countdown = 60;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _countdown <= 1) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _countdown = 0;
          });
        }
        return;
      }
      setState(() {
        _countdown -= 1;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final errorText = _errorText(strings, controller.authErrorCode);
    final isPhone = _accountType == _AuthAccountType.phone;
    final showPassword = _loginMethod == _LoginMethod.password;

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
                            Icons.lock_open_rounded,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          strings.authWelcomeBackTitle,
                          key: const ValueKey('auth-login-title'),
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          strings.authWelcomeBackSubtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (errorText != null) ...[
                          const SizedBox(height: 20),
                          _AuthErrorBanner(message: errorText),
                        ],
                        const SizedBox(height: 20),
                        _AccountField(
                          controller: _accountController,
                          isPhone: isPhone,
                          enabled: !controller.authBusy,
                          onToggle: _toggleAccountType,
                          onChanged: (_) => controller.clearAuthError(),
                          onSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 16),
                        SegmentedButton<_LoginMethod>(
                          key: const ValueKey('auth-login-method-segment'),
                          segments: [
                            ButtonSegment<_LoginMethod>(
                              value: _LoginMethod.password,
                              label: Text(strings.authPasswordLoginTabLabel),
                            ),
                            ButtonSegment<_LoginMethod>(
                              value: _LoginMethod.otp,
                              label: Text(strings.authOtpLoginTabLabel),
                            ),
                          ],
                          selected: {_loginMethod},
                          onSelectionChanged: controller.authBusy
                              ? null
                              : (selection) {
                                  final selected = selection.single;
                                  controller.clearAuthError();
                                  controller.clearPendingAuthState();
                                  setState(() {
                                    _loginMethod = selected;
                                    _codeController.clear();
                                  });
                                },
                        ),
                        const SizedBox(height: 16),
                        if (showPassword)
                          TextField(
                            key: const ValueKey('auth-password-field'),
                            controller: _passwordController,
                            enabled: !controller.authBusy,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            decoration: InputDecoration(
                              labelText: strings.authPasswordLabel,
                              hintText: strings.authPasswordHint,
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                            onChanged: (_) => controller.clearAuthError(),
                            onSubmitted: (_) => _submit(),
                          )
                        else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextField(
                                  key: const ValueKey('auth-otp-field'),
                                  controller: _codeController,
                                  enabled: !controller.authBusy,
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [
                                    AutofillHints.oneTimeCode,
                                  ],
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(6),
                                  ],
                                  decoration: InputDecoration(
                                    labelText: strings.authOtpLabel,
                                    hintText: strings.authOtpHint,
                                  ),
                                  onChanged: (_) => controller.clearAuthError(),
                                  onSubmitted: (_) => _submit(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                height: 56,
                                child: FilledButton.tonal(
                                  key: ValueKey(
                                    isPhone
                                        ? 'auth-send-phone-code-button'
                                        : 'auth-send-code-button',
                                  ),
                                  onPressed:
                                      controller.authBusy || _countdown > 0
                                      ? null
                                      : _sendCode,
                                  child: Text(
                                    _countdown > 0
                                        ? strings.authCountdownLabel(
                                            _countdown,
                                          )
                                        : strings.authSendCodeLabel,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            key: const ValueKey('auth-login-submit-button'),
                            onPressed: controller.authBusy ? null : _submit,
                            child: controller.authBusy
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(strings.authSignInTitle),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton(
                            key: const ValueKey('auth-go-register-button'),
                            onPressed: controller.authBusy ? null : _openRegister,
                            child: Text(strings.authGoRegisterLabel),
                          ),
                        ),
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

  String? _errorText(AppStrings strings, String? errorCode) {
    return switch (errorCode) {
      null => null,
      'initialize_failed' => strings.authInitializeFailedMessage,
      'invalid_email' => strings.authInvalidEmailMessage,
      'invalid_phone' => strings.authInvalidPhoneMessage,
      'otp_send_failed' => strings.authOtpSendFailedMessage,
      'phone_otp_send_failed' => strings.authPhoneOtpSendFailedMessage,
      'user_not_registered' => strings.authUserNotRegisteredMessage,
      'phone_user_not_registered' => strings.authPhoneUserNotRegisteredMessage,
      'missing_pending_email' => strings.authMissingPendingEmailMessage,
      'missing_pending_phone' => strings.authMissingPendingPhoneMessage,
      'invalid_token_length' => strings.authInvalidTokenLengthMessage,
      'otp_verify_failed' => strings.authOtpVerifyFailedMessage,
      'invalid_credentials' => strings.authPasswordSignInFailedMessage,
      _ => strings.authUnknownErrorMessage,
    };
  }
}

class _AccountField extends StatelessWidget {
  const _AccountField({
    required this.controller,
    required this.isPhone,
    required this.enabled,
    required this.onToggle,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool isPhone;
  final bool enabled;
  final VoidCallback onToggle;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return TextField(
      key: ValueKey(isPhone ? 'auth-phone-field' : 'auth-email-field'),
      controller: controller,
      enabled: enabled,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      inputFormatters: isPhone
          ? [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ]
          : null,
      autofillHints: isPhone
          ? const [AutofillHints.telephoneNumber]
          : const [AutofillHints.email],
      decoration: InputDecoration(
        hintText: isPhone ? strings.authEnterPhoneHint : strings.authEnterEmailHint,
        prefixIcon: IconButton(
          tooltip: isPhone
              ? strings.authSwitchToEmailTooltip
              : strings.authSwitchToPhoneTooltip,
          onPressed: enabled ? onToggle : null,
          icon: Icon(
            isPhone
                ? Icons.phone_iphone_rounded
                : Icons.alternate_email_rounded,
          ),
        ),
        prefixText: isPhone ? '+86 ' : null,
      ),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    );
  }
}

class _AuthErrorBanner extends StatelessWidget {
  const _AuthErrorBanner({required this.message});

  final String message;

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
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: colorScheme.onErrorContainer),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_controller.dart';
import '../../app/app_strings.dart';
import 'auth_page_visuals.dart';

enum _RegisterAccountType { email, phone }

class EmailRegisterScreen extends StatefulWidget {
  const EmailRegisterScreen({super.key, this.finalizeOnly = false});

  final bool finalizeOnly;

  @override
  State<EmailRegisterScreen> createState() => _EmailRegisterScreenState();
}

class _EmailRegisterScreenState extends State<EmailRegisterScreen> {
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  _RegisterAccountType _accountType = _RegisterAccountType.email;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreed = false;
  String? _selectedGender;
  String? _localError;
  bool _initializedProfile = false;
  int _countdown = 0;
  Timer? _countdownTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initializedProfile) {
      return;
    }
    final controller = AppScope.read(context);
    if (controller.pendingPhone != null ||
        controller.authStatus == AppAuthStatus.phoneOtpSent) {
      _accountType = _RegisterAccountType.phone;
    }
    final existingDisplayName = controller.displayName?.trim();
    _displayNameController.text =
        existingDisplayName == null ||
            existingDisplayName.isEmpty ||
            existingDisplayName == AppController.defaultDisplayNamePlaceholder
        ? ''
        : existingDisplayName;
    _selectedGender = switch (controller.gender) {
      AppController.genderMale => AppController.genderMale,
      AppController.genderFemale => AppController.genderFemale,
      _ => null,
    };
    _initializedProfile = true;
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _accountController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final controller = AppScope.read(context);
    controller.clearAuthError();
    setState(() {
      _localError = null;
    });
    final success = switch (_accountType) {
      _RegisterAccountType.email => await controller.signUpWithEmail(
        _accountController.text,
      ),
      _RegisterAccountType.phone => await controller.sendPhoneOtpForSignUp(
        _accountController.text,
      ),
    };
    if (!mounted || !success) {
      return;
    }

    _codeController.clear();
    _startCountdown();
    final strings = AppStrings.of(context);
    final toast = _accountType == _RegisterAccountType.email
        ? strings.authRegisterOtpSentToast
        : strings.authPhoneRegisterOtpSentToast;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(toast)));
  }

  Future<void> _verifyCode() async {
    final controller = AppScope.read(context);
    controller.clearAuthError();
    setState(() {
      _localError = null;
    });
    final success = switch (_accountType) {
      _RegisterAccountType.email => await controller.verifyEmailOtp(
        _codeController.text,
      ),
      _RegisterAccountType.phone => await controller.verifyPhoneOtp(
        _codeController.text,
      ),
    };
    if (!mounted || !success || !controller.isAuthenticated) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.of(context).authCodeVerifiedLabel)),
    );
  }

  Future<void> _register() async {
    final controller = AppScope.read(context);
    final strings = AppStrings.of(context);
    controller.clearAuthError();

    if (!controller.isAuthenticated) {
      setState(() {
        _localError = strings.authCodeVerificationRequiredMessage;
      });
      return;
    }
    if (!AppController.isValidPassword(_passwordController.text)) {
      setState(() {
        _localError = strings.authInvalidPasswordMessage;
      });
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _localError = strings.authPasswordMismatchMessage;
      });
      return;
    }

    final normalizedName = _displayNameController.text.trim();
    if (normalizedName.isEmpty) {
      setState(() {
        _localError = strings.profileDisplayNameEmptyError;
      });
      return;
    }
    if (normalizedName.characters.length > 40) {
      setState(() {
        _localError = strings.profileDisplayNameTooLongError;
      });
      return;
    }
    if (_selectedGender == null) {
      setState(() {
        _localError = strings.profileGenderRequiredError;
      });
      return;
    }
    if (!_agreed) {
      setState(() {
        _localError = strings.authAgreementRequiredMessage;
      });
      return;
    }

    setState(() {
      _localError = null;
    });

    final success = await controller.completeVerifiedRegistration(
      password: _passwordController.text,
      displayName: normalizedName,
      gender: _selectedGender!,
    );
    if (!mounted || !success) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.authRegisterSuccessMessage)),
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _backToSignIn() {
    final controller = AppScope.read(context);
    controller.clearPendingAuthState();
    controller.clearAuthError();
    Navigator.of(context).pop();
  }

  void _toggleAccountType() {
    final controller = AppScope.read(context);
    controller.clearPendingAuthState();
    controller.clearAuthError();
    setState(() {
      _accountType = _accountType == _RegisterAccountType.email
          ? _RegisterAccountType.phone
          : _RegisterAccountType.email;
      _accountController.clear();
      _codeController.clear();
      _localError = null;
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
    final isVerificationComplete = controller.isAuthenticated;
    final showAccountSection = !isVerificationComplete && !widget.finalizeOnly;
    final errorText =
        _localError ?? _errorText(strings, controller.authErrorCode);

    return PopScope(
      canPop: !isVerificationComplete,
      child: Scaffold(
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
                              Icons.person_add_alt_1_rounded,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            strings.authCreateAccountHeading,
                            key: const ValueKey('auth-register-title'),
                            style: theme.textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            strings.authCreateAccountSubtitle,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (errorText != null) ...[
                            const SizedBox(height: 20),
                            _AuthErrorBanner(message: errorText),
                          ],
                          if (showAccountSection) ...[
                            const SizedBox(height: 20),
                            _SectionLabel(text: strings.authEmailMethodLabel),
                            const SizedBox(height: 10),
                            _AccountField(
                              controller: _accountController,
                              isPhone:
                                  _accountType == _RegisterAccountType.phone,
                              enabled: !controller.authBusy,
                              onToggle: _toggleAccountType,
                              onChanged: (_) {
                                controller.clearAuthError();
                                setState(() {
                                  _localError = null;
                                });
                              },
                              onSubmitted: (_) => _sendCode(),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.tonal(
                                key: ValueKey(
                                  _accountType == _RegisterAccountType.phone
                                      ? 'auth-send-phone-code-button'
                                      : 'auth-send-code-button',
                                ),
                                onPressed:
                                    controller.authBusy || _countdown > 0
                                    ? null
                                    : _sendCode,
                                child: Text(
                                  _countdown > 0
                                      ? strings.authCountdownLabel(_countdown)
                                      : strings.authSendCodeLabel,
                                ),
                              ),
                            ),
                            if (controller.pendingEmail != null ||
                                controller.pendingPhone != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _accountType == _RegisterAccountType.phone
                                    ? strings.authPhoneCodeSentTo(
                                        controller.pendingPhone ??
                                            _accountController.text,
                                      )
                                    : strings.authCodeSentTo(
                                        controller.pendingEmail ??
                                            _accountController.text,
                                      ),
                                key: const ValueKey('auth-pending-target'),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
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
                                    onChanged: (_) {
                                      controller.clearAuthError();
                                      setState(() {
                                        _localError = null;
                                      });
                                    },
                                    onSubmitted: (_) => _verifyCode(),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  height: 56,
                                  child: OutlinedButton(
                                    key: const ValueKey('auth-verify-code-button'),
                                    onPressed: controller.authBusy
                                        ? null
                                        : _verifyCode,
                                    child: Text(strings.authVerifyCodeLabel),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            const SizedBox(height: 20),
                            _VerificationDoneBanner(
                              title: strings.authCodeVerifiedLabel,
                              subtitle: strings.authRegisterCompletionHint,
                            ),
                          ],
                          const SizedBox(height: 20),
                          _SectionLabel(text: strings.authPasswordLabel),
                          const SizedBox(height: 10),
                          TextField(
                            key: const ValueKey('auth-password-field'),
                            controller: _passwordController,
                            enabled: !controller.authBusy,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
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
                            onChanged: (_) {
                              controller.clearAuthError();
                              setState(() {
                                _localError = null;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            key: const ValueKey('auth-confirm-password-field'),
                            controller: _confirmPasswordController,
                            enabled: !controller.authBusy,
                            obscureText: _obscureConfirmPassword,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: strings.authConfirmPasswordLabel,
                              hintText: strings.authConfirmPasswordHint,
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                            onChanged: (_) => setState(() {
                              _localError = null;
                            }),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            strings.authPasswordRequirementHint,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _SectionLabel(text: strings.profileSharedInfoSectionTitle),
                          const SizedBox(height: 10),
                          TextField(
                            key: const ValueKey('auth-register-display-name-field'),
                            controller: _displayNameController,
                            enabled: !controller.authBusy,
                            textInputAction: TextInputAction.next,
                            maxLength: 40,
                            decoration: InputDecoration(
                              labelText: strings.profileDisplayNameLabel,
                              hintText: strings.profileDisplayNameSetupHint,
                            ),
                            onChanged: (_) => setState(() {
                              _localError = null;
                            }),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            strings.profileGenderLabel,
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              ChoiceChip(
                                key: const ValueKey('auth-register-gender-male'),
                                label: Text(strings.profileGenderMaleLabel),
                                selected:
                                    _selectedGender == AppController.genderMale,
                                onSelected: controller.authBusy
                                    ? null
                                    : (selected) {
                                        setState(() {
                                          _selectedGender = selected
                                              ? AppController.genderMale
                                              : null;
                                          _localError = null;
                                        });
                                      },
                              ),
                              ChoiceChip(
                                key: const ValueKey(
                                  'auth-register-gender-female',
                                ),
                                label: Text(strings.profileGenderFemaleLabel),
                                selected:
                                    _selectedGender ==
                                    AppController.genderFemale,
                                onSelected: controller.authBusy
                                    ? null
                                    : (selected) {
                                        setState(() {
                                          _selectedGender = selected
                                              ? AppController.genderFemale
                                              : null;
                                          _localError = null;
                                        });
                                      },
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: _agreed,
                                onChanged: controller.authBusy
                                    ? null
                                    : (value) {
                                        setState(() {
                                          _agreed = value ?? false;
                                          _localError = null;
                                        });
                                      },
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: [
                                      Text(strings.authAgreementPrefix),
                                      TextButton(
                                        onPressed: _showPlaceholderLink,
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          strings.authUserAgreementLabel,
                                        ),
                                      ),
                                      Text(strings.isChinese ? '和' : 'and'),
                                      TextButton(
                                        onPressed: _showPlaceholderLink,
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          strings.authPrivacyPolicyLabel,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              key: const ValueKey('auth-register-submit-button'),
                              onPressed:
                                  controller.authBusy || !_agreed
                                  ? null
                                  : _register,
                              child: controller.authBusy
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(strings.authRegisterButtonLabel),
                            ),
                          ),
                          if (!isVerificationComplete) ...[
                            const SizedBox(height: 12),
                            Center(
                              child: TextButton(
                                key: const ValueKey('auth-go-login-button'),
                                onPressed: controller.authBusy
                                    ? null
                                    : _backToSignIn,
                                child: Text(strings.authGoSignInLabel),
                              ),
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
        ),
      ),
    );
  }

  void _showPlaceholderLink() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.of(context).authLinkUnavailableMessage)),
    );
  }

  String? _errorText(AppStrings strings, String? errorCode) {
    return switch (errorCode) {
      null => null,
      'initialize_failed' => strings.authInitializeFailedMessage,
      'invalid_email' => strings.authInvalidEmailMessage,
      'invalid_phone' => strings.authInvalidPhoneMessage,
      'signup_send_failed' => strings.authSignUpSendFailedMessage,
      'phone_signup_send_failed' => strings.authPhoneSignUpSendFailedMessage,
      'user_already_registered' => strings.authUserAlreadyRegisteredMessage,
      'phone_user_already_registered' =>
        strings.authPhoneUserAlreadyRegisteredMessage,
      'missing_pending_email' => strings.authMissingPendingEmailMessage,
      'missing_pending_phone' => strings.authMissingPendingPhoneMessage,
      'invalid_token_length' => strings.authInvalidTokenLengthMessage,
      'otp_verify_failed' => strings.authOtpVerifyFailedMessage,
      'invalid_password' => strings.authInvalidPasswordMessage,
      'invalid_display_name' => strings.profileSetupInvalidNameError,
      'invalid_gender' => strings.profileGenderRequiredError,
      'missing_verified_account' => strings.authMissingVerifiedAccountMessage,
      'missing_user' => strings.profileSetupMissingUserError,
      'session_expired' => strings.profileSessionExpiredMessage,
      'password_setup_failed' => strings.authPasswordSetupFailedMessage,
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
      textInputAction: TextInputAction.done,
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleSmall);
  }
}

class _VerificationDoneBanner extends StatelessWidget {
  const _VerificationDoneBanner({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

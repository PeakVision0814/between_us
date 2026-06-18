import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_controller.dart';
import '../../app/app_strings.dart';
import '../../app/app_theme.dart';
import '../../shared/widgets/page_visual_language.dart';

enum _BindingKind { phone, email, recoveryEmail }

typedef SpaceStatusRouteBuilder =
    Widget Function(AppController controller, String? partnerName);

class AccountSecurityScreen extends StatefulWidget {
  const AccountSecurityScreen({
    super.key,
    required this.spaceStatusRouteBuilder,
  });

  final SpaceStatusRouteBuilder spaceStatusRouteBuilder;

  @override
  State<AccountSecurityScreen> createState() => _AccountSecurityScreenState();
}

class _AccountSecurityScreenState extends State<AccountSecurityScreen> {
  _BindingKind? _activeBinding;
  bool _showPasswordPanel = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _passwordError;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _recoveryEmailController =
      TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _recoveryEmailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _requestBinding(AppController controller) async {
    final kind = _activeBinding;
    if (kind == null) return;

    final recoveryEmailTarget = controller.recoveryEmailPending?.trim();
    final success = switch (kind) {
      _BindingKind.phone => await controller.requestPhoneBindingOtp(
        _phoneController.text,
      ),
      _BindingKind.email => await controller.requestEmailBindingOtp(
        _emailController.text,
      ),
      _BindingKind.recoveryEmail => await controller.requestRecoveryEmailChange(
        recoveryEmailTarget != null && recoveryEmailTarget.isNotEmpty
            ? recoveryEmailTarget
            : _recoveryEmailController.text,
      ),
    };
    if (success && mounted) {
      _codeController.clear();
    }
  }

  Future<void> _verifyBinding(AppController controller) async {
    final kind = _activeBinding;
    if (kind == null) return;

    final success = switch (kind) {
      _BindingKind.phone => await controller.verifyPhoneBindingOtp(
        _codeController.text,
      ),
      _BindingKind.email => await controller.verifyEmailBindingOtp(
        _codeController.text,
      ),
      _BindingKind.recoveryEmail => await controller.verifyRecoveryEmailChange(
        _codeController.text,
      ),
    };
    if (success && mounted) {
      setState(() {
        _activeBinding = null;
        _phoneController.clear();
        _emailController.clear();
        _recoveryEmailController.clear();
        _codeController.clear();
      });
    }
  }

  void _startBinding(AppController controller, _BindingKind kind) {
    controller.clearPendingBindingState();
    if (kind == _BindingKind.recoveryEmail) {
      controller.clearRecoveryEmailPendingForChange();
    }
    setState(() {
      _activeBinding = kind;
      _showPasswordPanel = false;
      _codeController.clear();
    });
  }

  void _continueRecoveryEmailVerification(AppController controller) {
    controller.clearPendingBindingState();
    setState(() {
      _activeBinding = _BindingKind.recoveryEmail;
      _showPasswordPanel = false;
      _codeController.clear();
    });
  }

  void _changeRecoveryEmail(AppController controller) {
    controller.clearRecoveryEmailPendingForChange();
    setState(() {
      _activeBinding = _BindingKind.recoveryEmail;
      _showPasswordPanel = false;
      _recoveryEmailController.clear();
      _codeController.clear();
    });
  }

  void _cancelBinding(AppController controller) {
    controller.clearPendingBindingState();
    setState(() {
      _activeBinding = null;
      _phoneController.clear();
      _emailController.clear();
      _recoveryEmailController.clear();
      _codeController.clear();
    });
  }

  void _startPasswordAction() {
    setState(() {
      _activeBinding = null;
      _showPasswordPanel = true;
      _passwordError = null;
      _passwordController.clear();
      _confirmPasswordController.clear();
      _obscurePassword = true;
      _obscureConfirmPassword = true;
    });
  }

  void _cancelPasswordAction() {
    setState(() {
      _showPasswordPanel = false;
      _passwordError = null;
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
  }

  Future<void> _savePassword(AppController controller, AppStrings strings) async {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    if (!AppController.isValidPassword(password)) {
      setState(() {
        _passwordError = strings.authInvalidPasswordMessage;
      });
      return;
    }
    if (password != confirmPassword) {
      setState(() {
        _passwordError = strings.authPasswordMismatchMessage;
      });
      return;
    }

    setState(() {
      _passwordError = null;
    });
    final errorCode = await controller.updatePassword(password: password);
    if (!mounted) {
      return;
    }
    if (errorCode == null) {
      _cancelPasswordAction();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.accountSecurityPasswordUpdatedMessage)),
      );
      return;
    }

    setState(() {
      _passwordError = switch (errorCode) {
        'initialize_failed' => strings.authInitializeFailedMessage,
        'not_authenticated' => strings.accountSecurityNotAuthenticatedMessage,
        'invalid_password' => strings.authInvalidPasswordMessage,
        'session_expired' => strings.profileSessionExpiredMessage,
        _ => strings.accountSecurityPasswordUpdateFailedMessage,
      };
    });
  }

  Future<void> _handleDeleteAccountTap(
    AppController controller,
    AppStrings strings,
  ) async {
    controller.clearAccountDeletionError();
    if (controller.hasActiveCoupleSpace) {
      await _showCoupleSpaceBlockDialog(controller, strings);
      return;
    }

    final firstConfirmed = await _showDeleteConfirmDialog(
      title: strings.accountSecurityDeleteFirstConfirmTitle,
      body: strings.accountSecurityDeleteFirstConfirmBody,
      confirmLabel: strings.accountSecurityDeleteFirstConfirmLabel,
      confirmKey: const ValueKey('account-delete-first-confirm-button'),
    );
    if (firstConfirmed != true || !mounted) return;

    final secondConfirmed = await _showDeleteConfirmDialog(
      title: strings.accountSecurityDeleteSecondConfirmTitle,
      body: strings.accountSecurityDeleteSecondConfirmBody,
      confirmLabel: strings.accountSecurityDeleteSecondConfirmLabel,
      confirmKey: const ValueKey('account-delete-second-confirm-button'),
      destructive: true,
    );
    if (secondConfirmed != true || !mounted) return;

    final success = await controller.deleteAccount();
    if (!mounted) return;
    if (success) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    if (controller.accountDeletionErrorCode ==
        'active_couple_space_required_exit') {
      await _showCoupleSpaceBlockDialog(controller, strings);
      return;
    }

    await _showDeleteFailureDialog(strings);
  }

  Future<void> _showDeleteFailureDialog(AppStrings strings) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.accountSecurityDeleteFailedTitle),
        content: Text(strings.accountSecurityDeleteFailedBody),
        actions: [
          FilledButton(
            key: const ValueKey('account-delete-failed-ok-button'),
            onPressed: () => Navigator.pop(context),
            child: Text(strings.accountSecurityDeleteDialogOkLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _showCoupleSpaceBlockDialog(
    AppController controller,
    AppStrings strings,
  ) async {
    final openSpaceStatus = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.accountSecurityDeleteBlockedTitle),
        content: Text(strings.accountSecurityDeleteBlockedBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.profileCancelLabel),
          ),
          FilledButton(
            key: const ValueKey('account-delete-open-space-status-button'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.accountSecurityOpenSpaceStatusLabel),
          ),
        ],
      ),
    );

    if (openSpaceStatus == true && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => widget.spaceStatusRouteBuilder(
            controller,
            controller.partnerDisplayName,
          ),
        ),
      );
    }
  }

  Future<bool?> _showDeleteConfirmDialog({
    required String title,
    required String body,
    required String confirmLabel,
    required Key confirmKey,
    bool destructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.of(context).profileCancelLabel),
          ),
          FilledButton(
            key: confirmKey,
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  )
                : null,
            onPressed: AppScope.of(context).accountDeletionBusy
                ? null
                : () => Navigator.pop(context, true),
            child: AppScope.of(context).accountDeletionBusy && destructive
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final email = controller.email;
    final phone = controller.phone;
    final recoveryEmail = controller.recoveryEmail;
    final recoveryEmailPending = controller.recoveryEmailPending;

    return Scaffold(
      key: const ValueKey('account-security-screen'),
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          strings.accountSecurityTitle,
          style: TextStyle(color: isDark ? AppTheme.warmWhite90 : null),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: PageAtmosphere(
        padding: const EdgeInsets.fromLTRB(16, 92, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageSectionHeader(
              title: strings.accountSecurityTitle,
              subtitle: strings.accountSecuritySubtitle,
            ),
            const SizedBox(height: 10),
            PageSurfaceCard(
              key: const ValueKey('account-security-status-card'),
              child: Column(
                children: [
                  _CredentialStatusItem(
                    valueKey: const ValueKey('account-security-email-status'),
                    icon: Icons.alternate_email_rounded,
                    title: strings.accountSecurityEmailTitle,
                    value: _credentialLabel(
                      value: email,
                      strings: strings,
                      isEmail: true,
                    ),
                    actionLabel: email == null || email.isEmpty
                        ? strings.accountSecurityBindEmailLabel
                        : strings.accountSecurityChangeLabel,
                    onAction: () =>
                        _startBinding(controller, _BindingKind.email),
                  ),
                  PageDivider(indent: 56),
                  _CredentialStatusItem(
                    valueKey: const ValueKey('account-security-phone-status'),
                    icon: Icons.phone_iphone_rounded,
                    title: strings.accountSecurityPhoneTitle,
                    value: _credentialLabel(
                      value: phone,
                      strings: strings,
                      isEmail: false,
                    ),
                    actionLabel: phone == null || phone.isEmpty
                        ? strings.accountSecurityBindPhoneLabel
                        : strings.accountSecurityChangeLabel,
                    onAction: () =>
                        _startBinding(controller, _BindingKind.phone),
                  ),
                  PageDivider(indent: 56),
                  _CredentialStatusItem(
                    valueKey: const ValueKey('account-security-password-status'),
                    icon: Icons.lock_outline_rounded,
                    title: strings.accountSecurityPasswordTitle,
                    value: controller.hasPassword
                        ? strings.accountSecurityPasswordSetValue
                        : strings.accountSecurityPasswordUnsetValue,
                    actionLabel: controller.hasPassword
                        ? strings.accountSecurityChangePasswordLabel
                        : strings.accountSecuritySetPasswordLabel,
                    onAction: _startPasswordAction,
                  ),
                  PageDivider(indent: 56),
                  _CredentialStatusItem(
                    valueKey: const ValueKey(
                      'account-security-recovery-email-status',
                    ),
                    icon: Icons.mark_email_unread_outlined,
                    title: strings.accountSecurityRecoveryEmailTitle,
                    value: _recoveryEmailLabel(
                      recoveryEmail: recoveryEmail,
                      pendingEmail: recoveryEmailPending,
                      strings: strings,
                    ),
                    actionLabel:
                        recoveryEmailPending != null &&
                            recoveryEmailPending.isNotEmpty
                        ? strings.accountSecurityContinueVerifyLabel
                        : (recoveryEmail == null || recoveryEmail.isEmpty)
                        ? strings.accountSecurityBindRecoveryEmailLabel
                        : strings.accountSecurityChangeLabel,
                    onAction: () =>
                        recoveryEmailPending != null &&
                            recoveryEmailPending.isNotEmpty
                        ? _continueRecoveryEmailVerification(controller)
                        : _startBinding(controller, _BindingKind.recoveryEmail),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              strings.accountSecurityPrivacyHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppTheme.warmWhite60
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (_activeBinding != null) ...[
              const SizedBox(height: 16),
              _BindingPanel(
                kind: _activeBinding!,
                controller: controller,
                phoneController: _phoneController,
                emailController: _emailController,
                recoveryEmailController: _recoveryEmailController,
                codeController: _codeController,
                onChanged: (_) => controller.clearBindingError(),
                onRequest: () => _requestBinding(controller),
                onVerify: () => _verifyBinding(controller),
                onChangeRecoveryEmail: () => _changeRecoveryEmail(controller),
                onCancel: () => _cancelBinding(controller),
              ),
            ],
            if (_showPasswordPanel) ...[
              const SizedBox(height: 16),
              PageSurfaceCard(
                key: const ValueKey('account-security-password-panel'),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.hasPassword
                          ? strings.accountSecurityChangePasswordTitle
                          : strings.accountSecuritySetPasswordTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      strings.accountSecurityPasswordHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (_passwordError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _passwordError!,
                        key: const ValueKey('account-security-password-error'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      key: const ValueKey('account-security-password-field'),
                      controller: _passwordController,
                      enabled: !controller.authBusy,
                      obscureText: _obscurePassword,
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
                        setState(() {
                          _passwordError = null;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const ValueKey(
                        'account-security-confirm-password-field',
                      ),
                      controller: _confirmPasswordController,
                      enabled: !controller.authBusy,
                      obscureText: _obscureConfirmPassword,
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
                      onChanged: (_) {
                        setState(() {
                          _passwordError = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                controller.authBusy ? null : _cancelPasswordAction,
                            child: Text(strings.profileCancelLabel),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            key: const ValueKey(
                              'account-security-save-password-button',
                            ),
                            onPressed: controller.authBusy
                                ? null
                                : () => _savePassword(controller, strings),
                            child: controller.authBusy
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(strings.accountSecuritySavePasswordLabel),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 28),
            PageSectionHeader(
              title: strings.accountSecurityDangerSectionTitle,
              subtitle: strings.accountSecurityDangerSectionSubtitle,
            ),
            const SizedBox(height: 10),
            PageSurfaceCard(
              key: const ValueKey('account-security-danger-section'),
              child: PageListItem(
                key: const ValueKey('account-delete-entry'),
                leading: Icon(
                  Icons.delete_forever_outlined,
                  color: theme.colorScheme.error,
                ),
                title: strings.accountSecurityDeleteAccountTitle,
                titleColor: theme.colorScheme.error,
                subtitle: strings.accountSecurityDeleteAccountSubtitle,
                trailing: Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: isDark
                      ? AppTheme.warmWhite25
                      : theme.colorScheme.onSurfaceVariant,
                ),
                onTap: () => _handleDeleteAccountTap(controller, strings),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _credentialLabel({
    required String? value,
    required AppStrings strings,
    required bool isEmail,
  }) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return isEmail
          ? strings.accountSecurityEmailUnbound
          : strings.accountSecurityPhoneUnbound;
    }
    return normalized;
  }

  String _recoveryEmailLabel({
    required String? recoveryEmail,
    required String? pendingEmail,
    required AppStrings strings,
  }) {
    final pending = pendingEmail?.trim();
    if (pending != null && pending.isNotEmpty) {
      return strings.accountSecurityRecoveryEmailPendingValue(pending);
    }
    final verified = recoveryEmail?.trim();
    if (verified != null && verified.isNotEmpty) {
      return strings.accountSecurityRecoveryEmailVerifiedValue(verified);
    }
    return strings.accountSecurityRecoveryEmailUnbound;
  }
}

class _CredentialStatusItem extends StatelessWidget {
  const _CredentialStatusItem({
    required this.valueKey,
    required this.icon,
    required this.title,
    required this.value,
    this.actionLabel,
    this.onAction,
  });

  final Key valueKey;
  final IconData icon;
  final String title;
  final String value;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  value,
                  key: valueKey,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class _BindingPanel extends StatelessWidget {
  const _BindingPanel({
    required this.kind,
    required this.controller,
    required this.phoneController,
    required this.emailController,
    required this.recoveryEmailController,
    required this.codeController,
    required this.onChanged,
    required this.onRequest,
    required this.onVerify,
    required this.onChangeRecoveryEmail,
    required this.onCancel,
  });

  final _BindingKind kind;
  final AppController controller;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController recoveryEmailController;
  final TextEditingController codeController;
  final ValueChanged<String> onChanged;
  final Future<void> Function() onRequest;
  final Future<void> Function() onVerify;
  final VoidCallback onChangeRecoveryEmail;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final isPhone = kind == _BindingKind.phone;
    final isRecoveryEmail = kind == _BindingKind.recoveryEmail;
    final pending = switch (kind) {
      _BindingKind.phone => controller.pendingBindingPhone,
      _BindingKind.email => controller.pendingBindingEmail,
      _BindingKind.recoveryEmail => controller.recoveryEmailPending,
    };
    final currentCredential = switch (kind) {
      _BindingKind.phone => controller.phone,
      _BindingKind.email => controller.email,
      _BindingKind.recoveryEmail =>
        controller.recoveryEmail ?? controller.recoveryEmailPending,
    };
    final isChanging =
        currentCredential != null && currentCredential.isNotEmpty;
    final errorText = _bindingErrorText(strings, controller.bindingErrorCode);
    final panelKey = switch (kind) {
      _BindingKind.phone => 'bind-phone-panel',
      _BindingKind.email => 'bind-email-panel',
      _BindingKind.recoveryEmail => 'bind-recovery-email-panel',
    };

    return PageSurfaceCard(
      key: ValueKey(panelKey),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(switch (kind) {
            _BindingKind.phone =>
              isChanging
                  ? strings.accountSecurityChangePhoneTitle
                  : strings.accountSecurityBindPhoneTitle,
            _BindingKind.email =>
              isChanging
                  ? strings.accountSecurityChangeEmailTitle
                  : strings.accountSecurityBindEmailTitle,
            _BindingKind.recoveryEmail =>
              isChanging
                  ? strings.accountSecurityChangeRecoveryEmailTitle
                  : strings.accountSecurityBindRecoveryEmailTitle,
          }, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            switch (kind) {
              _BindingKind.phone =>
                isChanging
                    ? strings.accountSecurityChangePhoneHint
                    : strings.accountSecurityBindPhoneHint,
              _BindingKind.email =>
                isChanging
                    ? strings.accountSecurityChangeEmailHint
                    : strings.accountSecurityBindEmailHint,
              _BindingKind.recoveryEmail =>
                isChanging
                    ? strings.accountSecurityChangeRecoveryEmailHint
                    : strings.accountSecurityBindRecoveryEmailHint,
            },
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (errorText != null) ...[
            const SizedBox(height: 12),
            Text(
              errorText,
              key: const ValueKey('account-security-error'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (pending == null) ...[
            TextField(
              key: ValueKey(switch (kind) {
                _BindingKind.phone => 'bind-phone-field',
                _BindingKind.email => 'bind-email-field',
                _BindingKind.recoveryEmail => 'bind-recovery-email-field',
              }),
              controller: isPhone
                  ? phoneController
                  : isRecoveryEmail
                  ? recoveryEmailController
                  : emailController,
              enabled: !controller.bindingBusy,
              keyboardType: isPhone
                  ? TextInputType.phone
                  : TextInputType.emailAddress,
              inputFormatters: isPhone
                  ? [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                    ]
                  : null,
              decoration: InputDecoration(
                labelText: isPhone
                    ? strings.authPhoneLabel
                    : strings.authEmailLabel,
                hintText: isPhone
                    ? strings.authPhoneHint
                    : strings.authEmailHint,
              ),
              onChanged: onChanged,
              onSubmitted: (_) => onRequest(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: controller.bindingBusy ? null : onCancel,
                    child: Text(strings.profileCancelLabel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: ValueKey(switch (kind) {
                      _BindingKind.phone => 'bind-phone-send-button',
                      _BindingKind.email => 'bind-email-send-button',
                      _BindingKind.recoveryEmail =>
                        'bind-recovery-email-send-button',
                    }),
                    onPressed: controller.bindingBusy ? null : onRequest,
                    child: controller.bindingBusy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(strings.accountSecuritySendBindingCodeLabel),
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              isRecoveryEmail
                  ? strings.accountSecurityRecoveryEmailCodeSentTo(pending)
                  : strings.accountSecurityBindingCodeSentTo(pending),
              key: const ValueKey('account-security-pending-target'),
              style: theme.textTheme.titleSmall,
            ),
            if (isRecoveryEmail) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  TextButton(
                    key: const ValueKey('bind-recovery-email-resend-button'),
                    onPressed: controller.bindingBusy ? null : onRequest,
                    child: Text(strings.accountSecuritySendBindingCodeLabel),
                  ),
                  TextButton(
                    key: const ValueKey('bind-recovery-email-change-button'),
                    onPressed: controller.bindingBusy
                        ? null
                        : onChangeRecoveryEmail,
                    child: Text(strings.accountSecurityChangeLabel),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              key: ValueKey(switch (kind) {
                _BindingKind.phone => 'bind-phone-otp-field',
                _BindingKind.email => 'bind-email-otp-field',
                _BindingKind.recoveryEmail => 'bind-recovery-email-otp-field',
              }),
              controller: codeController,
              enabled: !controller.bindingBusy,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: strings.authOtpLabel,
                hintText: strings.authOtpHint,
              ),
              onChanged: onChanged,
              onSubmitted: (_) => onVerify(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: controller.bindingBusy ? null : onCancel,
                    child: Text(strings.profileCancelLabel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: ValueKey(switch (kind) {
                      _BindingKind.phone => 'bind-phone-verify-button',
                      _BindingKind.email => 'bind-email-verify-button',
                      _BindingKind.recoveryEmail =>
                        'bind-recovery-email-verify-button',
                    }),
                    onPressed: controller.bindingBusy ? null : onVerify,
                    child: controller.bindingBusy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(strings.accountSecurityVerifyBindingLabel),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String? _bindingErrorText(AppStrings strings, String? errorCode) {
    return switch (errorCode) {
      null => null,
      'initialize_failed' => strings.authInitializeFailedMessage,
      'not_authenticated' => strings.accountSecurityNotAuthenticatedMessage,
      'invalid_phone' => strings.authInvalidPhoneMessage,
      'invalid_email' => strings.authInvalidEmailMessage,
      'invalid_token_length' => strings.authInvalidTokenLengthMessage,
      'missing_pending_phone' => strings.authMissingPendingPhoneMessage,
      'missing_pending_email' => strings.authMissingPendingEmailMessage,
      'same_credential' => strings.accountSecuritySameCredentialMessage,
      'same_recovery_email' => strings.accountSecuritySameRecoveryEmailMessage,
      'binding_target_in_use' => strings.accountSecurityBindingConflictMessage,
      'recovery_email_in_use' =>
        strings.accountSecurityRecoveryEmailConflictMessage,
      'missing_pending_recovery_email' =>
        strings.accountSecurityMissingPendingRecoveryEmailMessage,
      'recovery_email_token_expired' =>
        strings.accountSecurityRecoveryEmailTokenExpiredMessage,
      'binding_phone_send_failed' =>
        strings.accountSecurityPhoneBindingSendFailedMessage,
      'binding_email_send_failed' =>
        strings.accountSecurityEmailBindingSendFailedMessage,
      'recovery_email_send_failed' =>
        strings.accountSecurityRecoveryEmailSendFailedMessage,
      'recovery_email_verify_failed' =>
        strings.accountSecurityRecoveryEmailVerifyFailedMessage,
      'binding_verify_failed' =>
        strings.accountSecurityBindingVerifyFailedMessage,
      _ => strings.authUnknownErrorMessage,
    };
  }
}

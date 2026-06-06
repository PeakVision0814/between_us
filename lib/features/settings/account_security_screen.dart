import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../app/app_strings.dart';
import '../../app/app_theme.dart';
import '../../shared/widgets/page_visual_language.dart';

enum _BindingKind { phone, email }

class AccountSecurityScreen extends StatefulWidget {
  const AccountSecurityScreen({super.key});

  @override
  State<AccountSecurityScreen> createState() => _AccountSecurityScreenState();
}

class _AccountSecurityScreenState extends State<AccountSecurityScreen> {
  _BindingKind? _activeBinding;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _requestBinding(AppController controller) async {
    final kind = _activeBinding;
    if (kind == null) return;

    final success = switch (kind) {
      _BindingKind.phone => await controller.requestPhoneBindingOtp(
        _phoneController.text,
      ),
      _BindingKind.email => await controller.requestEmailBindingOtp(
        _emailController.text,
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
    };
    if (success && mounted) {
      setState(() {
        _activeBinding = null;
        _phoneController.clear();
        _emailController.clear();
        _codeController.clear();
      });
    }
  }

  void _startBinding(AppController controller, _BindingKind kind) {
    controller.clearPendingBindingState();
    setState(() {
      _activeBinding = kind;
      _codeController.clear();
    });
  }

  void _cancelBinding(AppController controller) {
    controller.clearPendingBindingState();
    setState(() {
      _activeBinding = null;
      _phoneController.clear();
      _emailController.clear();
      _codeController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final email = controller.email;
    final phone = controller.phone;

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
                        : null,
                    onAction: email == null || email.isEmpty
                        ? () => _startBinding(controller, _BindingKind.email)
                        : null,
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
                        : null,
                    onAction: phone == null || phone.isEmpty
                        ? () => _startBinding(controller, _BindingKind.phone)
                        : null,
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
                codeController: _codeController,
                onChanged: (_) => controller.clearBindingError(),
                onRequest: () => _requestBinding(controller),
                onVerify: () => _verifyBinding(controller),
                onCancel: () => _cancelBinding(controller),
              ),
            ],
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
    required this.codeController,
    required this.onChanged,
    required this.onRequest,
    required this.onVerify,
    required this.onCancel,
  });

  final _BindingKind kind;
  final AppController controller;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController codeController;
  final ValueChanged<String> onChanged;
  final Future<void> Function() onRequest;
  final Future<void> Function() onVerify;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final isPhone = kind == _BindingKind.phone;
    final pending = isPhone
        ? controller.pendingBindingPhone
        : controller.pendingBindingEmail;
    final errorText = _bindingErrorText(strings, controller.bindingErrorCode);

    return PageSurfaceCard(
      key: ValueKey(
        isPhone ? 'bind-phone-panel' : 'bind-email-panel',
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isPhone
                ? strings.accountSecurityBindPhoneTitle
                : strings.accountSecurityBindEmailTitle,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            isPhone
                ? strings.accountSecurityBindPhoneHint
                : strings.accountSecurityBindEmailHint,
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
              key: ValueKey(isPhone ? 'bind-phone-field' : 'bind-email-field'),
              controller: isPhone ? phoneController : emailController,
              enabled: !controller.bindingBusy,
              keyboardType: isPhone
                  ? TextInputType.phone
                  : TextInputType.emailAddress,
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
                    key: ValueKey(
                      isPhone
                          ? 'bind-phone-send-button'
                          : 'bind-email-send-button',
                    ),
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
              strings.accountSecurityBindingCodeSentTo(pending),
              key: const ValueKey('account-security-pending-target'),
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            TextField(
              key: ValueKey(isPhone ? 'bind-phone-otp-field' : 'bind-email-otp-field'),
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
                    key: ValueKey(
                      isPhone
                          ? 'bind-phone-verify-button'
                          : 'bind-email-verify-button',
                    ),
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
      'binding_target_in_use' => strings.accountSecurityBindingConflictMessage,
      'binding_phone_send_failed' =>
        strings.accountSecurityPhoneBindingSendFailedMessage,
      'binding_email_send_failed' =>
        strings.accountSecurityEmailBindingSendFailedMessage,
      'binding_verify_failed' => strings.accountSecurityBindingVerifyFailedMessage,
      _ => strings.authUnknownErrorMessage,
    };
  }
}

import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../app/app_strings.dart';
import 'auth_email_flow.dart';

class EmailRegisterScreen extends StatefulWidget {
  const EmailRegisterScreen({super.key});

  @override
  State<EmailRegisterScreen> createState() => _EmailRegisterScreenState();
}

class _EmailRegisterScreenState extends State<EmailRegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final controller = AppScope.read(context);
    final success = await controller.signUpWithEmail(_emailController.text);
    if (!mounted || !success) {
      return;
    }

    if (controller.authStatus == AppAuthStatus.otpSent) {
      _codeController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.of(context).authRegisterOtpSentToast),
        ),
      );
    }
  }

  Future<void> _verifyCode() async {
    final controller = AppScope.read(context);
    await controller.verifyEmailOtp(_codeController.text);
  }

  void _backToSignIn() {
    final controller = AppScope.read(context);
    controller.clearAuthError();
    controller.returnToEmailEntry();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AuthEmailFlowScaffold(
      mode: AuthEmailFlowMode.register,
      emailController: _emailController,
      codeController: _codeController,
      onPrimarySubmit: _signUp,
      onVerifyCode: _verifyCode,
      onSwitchMode: _backToSignIn,
    );
  }
}

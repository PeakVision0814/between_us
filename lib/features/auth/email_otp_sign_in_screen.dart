import 'package:flutter/material.dart';

import 'auth_email_flow.dart';
import '../../app/app_controller.dart';
import '../../app/app_strings.dart';
import 'email_register_screen.dart';

class EmailOtpSignInScreen extends StatefulWidget {
  const EmailOtpSignInScreen({super.key});

  @override
  State<EmailOtpSignInScreen> createState() => _EmailOtpSignInScreenState();
}

class _EmailOtpSignInScreenState extends State<EmailOtpSignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.of(context).authOtpSentToast)),
    );
  }

  Future<void> _sendPhoneCode() async {
    final controller = AppScope.read(context);
    final success = await controller.sendPhoneOtpForSignIn(
      _phoneController.text,
    );
    if (!mounted || !success) {
      return;
    }

    _codeController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.of(context).authPhoneOtpSentToast)),
    );
  }

  Future<void> _verifyCode() async {
    final controller = AppScope.read(context);
    await controller.verifyEmailOtp(_codeController.text);
  }

  Future<void> _verifyPhoneCode() async {
    final controller = AppScope.read(context);
    await controller.verifyPhoneOtp(_codeController.text);
  }

  void _openRegister() {
    final controller = AppScope.read(context);
    controller.clearAuthError();
    controller.returnToEmailEntry();
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const EmailRegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthEmailFlowScaffold(
      mode: AuthEmailFlowMode.signIn,
      emailController: _emailController,
      phoneController: _phoneController,
      codeController: _codeController,
      onPrimarySubmit: _sendCode,
      onPhoneSubmit: _sendPhoneCode,
      onVerifyCode: _verifyCode,
      onVerifyPhoneCode: _verifyPhoneCode,
      onSwitchMode: _openRegister,
    );
  }
}

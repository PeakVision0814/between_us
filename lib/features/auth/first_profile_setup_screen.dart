import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../app/app_strings.dart';

class FirstProfileSetupScreen extends StatefulWidget {
  const FirstProfileSetupScreen({super.key});

  @override
  State<FirstProfileSetupScreen> createState() =>
      _FirstProfileSetupScreenState();
}

class _FirstProfileSetupScreenState extends State<FirstProfileSetupScreen> {
  final TextEditingController _displayNameController = TextEditingController();
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    final controller = AppScope.read(context);
    _displayNameController.text = controller.displayName?.trim() ?? '';
    _initialized = true;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final controller = AppScope.read(context);
    await controller.saveDisplayName(_displayNameController.text);
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final strings = AppStrings.of(context);
    final isChinese = strings.isChinese;

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
                      Text(
                        isChinese ? '先填写一个昵称' : 'Set your display name first',
                        key: const ValueKey('profile-setup-title'),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isChinese
                            ? '登录已经完成。保存昵称后，才能进入 Between Us 主页面。'
                            : 'Sign-in is complete. Save your display name before entering the main app.',
                      ),
                      const SizedBox(height: 20),
                      if (controller.profileErrorCode case final errorCode?)
                        _ProfileErrorBanner(
                          message: _errorText(errorCode, isChinese),
                        ),
                      if (controller.profileErrorCode != null)
                        const SizedBox(height: 16),
                      TextField(
                        key: const ValueKey('profile-display-name-field'),
                        controller: _displayNameController,
                        enabled: !controller.profileSaveInProgress,
                        autofocus: true,
                        textInputAction: TextInputAction.done,
                        maxLength: 40,
                        decoration: InputDecoration(
                          labelText: isChinese ? '昵称' : 'Display name',
                          hintText: isChinese
                              ? '输入你想展示的昵称'
                              : 'Enter the name you want to show',
                        ),
                        onChanged: (_) => controller.clearProfileError(),
                        onSubmitted: (_) => _save(),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          key: const ValueKey('profile-save-button'),
                          onPressed: controller.profileSaveInProgress
                              ? null
                              : _save,
                          child: controller.profileSaveInProgress
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(isChinese ? '保存并进入' : 'Save and continue'),
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
    );
  }

  String _errorText(String errorCode, bool isChinese) {
    return switch (errorCode) {
      'initialize_failed' =>
        isChinese
            ? '资料服务初始化失败，请稍后重试。'
            : 'Profile service failed to initialize. Please try again.',
      'missing_user' =>
        isChinese
            ? '当前登录状态无效，请重新登录。'
            : 'Your session is invalid. Please sign in again.',
      'invalid_display_name' =>
        isChinese
            ? '昵称不能为空、不能使用默认占位名，且不能超过 40 个字符。'
            : 'Display name must be 1 to 40 characters, and cannot be the default placeholder.',
      'save_failed' =>
        isChinese
            ? '昵称保存失败，请稍后重试。'
            : 'Failed to save your display name. Please try again.',
      _ =>
        isChinese
            ? '资料保存时发生异常，请重试。'
            : 'Something went wrong while saving your profile. Please try again.',
    };
  }
}

class _ProfileErrorBanner extends StatelessWidget {
  const _ProfileErrorBanner({required this.message});

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

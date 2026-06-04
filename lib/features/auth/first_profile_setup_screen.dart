import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../app/app_strings.dart';
import 'auth_page_visuals.dart';

class FirstProfileSetupScreen extends StatefulWidget {
  const FirstProfileSetupScreen({super.key});

  @override
  State<FirstProfileSetupScreen> createState() =>
      _FirstProfileSetupScreenState();
}

class _FirstProfileSetupScreenState extends State<FirstProfileSetupScreen> {
  final TextEditingController _displayNameController = TextEditingController();
  String? _selectedGender;
  DateTime? _selectedBirthday;
  bool _initialized = false;

  bool get _canSubmit {
    final trimmedDisplayName = _displayNameController.text.trim();
    return trimmedDisplayName.isNotEmpty &&
        trimmedDisplayName.characters.length <= 40 &&
        trimmedDisplayName != AppController.defaultDisplayNamePlaceholder &&
        _selectedGender != null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    final controller = AppScope.read(context);
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
    _selectedBirthday = controller.birthday;
    _initialized = true;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    final controller = AppScope.read(context);
    controller.clearProfileError();
    final now = DateUtils.dateOnly(DateTime.now());
    final fallbackDay = now.day > 28 ? 28 : now.day;
    final initialDate =
        _selectedBirthday ?? DateTime(now.year - 20, now.month, fallbackDay);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(now) ? now : initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (!mounted || picked == null) {
      return;
    }
    setState(() {
      _selectedBirthday = DateUtils.dateOnly(picked);
    });
  }

  Future<void> _save() async {
    if (!_canSubmit) {
      return;
    }
    final controller = AppScope.read(context);
    await controller.saveProfileSetup(
      displayName: _displayNameController.text,
      gender: _selectedGender!,
      birthday: _selectedBirthday,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final strings = AppStrings.of(context);
    final isChinese = strings.isChinese;

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
                        Text(
                          isChinese ? '完善你的资料' : 'Complete your profile',
                          key: const ValueKey('profile-setup-title'),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isChinese
                              ? '登录已经完成。请先填写昵称和性别，生日可以稍后补充为空。保存后即可进入 Between Us。'
                              : 'Sign-in is complete. Finish your name and gender first. Birthday is optional, and you can continue after saving.',
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
                          onChanged: (_) {
                            controller.clearProfileError();
                            setState(() {});
                          },
                          onSubmitted: (_) => _save(),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isChinese ? '性别' : 'Gender',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            ChoiceChip(
                              key: const ValueKey('profile-gender-male'),
                              label: Text(isChinese ? '男生' : 'Male'),
                              selected:
                                  _selectedGender == AppController.genderMale,
                              onSelected: controller.profileSaveInProgress
                                  ? null
                                  : (selected) {
                                      controller.clearProfileError();
                                      setState(() {
                                        _selectedGender = selected
                                            ? AppController.genderMale
                                            : null;
                                      });
                                    },
                            ),
                            ChoiceChip(
                              key: const ValueKey('profile-gender-female'),
                              label: Text(isChinese ? '女生' : 'Female'),
                              selected:
                                  _selectedGender == AppController.genderFemale,
                              onSelected: controller.profileSaveInProgress
                                  ? null
                                  : (selected) {
                                      controller.clearProfileError();
                                      setState(() {
                                        _selectedGender = selected
                                            ? AppController.genderFemale
                                            : null;
                                      });
                                    },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          isChinese ? '生日（可选）' : 'Birthday (optional)',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          key: const ValueKey('profile-birthday-button'),
                          onPressed: controller.profileSaveInProgress
                              ? null
                              : _pickBirthday,
                          icon: const Icon(Icons.cake_outlined),
                          label: Text(_birthdayLabel(isChinese)),
                        ),
                        if (_selectedBirthday != null) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            key: const ValueKey(
                              'profile-birthday-clear-button',
                            ),
                            onPressed: controller.profileSaveInProgress
                                ? null
                                : () {
                                    controller.clearProfileError();
                                    setState(() {
                                      _selectedBirthday = null;
                                    });
                                  },
                            child: Text(isChinese ? '清空生日' : 'Clear birthday'),
                          ),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            key: const ValueKey('profile-save-button'),
                            onPressed:
                                controller.profileSaveInProgress || !_canSubmit
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
                                : Text(
                                    isChinese ? '保存并进入' : 'Save and continue',
                                  ),
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

  String _birthdayLabel(bool isChinese) {
    if (_selectedBirthday == null) {
      return isChinese ? '选择生日' : 'Choose your birthday';
    }
    final year = _selectedBirthday!.year;
    final month = _selectedBirthday!.month.toString().padLeft(2, '0');
    final day = _selectedBirthday!.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
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
      'invalid_gender' =>
        isChinese ? '请选择性别后再继续。' : 'Please choose your gender.',
      'save_failed' =>
        isChinese
            ? '资料保存失败，请稍后重试。'
            : 'Failed to save your profile. Please try again.',
      'session_expired' =>
        isChinese
            ? '登录状态已过期，请重新登录。'
            : 'Your session has expired. Please sign in again.',
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

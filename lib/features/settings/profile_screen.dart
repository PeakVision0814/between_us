import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../app/app_strings.dart';
import '../../app/app_theme.dart';
import '../../shared/widgets/page_visual_language.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  String? _editGender;
  DateTime? _editBirthday;
  String? _nameError;
  String? _genderError;
  bool _hasNameInteracted = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.controller.displayName ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _enterEditMode() {
    setState(() {
      _isEditing = true;
      _nameController.text = widget.controller.displayName ?? '';
      _editGender = widget.controller.gender;
      _editBirthday = widget.controller.birthday;
      _nameError = null;
      _genderError = null;
      _hasNameInteracted = false;
    });
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _nameError = null;
      _genderError = null;
      _hasNameInteracted = false;
    });
  }

  bool _validateName() {
    final trimmed = _nameController.text.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _nameError = AppStrings.of(context).profileDisplayNameEmptyError;
      });
      return false;
    }
    if (trimmed.characters.length > 40) {
      setState(() {
        _nameError = AppStrings.of(context).profileDisplayNameTooLongError;
      });
      return false;
    }
    setState(() {
      _nameError = null;
    });
    return true;
  }

  bool _validateGender() {
    if (_editGender == null || _editGender == AppController.genderUnset) {
      setState(() {
        _genderError = AppStrings.of(context).profileGenderRequiredError;
      });
      return false;
    }
    setState(() {
      _genderError = null;
    });
    return true;
  }

  bool _validate() {
    final nameValid = _validateName();
    final genderValid = _validateGender();
    return nameValid && genderValid;
  }

  Future<void> _save() async {
    if (!_validate()) return;

    final displayName = _nameController.text.trim();
    final gender = _editGender!;
    final birthday = _editBirthday;

    final success = await widget.controller.saveProfileSetup(
      displayName: displayName,
      gender: gender,
      birthday: birthday,
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        _isEditing = false;
      });
    } else {
      final errorCode = widget.controller.profileErrorCode;
      final strings = AppStrings.of(context);
      final message = errorCode == 'session_expired'
          ? strings.profileSessionExpiredMessage
          : strings.profileSaveFailedMessage;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final initial =
        _editBirthday ?? DateTime(now.year - 20, now.month, now.day);
    final firstDate = DateTime(1900);
    final lastDate = now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null && mounted) {
      setState(() {
        _editBirthday = DateUtils.dateOnly(picked);
      });
    }
  }

  void _clearBirthday() {
    setState(() {
      _editBirthday = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          strings.isChinese ? '个人资料' : 'My profile',
          style: TextStyle(color: isDark ? AppTheme.warmWhite90 : null),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (_isEditing) ...[
            TextButton(
              key: const ValueKey('profile-cancel-button'),
              onPressed: _cancelEdit,
              child: Text(
                strings.profileCancelLabel,
                style: TextStyle(color: isDark ? AppTheme.warmWhite60 : null),
              ),
            ),
            TextButton(
              key: const ValueKey('profile-save-button'),
              onPressed: widget.controller.profileSaveInProgress ? null : _save,
              child: widget.controller.profileSaveInProgress
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(strings.profileSaveLabel),
            ),
          ] else ...[
            IconButton(
              key: const ValueKey('profile-edit-button'),
              onPressed: _enterEditMode,
              icon: Icon(
                Icons.edit_outlined,
                color: isDark ? AppTheme.warmWhite60 : null,
              ),
              tooltip: strings.profileEditLabel,
            ),
          ],
        ],
      ),
      body: PageAtmosphere(
        padding: const EdgeInsets.fromLTRB(16, 92, 16, 32),
        child: PageSurfaceCard(
          variant: PageSurfaceVariant.secondary,
          radius: AppTheme.radius2xl,
          padding: EdgeInsets.zero,
          child: _isEditing
              ? _buildEditMode(strings, theme, isDark)
              : _buildReadMode(strings, theme, isDark),
        ),
      ),
    );
  }

  // ─── Read mode ─────────────────────────────────────────────────────

  Widget _buildReadMode(AppStrings strings, ThemeData theme, bool isDark) {
    return Column(
      children: [
        _ProfileRow(
          label: strings.profileDisplayNameLabel,
          value: _resolvedSelfName(widget.controller, strings),
          valueKey: const ValueKey('profile-display-name'),
          isDark: isDark,
        ),
        const PageDivider(indent: 20),
        _ProfileRow(
          label: strings.profileEmailLabel,
          value: _emailLabel(strings, widget.controller.email),
          valueKey: const ValueKey('profile-email'),
          isPlaceholder: widget.controller.email == null,
          isDark: isDark,
        ),
        const PageDivider(indent: 20),
        _ProfileRow(
          label: strings.profileGenderLabel,
          value: _genderLabel(strings, widget.controller.gender),
          valueKey: const ValueKey('profile-gender'),
          isDark: isDark,
        ),
        const PageDivider(indent: 20),
        _ProfileRow(
          label: strings.profileBirthdayLabel,
          value: _birthdayLabel(strings, widget.controller.birthday),
          valueKey: const ValueKey('profile-birthday'),
          isPlaceholder: widget.controller.birthday == null,
          isDark: isDark,
          isLast: true,
        ),
      ],
    );
  }

  // ─── Edit mode ─────────────────────────────────────────────────────

  Widget _buildEditMode(AppStrings strings, ThemeData theme, bool isDark) {
    final colorScheme = theme.colorScheme;
    final labelColor = isDark
        ? AppTheme.warmWhite60
        : colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display name
          _EditLabel(text: strings.profileDisplayNameLabel, color: labelColor),
          const SizedBox(height: 6),
          TextFormField(
            key: const ValueKey('profile-edit-name-field'),
            controller: _nameController,
            maxLength: 40,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: strings.profileDisplayNameHint,
              errorText: _nameError,
              counterText: '',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
            onChanged: (_) {
              if (_hasNameInteracted) {
                _validateName();
              }
            },
            onTap: () {
              if (!_hasNameInteracted) {
                _hasNameInteracted = true;
              }
            },
          ),
          const SizedBox(height: 18),

          // Email (read-only)
          _EditLabel(text: strings.profileEmailLabel, color: labelColor),
          const SizedBox(height: 6),
          _ReadOnlyField(
            key: const ValueKey('profile-edit-email-field'),
            value: _emailLabel(strings, widget.controller.email),
            isPlaceholder: widget.controller.email == null,
            isDark: isDark,
          ),
          const SizedBox(height: 18),

          // Gender
          _EditLabel(text: strings.profileGenderLabel, color: labelColor),
          const SizedBox(height: 6),
          _GenderSelector(
            selected: _editGender,
            onChanged: (value) {
              setState(() {
                _editGender = value;
                if (_genderError != null) _genderError = null;
              });
            },
            strings: strings,
            isDark: isDark,
          ),
          if (_genderError != null) ...[
            const SizedBox(height: 6),
            Text(
              _genderError!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 18),

          // Birthday
          _EditLabel(text: strings.profileBirthdayLabel, color: labelColor),
          const SizedBox(height: 6),
          _BirthdayPicker(
            birthday: _editBirthday,
            onPick: _pickBirthday,
            onClear: _clearBirthday,
            strings: strings,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────

  String _resolvedSelfName(AppController controller, AppStrings strings) {
    final normalized = _normalizeName(controller.displayName);
    return normalized ?? (strings.isChinese ? '我' : 'Me');
  }

  String? _normalizeName(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  String _emailLabel(AppStrings strings, String? email) {
    if (email == null || email.isEmpty) {
      return strings.isChinese ? '未获取' : 'Unavailable';
    }
    return email;
  }

  String _genderLabel(AppStrings strings, String? gender) {
    return switch (gender) {
      AppController.genderMale => strings.profileGenderMaleLabel,
      AppController.genderFemale => strings.profileGenderFemaleLabel,
      _ => strings.isChinese ? '尚未补充' : 'Not set yet',
    };
  }

  String _birthdayLabel(AppStrings strings, DateTime? birthday) {
    if (birthday == null) {
      return strings.isChinese ? '还没有填写' : 'Not added yet.';
    }

    final month = birthday.month.toString().padLeft(2, '0');
    final day = birthday.day.toString().padLeft(2, '0');
    return strings.isChinese
        ? '${birthday.year} 年 $month 月 $day 日'
        : '${birthday.year}-$month-$day';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Read-mode row
// ═══════════════════════════════════════════════════════════════════════

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.label,
    required this.value,
    this.valueKey,
    this.isPlaceholder = false,
    this.isDark = false,
    this.isLast = false,
  });

  final String label;
  final String value;
  final Key? valueKey;
  final bool isPlaceholder;
  final bool isDark;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 6, 20, isLast ? 14 : 6),
      child: PageListItem(
        compact: true,
        leading: SizedBox(
          width: 72,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppTheme.warmWhite60
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        title: value,
        titleKey: valueKey,
        titleStyle: theme.textTheme.bodyLarge,
        titleColor: isPlaceholder
            ? (isDark ? AppTheme.warmWhite25 : colorScheme.onSurfaceVariant)
            : null,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Edit-mode helpers
// ═══════════════════════════════════════════════════════════════════════

class _EditLabel extends StatelessWidget {
  const _EditLabel({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
    );
  }
}

/// Read-only field shown for email in edit mode.
class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    super.key,
    required this.value,
    this.isPlaceholder = false,
    this.isDark = false,
  });

  final String value;
  final bool isPlaceholder;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        value,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: isPlaceholder
              ? (isDark ? AppTheme.warmWhite25 : colorScheme.onSurfaceVariant)
              : (isDark ? AppTheme.warmWhite60 : colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

/// Gender segmented selector for edit mode.
class _GenderSelector extends StatelessWidget {
  const _GenderSelector({
    required this.selected,
    required this.onChanged,
    required this.strings,
    required this.isDark,
  });

  final String? selected;
  final ValueChanged<String?> onChanged;
  final AppStrings strings;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: [
        ButtonSegment<String>(
          value: AppController.genderMale,
          label: Text(strings.profileGenderMaleLabel),
          icon: const Icon(Icons.male, size: 18),
        ),
        ButtonSegment<String>(
          value: AppController.genderFemale,
          label: Text(strings.profileGenderFemaleLabel),
          icon: const Icon(Icons.female, size: 18),
        ),
      ],
      selected:
          selected == AppController.genderMale ||
              selected == AppController.genderFemale
          ? {selected!}
          : <String>{},
      onSelectionChanged: (selection) {
        onChanged(selection.isEmpty ? null : selection.first);
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.standard,
        textStyle: WidgetStatePropertyAll(
          Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

/// Birthday picker row for edit mode.
class _BirthdayPicker extends StatelessWidget {
  const _BirthdayPicker({
    required this.birthday,
    required this.onPick,
    required this.onClear,
    required this.strings,
    required this.isDark,
  });

  final DateTime? birthday;
  final VoidCallback onPick;
  final VoidCallback onClear;
  final AppStrings strings;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final displayText = birthday != null
        ? _formatDate(birthday!, strings)
        : strings.profileBirthdayHint;

    return Row(
      children: [
        Expanded(
          child: InkWell(
            key: const ValueKey('profile-edit-birthday-button'),
            onTap: onPick,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark
                      ? AppTheme.warmWhite25
                      : colorScheme.outlineVariant,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: isDark
                        ? AppTheme.warmWhite60
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    displayText,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: birthday == null
                          ? (isDark
                                ? AppTheme.warmWhite25
                                : colorScheme.onSurfaceVariant)
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (birthday != null) ...[
          const SizedBox(width: 8),
          IconButton(
            key: const ValueKey('profile-edit-birthday-clear'),
            onPressed: onClear,
            icon: Icon(
              Icons.clear,
              size: 20,
              color: isDark
                  ? AppTheme.warmWhite60
                  : colorScheme.onSurfaceVariant,
            ),
            tooltip: strings.profileBirthdayClearLabel,
          ),
        ],
      ],
    );
  }

  String _formatDate(DateTime date, AppStrings strings) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return strings.isChinese
        ? '${date.year} 年 $month 月 $day 日'
        : '${date.year}-$month-$day';
  }
}

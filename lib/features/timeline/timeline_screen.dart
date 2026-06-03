import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/app_controller.dart';
import '../../app/app_strings.dart';
import '../../app/app_theme.dart';
import '../../data/models/note_record.dart';
import '../../data/models/plan_record.dart';
import '../../shared/widgets/page_visual_language.dart';

enum PlansNotesMode { overview, plan, note }

class PlansNotesScreen extends StatefulWidget {
  const PlansNotesScreen({super.key, this.mode = PlansNotesMode.overview});

  final PlansNotesMode mode;

  @override
  State<PlansNotesScreen> createState() => PlansNotesScreenState();
}

class PlansNotesScreenState extends State<PlansNotesScreen> {
  late PlansNotesMode _activeMode;
  Future<List<NoteRecord>>? _notesFuture;
  Future<List<PlanRecord>>? _plansFuture;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _activeMode = widget.mode == PlansNotesMode.overview
        ? PlansNotesMode.plan
        : widget.mode;
    _notesFuture = _fetchNotes();
    _plansFuture = _fetchPlans();
  }

  Future<List<NoteRecord>> _fetchNotes() async {
    try {
      final response = await Supabase.instance.client
          .from('notes')
          .select()
          .filter('deleted_at', 'is', null)
          .order('authored_at', ascending: false);
      return (response as List)
          .map((json) => NoteRecord.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  void _refreshNotes() {
    setState(() {
      _notesFuture = _fetchNotes();
    });
  }

  Future<List<PlanRecord>> _fetchPlans() async {
    try {
      final response = await Supabase.instance.client
          .from('plans')
          .select()
          .filter('deleted_at', 'is', null)
          .order('created_at', ascending: false);
      return (response as List)
          .map((json) => PlanRecord.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  void _refreshPlans() {
    setState(() {
      _plansFuture = _fetchPlans();
    });
  }

  Future<bool> _submitPlan(String title, String body) async {
    if (title.trim().isEmpty) return false;
    if (!AppScope.read(context).hasActiveCoupleSpace) return false;

    setState(() => _submitting = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return false;
      final coupleSpaceId = AppScope.read(context).currentSpaceId;
      if (coupleSpaceId == null) return false;

      await Supabase.instance.client.from('plans').insert({
        'couple_space_id': coupleSpaceId,
        'created_by': user.id,
        'title': title.trim(),
        'body': body.trim().isEmpty ? null : body.trim(),
        'status': 'idea',
      });

      _refreshPlans();
      return true;
    } catch (_) {
      return false;
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _showCreatePlanDialog() {
    final strings = AppStrings.of(context);
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(strings.isChinese ? '加一个计划' : 'Add a plan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: strings.isChinese
                      ? '想做什么...'
                      : 'What do you want to do...',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyController,
                decoration: InputDecoration(
                  hintText: strings.isChinese
                      ? '补充说明（可选）'
                      : 'Details (optional)',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(strings.isChinese ? '取消' : 'Cancel'),
            ),
            FilledButton(
              onPressed: _submitting
                  ? null
                  : () async {
                      final success = await _submitPlan(
                        titleController.text,
                        bodyController.text,
                      );
                      if (success && context.mounted) {
                        Navigator.pop(context);
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              strings.isChinese
                                  ? '创建失败，请重试'
                                  : 'Failed to create. Please try again.',
                            ),
                          ),
                        );
                      }
                    },
              child: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(strings.isChinese ? '创建' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _submitNote(String body) async {
    if (body.trim().isEmpty) return false;
    if (!AppScope.read(context).hasActiveCoupleSpace) return false;

    setState(() => _submitting = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return false;
      final coupleSpaceId = AppScope.read(context).currentSpaceId;
      if (coupleSpaceId == null) return false;

      await Supabase.instance.client.from('notes').insert({
        'couple_space_id': coupleSpaceId,
        'author_profile_id': user.id,
        'body': body.trim(),
        'authored_at': DateTime.now().toIso8601String(),
        'author_local_date': DateTime.now().toIso8601String().substring(0, 10),
      });

      _refreshNotes();
      return true;
    } catch (_) {
      return false;
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _showWriteNoteDialog() {
    final strings = AppStrings.of(context);
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(strings.isChinese ? '写随记' : 'Write a note'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: strings.isChinese
                  ? '想到什么就留一点...'
                  : 'Leave a little something...',
            ),
            autofocus: true,
            maxLines: 4,
            textInputAction: TextInputAction.newline,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(strings.isChinese ? '取消' : 'Cancel'),
            ),
            FilledButton(
              onPressed: _submitting
                  ? null
                  : () async {
                      final success = await _submitNote(controller.text);
                      if (success && context.mounted) {
                        Navigator.pop(context);
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              strings.isChinese
                                  ? '发送失败，请重试'
                                  : 'Failed to send. Please try again.',
                            ),
                          ),
                        );
                      }
                    },
              child: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(strings.isChinese ? '发送' : 'Send'),
            ),
          ],
        ),
      ),
    );
  }

  void switchMode(PlansNotesMode mode) {
    if (mode == PlansNotesMode.overview) return;
    setState(() => _activeMode = mode);
  }

  @override
  void didUpdateWidget(PlansNotesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mode != PlansNotesMode.overview &&
        widget.mode != oldWidget.mode) {
      _activeMode = widget.mode;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final isPlanMode = _activeMode == PlansNotesMode.plan;
    final isPaired = AppScope.of(context).hasActiveCoupleSpace;

    return PageAtmosphere(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Mode toggle ──
          _ModeToggle(
            activeMode: _activeMode,
            onChanged: (mode) => setState(() => _activeMode = mode),
          ),
          const SizedBox(height: 24),

          // ── Mode lead card ──
          _ModeLeadCard(isPlanMode: isPlanMode),
          const SizedBox(height: 24),

          if (isPlanMode) ...[
            // ── Plans section ──
            PageSectionHeader(
              title: strings.plansSectionTitle,
              subtitle: strings.plansSectionSubtitle,
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<PlanRecord>>(
              future: _plansFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data!.isEmpty) {
                  return Column(
                    children: [
                      _PlansEmptyState(isChinese: strings.isChinese),
                      const SizedBox(height: 16),
                      _CreatePlanButton(
                        isChinese: strings.isChinese,
                        onPressed: isPaired ? _showCreatePlanDialog : null,
                      ),
                    ],
                  );
                }

                final plans = snapshot.data!;
                return Column(
                  children: [
                    ...plans.map(
                      (plan) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _PlanCard(
                          plan: PlanItemCopy(
                            title: plan.title,
                            body: plan.body ?? '',
                            statusLabel: _planStatusLabel(
                              plan.status,
                              isChinese: strings.isChinese,
                            ),
                            helperLabel: '',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _CreatePlanButton(
                      isChinese: strings.isChinese,
                      onPressed: isPaired ? _showCreatePlanDialog : null,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            _SecondaryHint(
              label: strings.switchToNotesHint,
              onTap: () => setState(() => _activeMode = PlansNotesMode.note),
            ),
          ] else ...[
            // ── Notes section ──
            PageSectionHeader(
              title: strings.notesSectionTitle,
              subtitle: strings.notesSectionSubtitle,
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<NoteRecord>>(
              future: _notesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data!.isEmpty) {
                  return Column(
                    children: [
                      _NotesEmptyState(isChinese: strings.isChinese),
                      const SizedBox(height: 16),
                      _WriteNoteButton(
                        isChinese: strings.isChinese,
                        onPressed: isPaired ? _showWriteNoteDialog : null,
                      ),
                    ],
                  );
                }

                final notes = snapshot.data!;
                return Column(
                  children: [
                    ...notes.map(
                      (note) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _NoteCard(
                          note: NoteItemCopy(
                            author: note.authorProfileId,
                            timeLabel: _formatTimeLabel(
                              note.authoredAt,
                              isChinese: strings.isChinese,
                            ),
                            text: note.body,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _WriteNoteButton(
                      isChinese: strings.isChinese,
                      onPressed: isPaired ? _showWriteNoteDialog : null,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            _SecondaryHint(
              label: strings.switchToPlansHint,
              onTap: () => setState(() => _activeMode = PlansNotesMode.plan),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Mode Toggle ────────────────────────────────────────────────────────

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.activeMode, required this.onChanged});

  final PlansNotesMode activeMode;
  final ValueChanged<PlansNotesMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPlan = activeMode == PlansNotesMode.plan;

    return PageSurfaceCard(
      variant: PageSurfaceVariant.secondary,
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _ToggleChip(
              label: strings.plansSectionTitle,
              active: isPlan,
              isDark: isDark,
              onTap: () => onChanged(PlansNotesMode.plan),
            ),
          ),
          Expanded(
            child: _ToggleChip(
              label: strings.notesSectionTitle,
              active: !isPlan,
              isDark: isDark,
              onTap: () => onChanged(PlansNotesMode.note),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.active,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool active;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: active
              ? (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.65))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: active
              ? Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.5),
                  width: 0.5,
                )
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active
                  ? (isDark ? AppTheme.warmWhite90 : colorScheme.onSurface)
                  : (isDark
                        ? AppTheme.warmWhite60
                        : colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Mode Lead Card ─────────────────────────────────────────────────────

class _ModeLeadCard extends StatelessWidget {
  const _ModeLeadCard({required this.isPlanMode});

  final bool isPlanMode;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PageSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageIconBadge(
            icon: isPlanMode
                ? Icons.lightbulb_outline
                : Icons.note_alt_outlined,
            color: isPlanMode ? AppTheme.mint : AppTheme.blush,
          ),
          const SizedBox(height: 16),
          Text(
            isPlanMode ? strings.planModeLeadTitle : strings.noteModeLeadTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            isPlanMode
                ? strings.planModeLeadSubtitle
                : strings.noteModeLeadSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppTheme.warmWhite60
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Plan Card ──────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});

  final PlanItemCopy plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return PageSurfaceCard(
      variant: PageSurfaceVariant.secondary,
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PageIconBadge(
                    icon: Icons.route_outlined,
                    color: AppTheme.mint,
                    size: 28,
                  ),
                  const Spacer(),
                  _StatusBadge(label: plan.statusLabel),
                ],
              ),
              const SizedBox(height: 14),
              Text(plan.title, style: theme.textTheme.titleMedium),
              if (plan.body.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  plan.body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppTheme.warmWhite60
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (plan.helperLabel.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(plan.helperLabel, style: theme.textTheme.bodySmall),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Note Card ──────────────────────────────────────────────────────────

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note});

  final NoteItemCopy note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return PageSurfaceCard(
      variant: PageSurfaceVariant.secondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PageIconBadge(
                icon: Icons.notes_rounded,
                color: AppTheme.blush,
                size: 28,
              ),
              const Spacer(),
              Text(
                note.timeLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppTheme.warmWhite60
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            note.text,
            style: theme.textTheme.titleMedium?.copyWith(height: 1.35),
          ),
        ],
      ),
    );
  }
}

// ─── Status Badge ───────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ─── Empty States ───────────────────────────────────────────────────────

class _PlansEmptyState extends StatelessWidget {
  const _PlansEmptyState({required this.isChinese});

  final bool isChinese;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            PageIconBadge(
              icon: Icons.lightbulb_outline,
              color: AppTheme.mint,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              isChinese ? '还没有计划' : 'No plans yet',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              isChinese ? '想做的事先记在这里' : 'Jot down what you want to do',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppTheme.warmWhite60
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotesEmptyState extends StatelessWidget {
  const _NotesEmptyState({required this.isChinese});

  final bool isChinese;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            PageIconBadge(
              icon: Icons.note_alt_outlined,
              color: AppTheme.blush,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              isChinese ? '还没有随记' : 'No notes yet',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              isChinese ? '写一条给对方看看吧' : 'Leave one for your partner',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppTheme.warmWhite60
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Action Buttons ─────────────────────────────────────────────────────

class _CreatePlanButton extends StatelessWidget {
  const _CreatePlanButton({required this.isChinese, required this.onPressed});

  final bool isChinese;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add, size: 20),
        label: Text(isChinese ? '加一个计划' : 'Add a plan'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          foregroundColor: isDark
              ? AppTheme.warmWhite90
              : Theme.of(context).colorScheme.primary,
          side: BorderSide(
            color: isDark
                ? AppTheme.surfaceBorderDarkSoft
                : AppTheme.surfaceBorderLightSoft,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
        ),
      ),
    );
  }
}

class _WriteNoteButton extends StatelessWidget {
  const _WriteNoteButton({required this.isChinese, required this.onPressed});

  final bool isChinese;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.edit_outlined, size: 20),
        label: Text(isChinese ? '写随记' : 'Write a note'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          foregroundColor: isDark
              ? AppTheme.warmWhite90
              : Theme.of(context).colorScheme.primary,
          side: BorderSide(
            color: isDark
                ? AppTheme.surfaceBorderDarkSoft
                : AppTheme.surfaceBorderLightSoft,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
        ),
      ),
    );
  }
}

// ─── Secondary Hint ─────────────────────────────────────────────────────

class _SecondaryHint extends StatelessWidget {
  const _SecondaryHint({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : AppTheme.warmGray50.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isDark
                ? AppTheme.surfaceBorderDarkSoft.withValues(alpha: 0.5)
                : AppTheme.surfaceBorderLightSoft,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.swap_horiz_rounded,
              size: 18,
              color: isDark
                  ? AppTheme.warmWhite60
                  : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.45),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppTheme.warmWhite60
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ────────────────────────────────────────────────────────────

String _formatTimeLabel(DateTime dateTime, {required bool isChinese}) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inMinutes < 1) {
    return isChinese ? '刚刚' : 'Just now';
  } else if (difference.inHours < 1) {
    return isChinese
        ? '${difference.inMinutes} 分钟前'
        : '${difference.inMinutes} min ago';
  } else if (difference.inDays < 1) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  } else if (difference.inDays < 7) {
    final weekdays = isChinese
        ? ['周一', '周二', '周三', '周四', '周五', '周六', '周日']
        : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[dateTime.weekday - 1]} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  } else {
    if (isChinese) {
      return '${dateTime.month}月${dateTime.day}日';
    }
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}';
  }
}

String _planStatusLabel(String status, {required bool isChinese}) {
  return switch (status) {
    'idea' => isChinese ? '想法中' : 'Idea',
    'discussing' => isChinese ? '待讨论' : 'Discussing',
    'scheduled' => isChinese ? '已安排' : 'Scheduled',
    'done' => isChinese ? '已完成' : 'Done',
    'archived' => isChinese ? '已归档' : 'Archived',
    _ => status,
  };
}

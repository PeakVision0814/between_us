import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/couple_space_guard.dart';
import '../../app/app_strings.dart';
import '../../data/models/note_record.dart';
import '../../data/models/plan_record.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/section_header.dart';

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
  String? _coupleSpaceId;
  bool _submitting = false;
  late final CoupleSpaceGuard _coupleSpaceGuard;

  @override
  void initState() {
    super.initState();
    _coupleSpaceGuard = CoupleSpaceGuard.usingSupabase();
    _activeMode = widget.mode == PlansNotesMode.overview
        ? PlansNotesMode.plan
        : widget.mode;
    _notesFuture = _fetchNotes();
    _plansFuture = _fetchPlans();
    _loadCoupleSpaceId();
  }

  Future<void> _loadCoupleSpaceId() async {
    try {
      _coupleSpaceId = await _coupleSpaceGuard.loadCurrentSpaceId();
    } catch (_) {
      // Query failed; will be null.
    }
  }

  Future<String?> _ensureCoupleSpaceId() async {
    final currentSpaceId = _coupleSpaceId;
    if (currentSpaceId != null) {
      return currentSpaceId;
    }

    try {
      final ensuredSpaceId = await _coupleSpaceGuard.ensureSpaceId();
      _coupleSpaceId = ensuredSpaceId;
      return ensuredSpaceId;
    } catch (error) {
      debugPrint('[PlansNotes] ensure couple space failed: $error');
      return null;
    }
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

    setState(() => _submitting = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return false;
      final coupleSpaceId = await _ensureCoupleSpaceId();
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

    setState(() => _submitting = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return false;
      final coupleSpaceId = await _ensureCoupleSpaceId();
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

    return AppPage(
      children: [
        _ModeToggle(
          activeMode: _activeMode,
          onChanged: (mode) => setState(() => _activeMode = mode),
        ),
        const SizedBox(height: 16),
        _ModeLeadCard(isPlanMode: isPlanMode),
        const SizedBox(height: 18),
        if (isPlanMode) ...[
          SectionHeader(title: strings.plansSectionTitle),
          _SectionIntro(text: strings.plansSectionSubtitle),
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
                      onPressed: _showCreatePlanDialog,
                    ),
                  ],
                );
              }

              final plans = snapshot.data!;
              return Column(
                children: [
                  ...plans.map(
                    (plan) => _PlanCard(
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
                  const SizedBox(height: 16),
                  _CreatePlanButton(
                    isChinese: strings.isChinese,
                    onPressed: _showCreatePlanDialog,
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
          SectionHeader(title: strings.notesSectionTitle),
          _SectionIntro(text: strings.notesSectionSubtitle),
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
                      onPressed: _showWriteNoteDialog,
                    ),
                  ],
                );
              }

              final notes = snapshot.data!;
              return Column(
                children: [
                  ...notes.map(
                    (note) => _NoteCard(
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
                  const SizedBox(height: 16),
                  _WriteNoteButton(
                    isChinese: strings.isChinese,
                    onPressed: _showWriteNoteDialog,
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
    );
  }
}

class _SectionIntro extends StatelessWidget {
  const _SectionIntro({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});

  final PlanItemCopy plan;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  plan.statusLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(plan.title, style: Theme.of(context).textTheme.titleMedium),
              if (plan.body.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(plan.body),
              ],
              const SizedBox(height: 12),
              Text(
                plan.helperLabel,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note});

  final NoteItemCopy note;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.author,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    note.timeLabel,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(note.text),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.activeMode, required this.onChanged});

  final PlansNotesMode activeMode;
  final ValueChanged<PlansNotesMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isPlan = activeMode == PlansNotesMode.plan;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleChip(
              label: strings.plansSectionTitle,
              active: isPlan,
              onTap: () => onChanged(PlansNotesMode.plan),
            ),
          ),
          Expanded(
            child: _ToggleChip(
              label: strings.notesSectionTitle,
              active: !isPlan,
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
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? colorScheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active
                  ? colorScheme.onSurface
                  : colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeLeadCard extends StatelessWidget {
  const _ModeLeadCard({required this.isPlanMode});

  final bool isPlanMode;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isPlanMode
                  ? strings.planModeLeadTitle
                  : strings.noteModeLeadTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              isPlanMode
                  ? strings.planModeLeadSubtitle
                  : strings.noteModeLeadSubtitle,
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryHint extends StatelessWidget {
  const _SecondaryHint({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.swap_horiz_rounded,
              size: 18,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.note_alt_outlined,
              size: 48,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              isChinese ? '还没有随记' : 'No notes yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              isChinese ? '写一条给对方看看吧' : 'Leave one for your partner',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

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

class _WriteNoteButton extends StatelessWidget {
  const _WriteNoteButton({required this.isChinese, required this.onPressed});

  final bool isChinese;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.edit_outlined),
        label: Text(isChinese ? '写随记' : 'Write a note'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
        ),
      ),
    );
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

class _PlansEmptyState extends StatelessWidget {
  const _PlansEmptyState({required this.isChinese});

  final bool isChinese;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 48,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              isChinese ? '还没有计划' : 'No plans yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              isChinese ? '想做的事先记在这里' : 'Jot down what you want to do',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatePlanButton extends StatelessWidget {
  const _CreatePlanButton({required this.isChinese, required this.onPressed});

  final bool isChinese;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add),
        label: Text(isChinese ? '加一个计划' : 'Add a plan'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
        ),
      ),
    );
  }
}

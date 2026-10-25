import 'package:flutter/material.dart';

import '../../models/chore.dart';
import '../../models/priority.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/app_scope.dart';
import '../../widgets/common/dialogs.dart';
import '../../widgets/common/member_avatar.dart';
import '../../widgets/common/status_pill.dart';
import 'chore_detail_screen.dart';

class AssignmentTile extends StatelessWidget {
  const AssignmentTile({
    super.key,
    required this.assignment,
    this.showCompleteButton = true,
  });

  final ChoreAssignment assignment;
  final bool showCompleteButton;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    final chore = app.choreById(assignment.choreId);
    final overdue = assignment.isOverdue(app.today);
    final isMine = assignment.assigneeMemberId == app.data.currentMemberId;
    final assignee = app.memberName(assignment.assigneeMemberId);

    return ListTile(
      onTap: () => showAssignmentActions(context, assignment.id),
      leading: MemberAvatar(member: app.member(assignment.assigneeMemberId)),
      title: Text(
        chore?.title ?? '—',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('${isMine ? '$assignee (${s.you})' : assignee} · '),
            if (overdue)
              StatusPill(
                label: s.overdueSince(
                  s.dates.relativeDay(assignment.dueDate, app.today),
                ),
                icon: Icons.warning_amber_rounded,
                tone: PillTone.overdue,
              )
            else
              Text(
                s.dates.relativeDayCapitalized(assignment.dueDate, app.today),
              ),
            if (assignment.changes.isNotEmpty)
              StatusPill(
                label:
                    assignment.changes.last.type == AssignmentChangeType.swapped
                    ? s.swappedBadge
                    : s.reassignedBadge,
                icon: Icons.swap_horiz,
              ),
            if (chore?.priority == Priority.high)
              StatusPill(
                label: s.priorityLabel(Priority.high),
                icon: Icons.priority_high,
                tone: PillTone.soon,
              ),
          ],
        ),
      ),
      trailing: showCompleteButton && assignment.isPending
          ? IconButton(
              tooltip: s.markDone,
              icon: const Icon(Icons.check_circle_outline),
              onPressed: () => completeWithUndo(context, assignment.id),
            )
          : null,
    );
  }
}

void completeWithUndo(BuildContext context, String assignmentId) {
  final app = context.app;
  final s = context.s;
  final assignment = app.assignmentById(assignmentId);
  final title = app.choreById(assignment?.choreId)?.title ?? '';
  final next = app.completeAssignment(assignmentId);
  final message = next == null
      ? s.choreDone(title)
      : '${s.choreDone(title)}. ${s.nextTurn(app.memberName(next.assigneeMemberId), s.dates.relativeDay(next.dueDate, app.today))}';
  showSnack(
    context,
    message,
    actionLabel: s.undo,
    onAction: () => app.undoCompletion(assignmentId, next?.id),
  );
}

Future<void> showAssignmentActions(BuildContext context, String assignmentId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      final app = sheetContext.app;
      final s = sheetContext.s;
      final theme = Theme.of(sheetContext);
      final a = app.assignmentById(assignmentId);
      if (a == null) return const SizedBox.shrink();
      final chore = app.choreById(a.choreId);

      void close() => Navigator.pop(sheetContext);

      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                0,
                AppSpacing.page,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  MemberAvatar(
                    member: app.member(a.assigneeMemberId),
                    radius: 22,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chore?.title ?? '—',
                          style: theme.textTheme.titleLarge,
                        ),
                        Text(
                          '${app.memberName(a.assigneeMemberId)} · ${s.dueOn(s.dates.relativeDay(a.dueDate, app.today))}',
                          style: theme.textTheme.bodyMedium,
                        ),
                        if (a.changes.isNotEmpty)
                          Text(
                            s.originally(app.memberName(a.originalAssigneeId)),
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            if (a.isPending) ...[
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: Text(s.markDone),
                onTap: () {
                  close();
                  completeWithUndo(context, assignmentId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_search_outlined),
                title: Text(s.reassign),
                onTap: () {
                  close();
                  _reassign(context, assignmentId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.swap_horiz),
                title: Text(s.swap),
                onTap: () {
                  close();
                  _swap(context, assignmentId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.redo),
                title: Text(s.skip),
                onTap: () {
                  close();
                  _skip(context, assignmentId);
                },
              ),
            ],
            if (chore != null)
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(s.aboutChore),
                onTap: () {
                  close();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChoreDetailScreen(choreId: chore.id),
                    ),
                  );
                },
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      );
    },
  );
}

Future<void> _reassign(BuildContext context, String assignmentId) async {
  final app = context.app;
  final s = context.s;
  final a = app.assignmentById(assignmentId);
  if (a == null) return;
  final candidates = app.activeMembers
      .where((m) => m.id != a.assigneeMemberId)
      .toList();
  final picked = await showDialog<String>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: Text(s.reassignTitle),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.sm,
          ),
          child: Text(
            s.reassignNote,
            style: Theme.of(dialogContext).textTheme.bodySmall,
          ),
        ),
        for (final m in candidates)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, m.id),
            child: Row(
              children: [
                MemberAvatar(member: m, radius: 14),
                const SizedBox(width: AppSpacing.md),
                Text(m.displayName),
              ],
            ),
          ),
      ],
    ),
  );
  if (picked == null || !context.mounted) return;
  app.reassign(assignmentId, picked);
  showSnack(context, s.reassigned);
}

Future<void> _swap(BuildContext context, String assignmentId) async {
  final app = context.app;
  final s = context.s;
  final a = app.assignmentById(assignmentId);
  if (a == null) return;
  final options = app.pendingAssignments
      .where((x) => x.id != a.id && x.assigneeMemberId != a.assigneeMemberId)
      .toList();
  if (options.isEmpty) {
    showSnack(context, s.noSwapCandidates);
    return;
  }
  final picked = await showDialog<String>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: Text(s.swapTitle),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.sm,
          ),
          child: Text(
            s.swapNote,
            style: Theme.of(dialogContext).textTheme.bodySmall,
          ),
        ),
        for (final o in options)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, o.id),
            child: Row(
              children: [
                MemberAvatar(
                  member: app.member(o.assigneeMemberId),
                  radius: 14,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    '${app.choreById(o.choreId)?.title ?? ''}\n${app.memberName(o.assigneeMemberId)} · ${s.dates.relativeDay(o.dueDate, app.today)}',
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
  if (picked == null || !context.mounted) return;
  app.swapAssignments(assignmentId, picked);
  showSnack(context, s.swapped);
}

Future<void> _skip(BuildContext context, String assignmentId) async {
  final app = context.app;
  final s = context.s;
  final reason = await showDialog<String>(
    context: context,
    builder: (_) => const _SkipDialog(),
  );
  if (reason == null || !context.mounted) return;
  app.skipAssignment(assignmentId, reason);
  showSnack(context, s.skipped);
}

class _SkipDialog extends StatefulWidget {
  const _SkipDialog();

  @override
  State<_SkipDialog> createState() => _SkipDialogState();
}

class _SkipDialogState extends State<_SkipDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return AlertDialog(
      title: Text(s.skipTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.skipNote, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _reason,
              autofocus: true,
              decoration: InputDecoration(
                labelText: s.skipReason,
                hintText: s.skipReasonHint,
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) {
                final text = (v ?? '').trim();
                if (text.isEmpty) return s.fieldRequired;
                if (text.length > 120) return s.textTooLong(120);
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _reason.text.trim());
            }
          },
          child: Text(s.skip),
        ),
      ],
    );
  }
}

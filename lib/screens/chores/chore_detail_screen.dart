import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../widgets/common/app_scope.dart';
import '../../widgets/common/dialogs.dart';
import '../../widgets/common/member_avatar.dart';
import '../../widgets/common/missing_item_screen.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/status_pill.dart';
import '../../widgets/forms/picker_fields.dart';
import 'assignment_actions.dart';
import 'chore_form_screen.dart';
import 'chores_screen.dart';

class ChoreDetailScreen extends StatelessWidget {
  const ChoreDetailScreen({super.key, required this.choreId});

  final String choreId;

  Future<void> _archive(BuildContext context) async {
    final app = context.app;
    final s = context.s;
    final ok = await confirmAction(
      context,
      title: s.archiveChoreTitle,
      message: s.archiveChoreBody,
      confirmLabel: s.archive,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    Navigator.of(context).pop();
    app.archiveChore(choreId);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    final theme = Theme.of(context);
    final chore = app.choreById(choreId);
    if (chore == null) return const MissingItemScreen();
    final current = app.currentAssignmentFor(chore.id);
    final projection = app.projectionFor(chore);
    final decision = app.rotationFor(chore);
    final history = app.closedAssignments
        .where((a) => a.choreId == chore.id)
        .take(12)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(s.aboutChore),
        actions: [
          if (chore.isActive)
            IconButton(
              tooltip: s.edit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChoreFormScreen(existing: chore),
                ),
              ),
            ),
          if (chore.isActive)
            IconButton(
              tooltip: s.archive,
              icon: const Icon(Icons.archive_outlined),
              onPressed: () => _archive(context),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.page),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(chore.title, style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    StatusPill(
                      label: s.frequency(chore.frequency),
                      icon: Icons.event_repeat,
                    ),
                    StatusPill(
                      label: s.priorityLabel(chore.priority),
                      icon: priorityIcon(chore.priority),
                    ),
                    StatusPill(
                      label: s.shared,
                      icon: Icons.home_outlined,
                      tone: PillTone.shared,
                    ),
                  ],
                ),
                if (chore.notes.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(chore.notes, style: theme.textTheme.bodyMedium),
                ],
              ],
            ),
          ),
          SectionHeader(
            title: s.currentTurn,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              0,
              AppSpacing.page,
              0,
            ),
          ),
          if (current == null)
            ListTile(title: Text(s.noCurrentTurn))
          else
            AssignmentTile(assignment: current),
          if (projection.length > 1) ...[
            SectionHeader(title: s.forecast),
            for (final turn in projection.skip(1))
              ListTile(
                dense: true,
                leading: MemberAvatar(
                  member: app.member(turn.memberId),
                  radius: 14,
                ),
                title: Text(app.memberName(turn.memberId)),
                trailing: Text(
                  s.dates.relativeDayCapitalized(turn.dueDate, app.today),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              child: Text(s.forecastNote, style: theme.textTheme.bodySmall),
            ),
          ],
          SectionHeader(title: s.howChosen),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final rule in s.rotationRules)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Text(rule, style: theme.textTheme.bodySmall),
                      ),
                    const Divider(height: AppSpacing.xl),
                    Table(
                      columnWidths: const {0: FlexColumnWidth(2)},
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      children: [
                        TableRow(
                          children: [
                            const SizedBox.shrink(),
                            _head(context, s.colRecentTurns),
                            _head(context, s.colLastTurn),
                            _head(context, s.colOpenTasks),
                          ],
                        ),
                        for (final c in decision.ranking)
                          TableRow(
                            decoration: c.memberId == decision.memberId
                                ? BoxDecoration(
                                    color: theme.colorScheme.primaryContainer
                                        .withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.sm,
                                    ),
                                  )
                                : null,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.sm,
                                  horizontal: AppSpacing.xs,
                                ),
                                child: Row(
                                  children: [
                                    MemberAvatar(
                                      member: app.member(c.memberId),
                                      radius: 12,
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Flexible(
                                      child: Text(
                                        app.memberName(c.memberId),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _cell(context, '${c.recentTurns}'),
                              _cell(
                                context,
                                c.lastTurnDate == null
                                    ? s.never
                                    : s.dates.day(
                                        c.lastTurnDate!,
                                        now: app.today,
                                      ),
                              ),
                              _cell(context, '${c.openAssignments}'),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(s.rankingNote, style: theme.textTheme.bodySmall),
                    if (decision.memberId != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        '${s.nextByRules}: ${app.memberName(decision.memberId)}',
                        style: theme.textTheme.titleSmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          SectionHeader(title: s.choreHistory),
          if (history.isEmpty)
            ListTile(title: Text(s.noHistory))
          else
            for (final a in history) HistoryTile(assignment: a),
        ],
      ),
    );
  }

  Widget _head(BuildContext context, String text) => Text(
    text,
    textAlign: TextAlign.center,
    style: Theme.of(context).textTheme.labelSmall
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
  );

  Widget _cell(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall,
    ),
  );
}

import 'package:flutter/material.dart';

import '../../models/chore.dart';
import '../../theme/app_spacing.dart';
import '../../utils/date_math.dart';
import '../../widgets/common/app_scope.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/member_avatar.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/status_pill.dart';
import 'assignment_actions.dart';
import 'chore_detail_screen.dart';
import 'chore_form_screen.dart';

class ChoresScreen extends StatelessWidget {
  const ChoresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.choresTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: s.tabCurrent),
              Tab(text: s.tabSchedule),
              Tab(text: s.tabHistory),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'chores-fab',
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const ChoreFormScreen())),
          icon: const Icon(Icons.add),
          label: Text(s.addChore),
        ),
        body: const TabBarView(
          children: [_CurrentTab(), _ScheduleTab(), _HistoryTab()],
        ),
      ),
    );
  }
}

class _CurrentTab extends StatefulWidget {
  const _CurrentTab();

  @override
  State<_CurrentTab> createState() => _CurrentTabState();
}

class _CurrentTabState extends State<_CurrentTab> {
  bool _onlyMine = false;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    final today = app.today;
    final tomorrow = addDays(today, 1);
    final me = app.data.currentMemberId;
    final pending = app.pendingAssignments
        .where((a) => !_onlyMine || a.assigneeMemberId == me)
        .toList();
    final overdue = pending.where((a) => a.dueDate.isBefore(today)).toList();
    final dueToday = pending
        .where(
          (a) => !a.dueDate.isBefore(today) && a.dueDate.isBefore(tomorrow),
        )
        .toList();
    final later = pending.where((a) => !a.dueDate.isBefore(tomorrow)).toList();
    final loads = app.choreLoads;
    final doneThisWeek = loads.fold<int>(
      0,
      (sum, l) => sum + l.completedThisWeek,
    );
    final openCount = app.pendingAssignments.length;
    final overdueCount = app.pendingAssignments
        .where((a) => a.isOverdue(today))
        .length;

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.fabClearance),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.lg,
            AppSpacing.page,
            0,
          ),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              StatusPill(
                label: '${s.doneThisWeek}: $doneThisWeek',
                icon: Icons.task_alt,
                tone: PillTone.positive,
              ),
              StatusPill(
                label: '${s.pending}: $openCount',
                icon: Icons.pending_outlined,
              ),
              StatusPill(
                label: '${s.overdue}: $overdueCount',
                icon: Icons.warning_amber_rounded,
                tone: overdueCount > 0 ? PillTone.overdue : PillTone.neutral,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.md,
            AppSpacing.page,
            0,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FilterChip(
              avatar: _onlyMine
                  ? null
                  : MemberAvatar(member: app.currentMember, radius: 12),
              label: Text(s.onlyMine),
              selected: _onlyMine,
              onSelected: (v) => setState(() => _onlyMine = v),
            ),
          ),
        ),
        if (pending.isEmpty)
          EmptyState(
            icon: Icons.cleaning_services_outlined,
            title: s.noPendingChores,
            message: s.noPendingChoresHint,
            actionLabel: s.addChore,
            onAction: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ChoreFormScreen())),
          ),
        if (overdue.isNotEmpty) ...[
          SectionHeader(title: s.overdue),
          for (final a in overdue) AssignmentTile(assignment: a),
        ],
        if (dueToday.isNotEmpty) ...[
          SectionHeader(title: s.today),
          for (final a in dueToday) AssignmentTile(assignment: a),
        ],
        if (later.isNotEmpty) ...[
          SectionHeader(title: s.upcoming),
          for (final a in later) AssignmentTile(assignment: a),
        ],
      ],
    );
  }
}

class _ScheduleTab extends StatelessWidget {
  const _ScheduleTab();

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    final theme = Theme.of(context);
    final loads = app.choreLoads;
    final chores = app.activeChores;

    TableRow row(List<Widget> cells) => TableRow(
      children: [
        for (final cell in cells)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: cell,
          ),
      ],
    );
    Text num(int value) => Text(
      '$value',
      textAlign: TextAlign.center,
      style: theme.textTheme.titleSmall,
    );
    Text head(String text) => Text(
      text,
      textAlign: TextAlign.center,
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.fabClearance),
      children: [
        SectionHeader(title: s.workloadTitle),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Table(
                    columnWidths: const {0: FlexColumnWidth(2.2)},
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      row([
                        const SizedBox.shrink(),
                        head(s.colAssigned),
                        head(s.colDone),
                        head(s.colOpen),
                      ]),
                      for (final load in loads)
                        row([
                          Row(
                            children: [
                              MemberAvatar(
                                member: app.member(load.memberId),
                                radius: 12,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: Text(
                                  app.memberName(load.memberId),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          num(load.assignedThisWeek),
                          num(load.completedThisWeek),
                          num(load.pending),
                        ]),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(s.workloadNote, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ),
        SectionHeader(title: s.recurringChores),
        if (chores.isEmpty)
          EmptyState(
            icon: Icons.event_repeat,
            title: s.noPendingChores,
            message: s.noPendingChoresHint,
            compact: true,
          ),
        for (final chore in chores) _ChoreTemplateTile(chore: chore),
      ],
    );
  }
}

class _ChoreTemplateTile extends StatelessWidget {
  const _ChoreTemplateTile({required this.chore});

  final Chore chore;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    final current = app.currentAssignmentFor(chore.id);
    final subtitle = current == null
        ? s.nobodyEligible
        : s.nextUp(
            app.memberName(current.assigneeMemberId),
            s.dates.relativeDay(current.dueDate, app.today),
          );
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        child: const Icon(Icons.event_repeat, size: 20),
      ),
      title: Text(chore.title),
      subtitle: Text(
        '${s.frequency(chore.frequency)} · ${s.priorityLabel(chore.priority)}\n$subtitle',
      ),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ChoreDetailScreen(choreId: chore.id)),
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    final closed = app.closedAssignments;
    if (closed.isEmpty) {
      return EmptyState(icon: Icons.history, title: s.noHistory);
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppSpacing.fabClearance),
      itemCount: closed.length,
      itemBuilder: (context, index) => HistoryTile(assignment: closed[index]),
    );
  }
}

class HistoryTile extends StatelessWidget {
  const HistoryTile({super.key, required this.assignment});

  final ChoreAssignment assignment;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    final a = assignment;
    final done = a.status == AssignmentStatus.completed;
    final detail = done
        ? s.doneOn(
            s.dates.dayAndTime(a.completedAt ?? a.dueDate, now: app.today),
          )
        : s.skippedBecause(a.skipReason ?? '');
    return ListTile(
      leading: MemberAvatar(member: app.member(a.assigneeMemberId), radius: 16),
      title: Text(app.choreById(a.choreId)?.title ?? '—'),
      subtitle: Text(
        [
          '${app.memberName(a.assigneeMemberId)} · ${s.dueOn(s.dates.day(a.dueDate, now: app.today))}',
          detail,
          if (a.changes.isNotEmpty)
            s.originally(app.memberName(a.originalAssigneeId)),
        ].join('\n'),
      ),
      isThreeLine: true,
      trailing: StatusPill(
        label: done ? s.statusDone : s.statusSkipped,
        icon: done ? Icons.check : Icons.redo,
        tone: done ? PillTone.done : PillTone.neutral,
      ),
    );
  }
}

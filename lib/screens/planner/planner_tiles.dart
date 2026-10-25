import 'package:flutter/material.dart';

import '../../models/chore.dart';
import '../../models/household_event.dart';
import '../../models/planner_item.dart';
import '../../models/priority.dart';
import '../../services/calculations/planner_filters.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/app_scope.dart';
import '../../widgets/common/category_icons.dart';
import '../../widgets/common/dialogs.dart';
import '../../widgets/common/status_pill.dart';
import '../chores/assignment_actions.dart';
import '../household/calendar_screen.dart';
import 'planner_item_sheet.dart';

class PlannerItemTile extends StatelessWidget {
  const PlannerItemTile({super.key, required this.item, this.day});

  final PlannerItem item;
  final DateTime? day;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    final theme = Theme.of(context);
    final now = app.now();
    final overdue = isPlannerItemOverdue(item, now);
    final when = item.isRecurring
        ? '${s.dates.weekdayName(item.dueAt.weekday)}, ${_timeRange(context)}'
        : (item.category.isTimeBlock
              ? '${s.dates.relativeDayCapitalized(item.dueAt, app.today)}, ${_timeRange(context)}'
              : s.dueLabel(item.dueAt, now, withTime: true));
    final details = [
      s.plannerCategory(item.category),
      if (item.course.isNotEmpty && item.course != item.title) item.course,
      if (day == null || !item.isRecurring) when else _timeRange(context),
    ].join(' · ');

    return ListTile(
      onTap: () => showPlannerItemSheet(context, item.id),
      leading: item.canBeCompleted
          ? SizedBox(
              width: 36,
              child: Checkbox(
                value: item.isCompleted,
                semanticLabel: item.isCompleted
                    ? s.markIncomplete
                    : s.markComplete,
                onChanged: (value) {
                  app.setPlannerCompleted(item.id, value ?? false);
                  if (value == true) {
                    showSnack(
                      context,
                      s.taskCompleted,
                      actionLabel: s.undo,
                      onAction: () => app.setPlannerCompleted(item.id, false),
                    );
                  }
                },
              ),
            )
          : CircleAvatar(
              radius: 18,
              backgroundColor: context.colors.personalContainer,
              foregroundColor: context.colors.personal,
              child: Icon(plannerIcon(item.category), size: 20),
            ),
      title: Text(
        item.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: item.isCompleted
            ? TextStyle(
                decoration: TextDecoration.lineThrough,
                color: theme.colorScheme.onSurfaceVariant,
              )
            : null,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(details),
            if (overdue)
              StatusPill(
                label: s.overdue,
                icon: Icons.warning_amber_rounded,
                tone: PillTone.overdue,
              ),
            if (item.priority == Priority.high && !item.isCompleted)
              StatusPill(
                label: s.priorityLabel(Priority.high),
                icon: Icons.priority_high,
                tone: PillTone.soon,
              ),
            if (item.isRecurring)
              StatusPill(label: s.weekly, icon: Icons.event_repeat),
          ],
        ),
      ),
    );
  }

  String _timeRange(BuildContext context) {
    final s = context.s;
    final end = item.endAt;
    return end == null
        ? s.dates.time(item.dueAt)
        : '${s.dates.time(item.dueAt)}–${s.dates.time(end)}';
  }
}

class SharedChoreTile extends StatelessWidget {
  const SharedChoreTile({super.key, required this.assignment});

  final ChoreAssignment assignment;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    final overdue = assignment.isOverdue(app.today);
    return ListTile(
      onTap: () => showAssignmentActions(context, assignment.id),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: context.colors.sharedContainer,
        foregroundColor: context.colors.shared,
        child: const Icon(choreIcon, size: 20),
      ),
      title: Text(app.choreById(assignment.choreId)?.title ?? '—'),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '${s.choreItem} · ${s.dates.relativeDayCapitalized(assignment.dueDate, app.today)}',
            ),
            StatusPill(
              label: s.shared,
              icon: Icons.home_outlined,
              tone: PillTone.shared,
            ),
            if (overdue)
              StatusPill(
                label: s.overdue,
                icon: Icons.warning_amber_rounded,
                tone: PillTone.overdue,
              ),
          ],
        ),
      ),
    );
  }
}

class SharedEventTile extends StatelessWidget {
  const SharedEventTile({super.key, required this.event});

  final HouseholdEvent event;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    final end = event.endAt;
    final time = end == null
        ? s.dates.time(event.startAt)
        : '${s.dates.time(event.startAt)}–${s.dates.time(end)}';
    return ListTile(
      onTap: () => showEventSheet(context, event.id),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: context.colors.sharedContainer,
        foregroundColor: context.colors.shared,
        child: Icon(eventIcon(event.type), size: 20),
      ),
      title: Text(event.title),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '${s.householdEvent} · ${s.dates.relativeDayCapitalized(event.startAt, app.today)}, $time',
            ),
            StatusPill(
              label: s.shared,
              icon: Icons.home_outlined,
              tone: PillTone.shared,
            ),
          ],
        ),
      ),
    );
  }
}

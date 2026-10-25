import 'package:flutter/material.dart';

import '../../services/calculations/planner_filters.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/app_scope.dart';
import '../../widgets/common/category_icons.dart';
import '../../widgets/common/dialogs.dart';
import '../../widgets/common/status_pill.dart';
import '../../widgets/forms/picker_fields.dart';
import 'planner_form_screen.dart';

Future<void> showPlannerItemSheet(BuildContext context, String itemId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      final app = sheetContext.app;
      final s = sheetContext.s;
      final theme = Theme.of(sheetContext);
      final item = app.plannerItemById(itemId);
      if (item == null) return const SizedBox.shrink();
      final overdue = isPlannerItemOverdue(item, app.now());
      final end = item.endAt;
      final when = item.isRecurring
          ? '${s.weekly}: ${s.dates.weekdayName(item.dueAt.weekday)}, ${s.dates.time(item.dueAt)}${end == null ? '' : '–${s.dates.time(end)}'}'
          : '${s.dates.dayWithWeekday(item.dueAt, now: app.today)}, ${s.dates.time(item.dueAt)}${end == null ? '' : '–${s.dates.time(end)}'}';

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            0,
            AppSpacing.page,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  StatusPill(
                    label: s.plannerCategory(item.category),
                    icon: plannerIcon(item.category),
                  ),
                  StatusPill(
                    label: s.personal,
                    icon: Icons.lock_outline,
                    tone: PillTone.personal,
                  ),
                  StatusPill(
                    label: s.priorityLabel(item.priority),
                    icon: priorityIcon(item.priority),
                  ),
                  if (overdue)
                    StatusPill(
                      label: s.overdue,
                      icon: Icons.warning_amber_rounded,
                      tone: PillTone.overdue,
                    ),
                  if (item.isCompleted)
                    StatusPill(
                      label: s.statusDone,
                      icon: Icons.check,
                      tone: PillTone.done,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(item.title, style: theme.textTheme.titleLarge),
              if (item.course.isNotEmpty)
                Text(item.course, style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(when)),
                ],
              ),
              if (item.description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(item.description),
              ],
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  if (item.canBeCompleted)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          app.setPlannerCompleted(item.id, !item.isCompleted);
                          showSnack(
                            context,
                            item.isCompleted ? s.taskCompleted : s.taskReopened,
                          );
                        },
                        icon: Icon(
                          item.isCompleted ? Icons.check_circle : Icons.undo,
                        ),
                        label: Text(
                          item.isCompleted ? s.markIncomplete : s.markComplete,
                        ),
                      ),
                    ),
                  if (item.canBeCompleted) const SizedBox(width: AppSpacing.sm),
                  IconButton.outlined(
                    tooltip: s.edit,
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PlannerFormScreen(existing: item),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton.outlined(
                    tooltip: s.delete,
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      final ok = await confirmAction(
                        context,
                        title: s.deletePlannerTitle,
                        message: item.title,
                        confirmLabel: s.delete,
                        destructive: true,
                      );
                      if (ok) {
                        app.deletePlannerItem(item.id);
                        if (context.mounted) showSnack(context, s.deleted);
                      }
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

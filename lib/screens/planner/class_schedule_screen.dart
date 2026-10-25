import 'package:flutter/material.dart';

import '../../models/planner_item.dart';
import '../../services/calculations/planner_filters.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/app_scope.dart';
import '../../widgets/common/section_header.dart';
import 'planner_form_screen.dart';
import 'planner_tiles.dart';

class ClassScheduleScreen extends StatelessWidget {
  const ClassScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    final theme = Theme.of(context);
    final items = app.myPlannerItems;
    final hasSunday = weeklySchedule(items, DateTime.sunday).isNotEmpty;
    final days = [
      for (
        var d = DateTime.monday;
        d <= (hasSunday ? DateTime.sunday : DateTime.saturday);
        d++
      )
        d,
    ];

    return Scaffold(
      appBar: AppBar(title: Text(s.classSchedule)),
      floatingActionButton: FloatingActionButton(
        heroTag: 'schedule-fab',
        tooltip: s.add,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const PlannerFormScreen(
              initialCategory: PlannerCategory.classSession,
              initialWeekly: true,
            ),
          ),
        ),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.fabClearance),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.md,
              AppSpacing.page,
              0,
            ),
            child: Text(s.scheduleHint, style: theme.textTheme.bodySmall),
          ),
          for (final day in days) ...[
            SectionHeader(
              title: day == app.today.weekday
                  ? '${s.dates.weekdayName(day)} · ${s.today}'
                  : s.dates.weekdayName(day),
            ),
            if (weeklySchedule(items, day).isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.page,
                ),
                child: Text(
                  s.noClassesThisDay,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              for (final item in weeklySchedule(items, day))
                PlannerItemTile(item: item, day: app.today),
          ],
        ],
      ),
    );
  }
}

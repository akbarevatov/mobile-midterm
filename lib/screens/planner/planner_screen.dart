import 'package:flutter/material.dart';

import '../../models/planner_item.dart';
import '../../services/calculations/planner_filters.dart';
import '../../theme/app_spacing.dart';
import '../../utils/date_math.dart';
import '../../widgets/common/app_scope.dart';
import '../../widgets/common/category_icons.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/section_header.dart';
import 'class_schedule_screen.dart';
import 'planner_form_screen.dart';
import 'planner_tiles.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  Set<PlannerCategory> _categories = {};

  Future<void> _openFilter() async {
    final s = context.s;
    final result = await showModalBottomSheet<Set<PlannerCategory>>(
      context: context,
      builder: (sheetContext) {
        final selected = Set.of(_categories);
        return StatefulBuilder(
          builder: (context, setSheetState) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                0,
                AppSpacing.page,
                AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.filterByCategory,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final c in PlannerCategory.values)
                        FilterChip(
                          avatar: selected.contains(c)
                              ? null
                              : Icon(plannerIcon(c), size: 18),
                          label: Text(s.plannerCategory(c)),
                          selected: selected.contains(c),
                          onSelected: (v) => setSheetState(
                            () => v ? selected.add(c) : selected.remove(c),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(sheetContext, <PlannerCategory>{}),
                        child: Text(s.clearFilters),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () => Navigator.pop(sheetContext, selected),
                        child: Text(s.save),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (result != null) setState(() => _categories = result);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.plannerTitle),
          actions: [
            IconButton(
              tooltip: s.classSchedule,
              icon: const Icon(Icons.calendar_view_week_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ClassScheduleScreen()),
              ),
            ),
            IconButton(
              tooltip: s.filterByCategory,
              onPressed: _openFilter,
              icon: Badge(
                isLabelVisible: _categories.isNotEmpty,
                label: Text('${_categories.length}'),
                child: const Icon(Icons.filter_list),
              ),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: s.viewToday),
              Tab(text: s.viewUpcoming),
              Tab(text: s.viewAll),
              Tab(text: s.viewCompleted),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'planner-fab',
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const PlannerFormScreen())),
          icon: const Icon(Icons.add),
          label: Text(s.addTaskLabel),
        ),
        body: Column(
          children: [
            if (_categories.isNotEmpty)
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.page,
                    vertical: AppSpacing.xs,
                  ),
                  children: [
                    for (final c in _categories)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: InputChip(
                          label: Text(s.plannerCategory(c)),
                          onDeleted: () => setState(
                            () => _categories = Set.of(_categories)..remove(c),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            Expanded(
              child: TabBarView(
                children: [
                  _TodayView(categories: _categories),
                  _UpcomingView(categories: _categories),
                  _ListView(categories: _categories, completedOnly: false),
                  _ListView(categories: _categories, completedOnly: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.md,
        AppSpacing.page,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock_outline,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              context.s.plannerPrivacyNote,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayView extends StatelessWidget {
  const _TodayView({required this.categories});

  final Set<PlannerCategory> categories;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    final now = app.now();
    final today = app.today;
    final tomorrow = addDays(today, 1);
    final mine = filterByCategories(app.myPlannerItems, categories);
    final overdue = overdueBeforeToday(mine, now);
    final todayItems = itemsForDay(mine, today);
    final showShared = categories.isEmpty;
    final myChores = showShared
        ? app.pendingAssignments
              .where(
                (a) =>
                    a.assigneeMemberId == app.data.currentMemberId &&
                    a.dueDate.isBefore(tomorrow),
              )
              .toList()
        : const [];
    final events = showShared
        ? app.eventsChronological
              .where((e) => isSameDay(e.startAt, today))
              .toList()
        : const [];

    final isEmpty =
        overdue.isEmpty &&
        todayItems.isEmpty &&
        myChores.isEmpty &&
        events.isEmpty;

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.fabClearance),
      children: [
        const _PrivacyNote(),
        if (isEmpty)
          EmptyState(
            icon: Icons.wb_sunny_outlined,
            title: s.emptyToday,
            message: s.emptyPlannerHint,
            actionLabel: s.addTaskLabel,
            onAction: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PlannerFormScreen()),
            ),
          ),
        if (overdue.isNotEmpty) ...[
          SectionHeader(title: s.overdue),
          for (final item in overdue) PlannerItemTile(item: item),
        ],
        if (todayItems.isNotEmpty) ...[
          SectionHeader(title: s.dates.dayWithWeekday(today)),
          for (final item in todayItems)
            PlannerItemTile(item: item, day: today),
        ],
        if (myChores.isNotEmpty || events.isNotEmpty) ...[
          SectionHeader(title: s.householdToday),
          for (final a in myChores) SharedChoreTile(assignment: a),
          for (final e in events) SharedEventTile(event: e),
        ],
      ],
    );
  }
}

class _UpcomingView extends StatelessWidget {
  const _UpcomingView({required this.categories});

  final Set<PlannerCategory> categories;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    final now = app.now();
    final tomorrow = addDays(app.today, 1);
    final horizon = addDays(app.today, 14);
    final items = upcomingItems(
      filterByCategories(app.myPlannerItems, categories),
      now,
    );
    final showShared = categories.isEmpty;

    final entries = <(DateTime, Widget)>[
      for (final item in items) (item.dueAt, PlannerItemTile(item: item)),
      if (showShared)
        for (final e in app.eventsChronological.where(
          (e) => !e.startAt.isBefore(tomorrow) && e.startAt.isBefore(horizon),
        ))
          (e.startAt, SharedEventTile(event: e)),
      if (showShared)
        for (final a in app.pendingAssignments.where(
          (a) =>
              a.assigneeMemberId == app.data.currentMemberId &&
              !a.dueDate.isBefore(tomorrow) &&
              a.dueDate.isBefore(horizon),
        ))
          (a.dueDate, SharedChoreTile(assignment: a)),
    ]..sort((a, b) => a.$1.compareTo(b.$1));

    if (entries.isEmpty) {
      return ListView(
        children: [
          EmptyState(
            icon: Icons.event_available_outlined,
            title: s.emptyUpcoming,
            message: s.emptyPlannerHint,
          ),
        ],
      );
    }

    final children = <Widget>[];
    DateTime? currentDay;
    for (final (date, tile) in entries) {
      if (currentDay == null || !isSameDay(currentDay, date)) {
        currentDay = dateOnly(date);
        final rel = daysBetween(app.today, currentDay) <= 7
            ? '${s.dates.relativeDayCapitalized(currentDay, app.today)} · ${s.dates.dayWithWeekday(currentDay, now: app.today)}'
            : s.dates.dayWithWeekday(currentDay, now: app.today);
        children.add(SectionHeader(title: rel));
      }
      children.add(tile);
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.fabClearance),
      children: children,
    );
  }
}

class _ListView extends StatelessWidget {
  const _ListView({required this.categories, required this.completedOnly});

  final Set<PlannerCategory> categories;
  final bool completedOnly;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    final mine = filterByCategories(app.myPlannerItems, categories);
    final items = completedOnly
        ? completedItems(mine)
        : allItemsSorted(mine, app.now());
    if (items.isEmpty) {
      return ListView(
        children: [
          EmptyState(
            icon: completedOnly ? Icons.task_alt : Icons.inbox_outlined,
            title: completedOnly ? s.emptyCompleted : s.emptyAll,
            message: completedOnly ? null : s.emptyPlannerHint,
          ),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppSpacing.fabClearance),
      itemCount: items.length,
      itemBuilder: (context, index) => PlannerItemTile(item: items[index]),
    );
  }
}

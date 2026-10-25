import '../../models/planner_item.dart';
import '../../utils/date_math.dart';

bool occursOn(PlannerItem item, DateTime day) {
  if (!item.isRecurring) return isSameDay(item.dueAt, day);
  final start = dateOnly(item.dueAt);
  final date = dateOnly(day);
  return !date.isBefore(start) && date.weekday == item.dueAt.weekday;
}

DateTime occurrenceOn(PlannerItem item, DateTime day) =>
    withTime(day, item.dueAt.hour, item.dueAt.minute);

DateTime nextOccurrence(PlannerItem item, DateTime from) {
  if (!item.isRecurring) return item.dueAt;
  var day = dateOnly(from).isBefore(dateOnly(item.dueAt))
      ? dateOnly(item.dueAt)
      : dateOnly(from);
  while (day.weekday != item.dueAt.weekday) {
    day = addDays(day, 1);
  }
  return occurrenceOn(item, day);
}

bool isPlannerItemOverdue(PlannerItem item, DateTime now) =>
    !item.isRecurring && !item.isCompleted && item.dueAt.isBefore(now);

List<PlannerItem> filterByCategories(
  List<PlannerItem> items,
  Set<PlannerCategory> categories,
) {
  if (categories.isEmpty) return List.of(items);
  return items.where((i) => categories.contains(i.category)).toList();
}

List<PlannerItem> overdueBeforeToday(List<PlannerItem> items, DateTime now) {
  final todayStart = dateOnly(now);
  return items.where((i) => isPlannerItemOverdue(i, todayStart)).toList()
    ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
}

List<PlannerItem> itemsForDay(List<PlannerItem> items, DateTime day) {
  final result = items
      .where((i) => !i.isCompleted && occursOn(i, day))
      .toList();
  result.sort((a, b) => occurrenceOn(a, day).compareTo(occurrenceOn(b, day)));
  return result;
}

List<PlannerItem> upcomingItems(List<PlannerItem> items, DateTime now) {
  final tomorrow = addDays(dateOnly(now), 1);
  return items
      .where(
        (i) => !i.isRecurring && !i.isCompleted && !i.dueAt.isBefore(tomorrow),
      )
      .toList()
    ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
}

List<PlannerItem> completedItems(List<PlannerItem> items) {
  return items.where((i) => i.isCompleted).toList()..sort(
    (a, b) => (b.completedAt ?? b.dueAt).compareTo(a.completedAt ?? a.dueAt),
  );
}

List<PlannerItem> allItemsSorted(List<PlannerItem> items, DateTime now) {
  final active = items.where((i) => !i.isCompleted).toList()
    ..sort((a, b) => nextOccurrence(a, now).compareTo(nextOccurrence(b, now)));
  return [...active, ...completedItems(items)];
}

PlannerItem? nextAcademicDeadline(List<PlannerItem> items, DateTime now) {
  PlannerItem? best;
  for (final item in items) {
    if (item.isCompleted ||
        item.isRecurring ||
        !item.category.isAcademicDeadline) {
      continue;
    }
    if (item.dueAt.isBefore(now)) continue;
    if (best == null || item.dueAt.isBefore(best.dueAt)) best = item;
  }
  return best;
}

List<PlannerItem> weeklySchedule(List<PlannerItem> items, int weekday) {
  return items
      .where((i) => i.isRecurring && i.dueAt.weekday == weekday)
      .toList()
    ..sort((a, b) {
      final aMinutes = a.dueAt.hour * 60 + a.dueAt.minute;
      final bMinutes = b.dueAt.hour * 60 + b.dueAt.minute;
      return aMinutes.compareTo(bMinutes);
    });
}

import 'package:birga/models/planner_item.dart';
import 'package:birga/models/priority.dart';
import 'package:birga/services/calculations/planner_filters.dart';
import 'package:flutter_test/flutter_test.dart';

final now = DateTime(2026, 10, 22, 14, 0);

PlannerItem item(
  String id,
  DateTime due, {
  PlannerCategory category = PlannerCategory.assignment,
  bool completed = false,
  DateTime? completedAt,
  Recurrence recurrence = Recurrence.none,
}) => PlannerItem(
  id: id,
  ownerMemberId: 'aziz',
  title: id,
  category: category,
  dueAt: due,
  priority: Priority.medium,
  createdAt: DateTime(2026, 10, 1),
  recurrence: recurrence,
  isCompleted: completed,
  completedAt: completedAt,
);

void main() {
  final items = [
    item('overdue-report', DateTime(2026, 10, 21, 23, 59)),
    item('today-morning', DateTime(2026, 10, 22, 9, 0)),
    item('today-evening', DateTime(2026, 10, 22, 18, 0)),
    item(
      'tomorrow-lab',
      DateTime(2026, 10, 23, 18, 0),
      category: PlannerCategory.homework,
    ),
    item('exam', DateTime(2026, 10, 28, 10, 0), category: PlannerCategory.exam),
    item(
      'done-essay',
      DateTime(2026, 10, 21, 12, 0),
      completed: true,
      completedAt: DateTime(2026, 10, 21, 11),
    ),
    item(
      'library',
      DateTime(2026, 10, 24, 17, 0),
      category: PlannerCategory.personalTask,
    ),
    item(
      'mobile-class',
      DateTime(2026, 9, 3, 10, 30),
      category: PlannerCategory.classSession,
      recurrence: Recurrence.weekly,
    ),
  ];

  test('weekly classes occur on their weekday from the start date onwards', () {
    final cls = items.last;
    expect(occursOn(cls, DateTime(2026, 10, 22)), isTrue);
    expect(occursOn(cls, DateTime(2026, 10, 23)), isFalse);
    expect(occursOn(cls, DateTime(2026, 8, 27)), isFalse);
  });

  test('today shows items scheduled today including weekly classes, sorted by time', () {
    final today = itemsForDay(items, now);
    expect(today.map((i) => i.id), [
      'today-morning',
      'mobile-class',
      'today-evening',
    ]);
  });

  test('overdue only includes unfinished one-off items from earlier days', () {
    expect(overdueBeforeToday(items, now).map((i) => i.id), ['overdue-report']);
  });

  test(
    'upcoming starts tomorrow, is chronological and hides completed items',
    () {
      expect(upcomingItems(items, now).map((i) => i.id), [
        'tomorrow-lab',
        'library',
        'exam',
      ]);
    },
  );

  test('completed view lists most recently completed first', () {
    final completed = [
      ...items,
      item(
        'older',
        DateTime(2026, 10, 10),
        completed: true,
        completedAt: DateTime(2026, 10, 9),
      ),
    ];
    expect(completedItems(completed).map((i) => i.id), ['done-essay', 'older']);
  });

  test('a completed task no longer appears in active views', () {
    final lab = item('lab', DateTime(2026, 10, 23, 18));
    final list = [lab];
    expect(upcomingItems(list, now), hasLength(1));
    lab.isCompleted = true;
    lab.completedAt = now;
    expect(upcomingItems(list, now), isEmpty);
    expect(itemsForDay(list, DateTime(2026, 10, 23)), isEmpty);
    expect(completedItems(list), hasLength(1));
  });

  test(
    'category filter keeps only selected categories, empty set keeps all',
    () {
      expect(
        filterByCategories(items, {PlannerCategory.exam}).map((i) => i.id),
        ['exam'],
      );
      expect(filterByCategories(items, {}), hasLength(items.length));
    },
  );

  test('next academic deadline skips personal tasks, classes, completed and past items', () {
    expect(nextAcademicDeadline(items, now)!.id, 'today-evening');
    expect(
      nextAcademicDeadline(items, DateTime(2026, 10, 22, 19))!.id,
      'tomorrow-lab',
    );
  });

  test('next occurrence of a weekly class is computed from the given day', () {
    final cls = items.last;
    expect(
      nextOccurrence(cls, DateTime(2026, 10, 23)),
      DateTime(2026, 10, 29, 10, 30),
    );
    expect(
      nextOccurrence(cls, DateTime(2026, 10, 22)),
      DateTime(2026, 10, 22, 10, 30),
    );
  });

  test('weekly schedule groups recurring items by weekday', () {
    expect(weeklySchedule(items, DateTime.thursday).map((i) => i.id), [
      'mobile-class',
    ]);
    expect(weeklySchedule(items, DateTime.monday), isEmpty);
  });
}

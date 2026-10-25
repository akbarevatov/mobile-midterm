import 'package:birga/models/chore.dart';
import 'package:birga/models/priority.dart';
import 'package:birga/services/calculations/chore_rotation.dart';
import 'package:flutter_test/flutter_test.dart';

const all = ['aziz', 'madina', 'sardor', 'dilnoza'];
final start = DateTime(2026, 10, 5);

Chore chore(
  String id, {
  List<String> eligible = all,
  ChoreFrequency frequency = ChoreFrequency.weekly,
}) => Chore(
  id: id,
  householdId: 'h',
  title: id,
  frequency: frequency,
  eligibleMemberIds: List.of(eligible),
  priority: Priority.medium,
  createdAt: start,
  createdById: 'aziz',
);

ChoreAssignment done(String choreId, String member, DateTime due) =>
    ChoreAssignment(
      id: '$choreId-$member-${due.toIso8601String()}',
      choreId: choreId,
      assigneeMemberId: member,
      dueDate: due,
      createdAt: due,
      status: AssignmentStatus.completed,
      completedAt: due,
    );

ChoreAssignment pending(String choreId, String member, DateTime due) =>
    ChoreAssignment(
      id: '$choreId-$member-pending',
      choreId: choreId,
      assigneeMemberId: member,
      dueDate: due,
      createdAt: due,
    );

String next(Chore c, List<ChoreAssignment> history, {Set<String>? active}) =>
    decideNextAssignee(
      chore: c,
      allAssignments: history,
      activeMemberIds: active ?? all.toSet(),
    ).memberId!;

List<String> runRotation(
  Chore c,
  List<ChoreAssignment> history,
  int turns, {
  Set<String>? active,
}) {
  final picks = <String>[];
  var due = history.isEmpty ? start : history.last.dueDate;
  for (var i = 0; i < turns; i++) {
    due = due.add(const Duration(days: 7));
    final member = next(c, history, active: active);
    picks.add(member);
    history.add(done(c.id, member, due));
  }
  return picks;
}

void main() {
  test('a new chore with no history starts with the first eligible member', () {
    expect(next(chore('dishes'), []), 'aziz');
  });

  test('steady rotation visits everyone in order and repeats', () {
    final picks = runRotation(chore('dishes'), [], 8);
    expect(picks, [
      'aziz',
      'madina',
      'sardor',
      'dilnoza',
      'aziz',
      'madina',
      'sardor',
      'dilnoza',
    ]);
  });

  test('first turns of several new chores are spread across members by current workload', () {
    final assignments = <ChoreAssignment>[];
    final firsts = <String>[];
    for (final id in ['dishes', 'trash', 'floor', 'bathroom']) {
      final member = next(chore(id), assignments);
      firsts.add(member);
      assignments.add(pending(id, member, start));
    }
    expect(firsts.toSet().length, 4);
  });

  test('a member who covered an extra turn waits until others catch up', () {
    final c = chore('dishes');
    final history = [
      done('dishes', 'aziz', start),
      done('dishes', 'madina', start.add(const Duration(days: 7))),
      done('dishes', 'aziz', start.add(const Duration(days: 14))),
    ];
    final picks = runRotation(c, history, 3);
    expect(picks, ['sardor', 'dilnoza', 'madina']);
    expect(picks, isNot(contains('aziz')));
  });

  test('over a full window every member ends up with the same number of turns after a swap', () {
    final c = chore('dishes');
    final history = [
      done('dishes', 'aziz', start),
      done('dishes', 'madina', start.add(const Duration(days: 7))),
      done('dishes', 'aziz', start.add(const Duration(days: 14))),
    ];
    runRotation(c, history, 5);
    final counts = <String, int>{};
    for (final a in history) {
      counts[a.assigneeMemberId] = (counts[a.assigneeMemberId] ?? 0) + 1;
    }
    expect(counts.values.toSet(), {2});
  });

  test('skipped assignments do not count as a turn', () {
    final history = [
      done('dishes', 'aziz', start),
      done('dishes', 'madina', start.add(const Duration(days: 7))),
      ChoreAssignment(
        id: 'skip',
        choreId: 'dishes',
        assigneeMemberId: 'sardor',
        dueDate: start.add(const Duration(days: 14)),
        createdAt: start,
        status: AssignmentStatus.skipped,
        skipReason: 'Viloyatga ketgan',
      ),
    ];
    expect(next(chore('dishes'), history), 'sardor');
  });

  test('inactive and ineligible members are never picked', () {
    final c = chore('trash', eligible: ['aziz', 'madina', 'sardor']);
    final picks = runRotation(c, [], 6, active: {'aziz', 'sardor', 'dilnoza'});
    expect(picks.toSet(), {'aziz', 'sardor'});
  });

  test('returns no assignee when nobody is eligible', () {
    final decision = decideNextAssignee(
      chore: chore('x', eligible: ['madina']),
      allAssignments: [],
      activeMemberIds: {'aziz'},
    );
    expect(decision.memberId, isNull);
  });

  test('a newly added member catches up within the window and then rotates normally', () {
    final c = chore('dishes');
    final history = <ChoreAssignment>[];
    runRotation(c, history, 8);
    c.eligibleMemberIds.add('jasur');
    final picks = runRotation(c, history, 7, active: {...all, 'jasur'});
    expect(picks.take(2), ['jasur', 'jasur']);
    expect(picks.skip(2).toSet().length, 5);
  });

  test('decision is deterministic for the same history', () {
    final history = [done('dishes', 'dilnoza', start)];
    expect(next(chore('dishes'), history), next(chore('dishes'), history));
  });

  group('due dates', () {
    test('next due date steps by frequency', () {
      final today = DateTime(2026, 10, 1);
      expect(
        nextDueDate(DateTime(2026, 10, 1), ChoreFrequency.daily, today),
        DateTime(2026, 10, 2),
      );
      expect(
        nextDueDate(DateTime(2026, 10, 1), ChoreFrequency.everyOtherDay, today),
        DateTime(2026, 10, 3),
      );
      expect(
        nextDueDate(DateTime(2026, 10, 1), ChoreFrequency.weekly, today),
        DateTime(2026, 10, 8),
      );
      expect(
        nextDueDate(DateTime(2026, 10, 1), ChoreFrequency.biweekly, today),
        DateTime(2026, 10, 15),
      );
      expect(
        nextDueDate(
          DateTime(2026, 1, 31),
          ChoreFrequency.monthly,
          DateTime(2026, 1, 31),
        ),
        DateTime(2026, 2, 28),
      );
      expect(
        nextDueDate(DateTime(2026, 10, 1), ChoreFrequency.once, today),
        isNull,
      );
    });

    test('completing a late chore does not create an already-overdue one', () {
      final today = DateTime(2026, 10, 22);
      final next = nextDueDate(
        DateTime(2026, 10, 1),
        ChoreFrequency.weekly,
        today,
      )!;
      expect(next, DateTime(2026, 10, 22));
      expect(next.isBefore(today), isFalse);
    });
  });

  test('projection shows the current turn then the predicted rotation', () {
    final c = chore('floor');
    final history = [
      done('floor', 'aziz', start),
      done('floor', 'madina', start.add(const Duration(days: 7))),
      pending('floor', 'sardor', start.add(const Duration(days: 14))),
    ];
    final turns = projectUpcomingTurns(
      chore: c,
      allAssignments: history,
      activeMemberIds: all.toSet(),
      today: start.add(const Duration(days: 14)),
    );
    expect(turns.map((t) => t.memberId), [
      'sardor',
      'dilnoza',
      'aziz',
      'madina',
    ]);
    expect(turns.first.isCurrent, isTrue);
    expect(turns[1].dueDate, start.add(const Duration(days: 21)));
    expect(
      history.where((a) => a.isPending).length,
      1,
      reason: 'projection must not mutate input',
    );
  });

  test(
    'weekly load counts assigned, completed, pending and overdue per member',
    () {
      final today = DateTime(2026, 10, 22);
      final assignments = [
        done('dishes', 'aziz', DateTime(2026, 10, 20)),
        pending('dishes', 'madina', DateTime(2026, 10, 21)),
        pending('floor', 'madina', DateTime(2026, 10, 24)),
        done('floor', 'sardor', DateTime(2026, 10, 10)),
      ];
      final loads = choreLoadByMember(
        memberIds: all,
        assignments: assignments,
        today: today,
      );
      final madina = loads.firstWhere((l) => l.memberId == 'madina');
      expect(madina.assignedThisWeek, 2);
      expect(madina.pending, 2);
      expect(madina.overdue, 1);
      final aziz = loads.firstWhere((l) => l.memberId == 'aziz');
      expect(aziz.completedThisWeek, 1);
      final sardor = loads.firstWhere((l) => l.memberId == 'sardor');
      expect(sardor.assignedThisWeek, 0);
    },
  );
}

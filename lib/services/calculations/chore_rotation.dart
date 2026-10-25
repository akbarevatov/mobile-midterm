import '../../models/chore.dart';
import '../../utils/date_math.dart';

class RotationCandidate {
  const RotationCandidate({
    required this.memberId,
    required this.orderIndex,
    required this.recentTurns,
    required this.lastTurnDate,
    required this.openAssignments,
  });

  final String memberId;
  final int orderIndex;
  final int recentTurns;
  final DateTime? lastTurnDate;
  final int openAssignments;
}

class RotationDecision {
  const RotationDecision({
    required this.memberId,
    required this.ranking,
    required this.windowSize,
  });

  final String? memberId;
  final List<RotationCandidate> ranking;
  final int windowSize;
}

class ProjectedTurn {
  const ProjectedTurn({
    required this.dueDate,
    required this.memberId,
    required this.isCurrent,
  });

  final DateTime dueDate;
  final String memberId;
  final bool isCurrent;
}

const int rotationWindowRounds = 2;

RotationDecision decideNextAssignee({
  required Chore chore,
  required List<ChoreAssignment> allAssignments,
  required Set<String> activeMemberIds,
}) {
  final eligible = chore.eligibleMemberIds
      .where(activeMemberIds.contains)
      .toList();
  final windowSize = eligible.length * rotationWindowRounds;
  if (eligible.isEmpty) {
    return const RotationDecision(memberId: null, ranking: [], windowSize: 0);
  }

  final done =
      allAssignments
          .where(
            (a) =>
                a.choreId == chore.id && a.status == AssignmentStatus.completed,
          )
          .toList()
        ..sort((a, b) {
          final byDue = b.dueDate.compareTo(a.dueDate);
          return byDue != 0 ? byDue : b.createdAt.compareTo(a.createdAt);
        });
  final window = done.take(windowSize).toList();

  final candidates = <RotationCandidate>[];
  for (var i = 0; i < eligible.length; i++) {
    final memberId = eligible[i];
    DateTime? lastTurn;
    for (final a in done) {
      if (a.assigneeMemberId == memberId) {
        lastTurn = a.dueDate;
        break;
      }
    }
    candidates.add(
      RotationCandidate(
        memberId: memberId,
        orderIndex: i,
        recentTurns: window.where((a) => a.assigneeMemberId == memberId).length,
        lastTurnDate: lastTurn,
        openAssignments: allAssignments
            .where((a) => a.isPending && a.assigneeMemberId == memberId)
            .length,
      ),
    );
  }

  candidates.sort(compareCandidates);
  return RotationDecision(
    memberId: candidates.first.memberId,
    ranking: candidates,
    windowSize: windowSize,
  );
}

int compareCandidates(RotationCandidate a, RotationCandidate b) {
  final byTurns = a.recentTurns.compareTo(b.recentTurns);
  if (byTurns != 0) return byTurns;

  final aLast = a.lastTurnDate;
  final bLast = b.lastTurnDate;
  if (aLast == null && bLast != null) return -1;
  if (aLast != null && bLast == null) return 1;
  if (aLast != null && bLast != null) {
    final byLast = aLast.compareTo(bLast);
    if (byLast != 0) return byLast;
  }

  final byLoad = a.openAssignments.compareTo(b.openAssignments);
  if (byLoad != 0) return byLoad;

  return a.orderIndex.compareTo(b.orderIndex);
}

DateTime stepDate(DateTime date, ChoreFrequency frequency) =>
    switch (frequency) {
      ChoreFrequency.once => date,
      ChoreFrequency.daily => addDays(date, 1),
      ChoreFrequency.everyOtherDay => addDays(date, 2),
      ChoreFrequency.weekly => addDays(date, 7),
      ChoreFrequency.biweekly => addDays(date, 14),
      ChoreFrequency.monthly => addMonths(date, 1),
    };

DateTime? nextDueDate(
  DateTime previousDue,
  ChoreFrequency frequency,
  DateTime today,
) {
  if (frequency == ChoreFrequency.once) return null;
  var next = stepDate(dateOnly(previousDue), frequency);
  final todayDate = dateOnly(today);
  while (next.isBefore(todayDate)) {
    next = stepDate(next, frequency);
  }
  return next;
}

List<ProjectedTurn> projectUpcomingTurns({
  required Chore chore,
  required List<ChoreAssignment> allAssignments,
  required Set<String> activeMemberIds,
  required DateTime today,
  int count = 4,
}) {
  final simulated = allAssignments.map(_copy).toList();
  final pending =
      simulated.where((a) => a.choreId == chore.id && a.isPending).toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  if (pending.isEmpty) return [];

  final current = pending.first;
  final turns = [
    ProjectedTurn(
      dueDate: current.dueDate,
      memberId: current.assigneeMemberId,
      isCurrent: true,
    ),
  ];
  current.status = AssignmentStatus.completed;
  var due = current.dueDate;

  while (turns.length < count && chore.isRecurring) {
    final next = nextDueDate(due, chore.frequency, today);
    if (next == null) break;
    due = next;
    final decision = decideNextAssignee(
      chore: chore,
      allAssignments: simulated,
      activeMemberIds: activeMemberIds,
    );
    final memberId = decision.memberId;
    if (memberId == null) break;
    turns.add(
      ProjectedTurn(dueDate: due, memberId: memberId, isCurrent: false),
    );
    simulated.add(
      ChoreAssignment(
        id: 'projection-${turns.length}',
        choreId: chore.id,
        assigneeMemberId: memberId,
        dueDate: due,
        createdAt: due,
        status: AssignmentStatus.completed,
      ),
    );
  }
  return turns;
}

ChoreAssignment _copy(ChoreAssignment a) => ChoreAssignment(
  id: a.id,
  choreId: a.choreId,
  assigneeMemberId: a.assigneeMemberId,
  dueDate: a.dueDate,
  createdAt: a.createdAt,
  status: a.status,
  completedAt: a.completedAt,
  skipReason: a.skipReason,
);

class MemberChoreLoad {
  MemberChoreLoad(this.memberId);

  final String memberId;
  int assignedThisWeek = 0;
  int completedThisWeek = 0;
  int pending = 0;
  int overdue = 0;
}

List<MemberChoreLoad> choreLoadByMember({
  required List<String> memberIds,
  required List<ChoreAssignment> assignments,
  required DateTime today,
}) {
  final weekStart = startOfWeek(today);
  final weekEnd = addDays(weekStart, 7);
  bool inWeek(DateTime d) => !d.isBefore(weekStart) && d.isBefore(weekEnd);

  final loads = {for (final id in memberIds) id: MemberChoreLoad(id)};
  for (final a in assignments) {
    final load = loads[a.assigneeMemberId];
    if (load == null) continue;
    if (a.status != AssignmentStatus.skipped && inWeek(a.dueDate)) {
      load.assignedThisWeek++;
    }
    if (a.status == AssignmentStatus.completed &&
        a.completedAt != null &&
        inWeek(a.completedAt!)) {
      load.completedThisWeek++;
    }
    if (a.isPending) {
      load.pending++;
      if (a.isOverdue(dateOnly(today))) load.overdue++;
    }
  }
  return memberIds.map((id) => loads[id]!).toList();
}

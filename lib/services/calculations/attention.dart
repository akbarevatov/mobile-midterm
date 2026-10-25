import '../../models/app_data.dart';
import '../../utils/date_math.dart';
import 'bill_schedule.dart';
import 'planner_filters.dart';

enum AttentionKind {
  choreOverdue,
  billOverdue,
  taskOverdue,
  choreToday,
  billDueSoon,
  taskToday,
}

class AttentionItem {
  const AttentionItem({
    required this.kind,
    required this.refId,
    required this.title,
    required this.date,
    this.amountUzs,
  });

  final AttentionKind kind;
  final String refId;
  final String title;
  final DateTime date;
  final int? amountUzs;

  bool get isOverdue =>
      kind == AttentionKind.choreOverdue ||
      kind == AttentionKind.billOverdue ||
      kind == AttentionKind.taskOverdue;
}

List<AttentionItem> buildAttention({
  required AppData data,
  required String memberId,
  required DateTime now,
}) {
  final today = dateOnly(now);
  final tomorrow = addDays(today, 1);
  final items = <AttentionItem>[];

  for (final a in data.assignments) {
    if (!a.isPending || a.assigneeMemberId != memberId) continue;
    final chore = data.chores.where((c) => c.id == a.choreId).firstOrNull;
    if (chore == null || !chore.isActive) continue;
    if (a.dueDate.isBefore(today)) {
      items.add(
        AttentionItem(
          kind: AttentionKind.choreOverdue,
          refId: a.id,
          title: chore.title,
          date: a.dueDate,
        ),
      );
    } else if (a.dueDate.isBefore(tomorrow)) {
      items.add(
        AttentionItem(
          kind: AttentionKind.choreToday,
          refId: a.id,
          title: chore.title,
          date: a.dueDate,
        ),
      );
    }
  }

  for (final overview in billOverviews(data.bills, data.expenses, today)) {
    final due = overview.currentDue;
    if (due == null) continue;
    if (overview.status == BillStatus.overdue) {
      items.add(
        AttentionItem(
          kind: AttentionKind.billOverdue,
          refId: overview.bill.id,
          title: overview.bill.name,
          date: due,
          amountUzs: overview.bill.expectedAmountUzs,
        ),
      );
    } else if (overview.status == BillStatus.dueSoon) {
      items.add(
        AttentionItem(
          kind: AttentionKind.billDueSoon,
          refId: overview.bill.id,
          title: overview.bill.name,
          date: due,
          amountUzs: overview.bill.expectedAmountUzs,
        ),
      );
    }
  }

  final mine = data.plannerItems
      .where((p) => p.ownerMemberId == memberId)
      .toList();
  for (final item in mine) {
    if (item.isRecurring || item.isCompleted) continue;
    if (isPlannerItemOverdue(item, now)) {
      items.add(
        AttentionItem(
          kind: AttentionKind.taskOverdue,
          refId: item.id,
          title: item.title,
          date: item.dueAt,
        ),
      );
    } else if (item.dueAt.isBefore(tomorrow)) {
      items.add(
        AttentionItem(
          kind: AttentionKind.taskToday,
          refId: item.id,
          title: item.title,
          date: item.dueAt,
        ),
      );
    }
  }

  items.sort((a, b) {
    final bySeverity = a.kind.index.compareTo(b.kind.index);
    if (a.isOverdue != b.isOverdue) return a.isOverdue ? -1 : 1;
    final byDate = a.date.compareTo(b.date);
    return byDate != 0 ? byDate : bySeverity;
  });
  return items;
}

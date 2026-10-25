import '../../models/expense.dart';
import '../../models/household_bill.dart';
import '../../utils/date_math.dart';

enum BillStatus { overdue, dueSoon, upcoming, settled }

const int billDueSoonDays = 3;
const int _maxPeriods = 600;

class BillOverview {
  const BillOverview({
    required this.bill,
    required this.currentDue,
    required this.status,
    required this.lastPayment,
  });

  final HouseholdBill bill;
  final DateTime? currentDue;
  final BillStatus status;
  final Expense? lastPayment;
}

DateTime billPeriodDate(HouseholdBill bill, int index) =>
    switch (bill.frequency) {
      BillFrequency.once => bill.firstDueDate,
      BillFrequency.monthly => addMonths(bill.firstDueDate, index),
      BillFrequency.quarterly => addMonths(bill.firstDueDate, index * 3),
    };

List<Expense> billPayments(HouseholdBill bill, List<Expense> expenses) {
  return expenses
      .where((e) => e.billId == bill.id && e.billPeriod != null)
      .toList()
    ..sort((a, b) => b.billPeriod!.compareTo(a.billPeriod!));
}

Set<DateTime> paidPeriods(HouseholdBill bill, List<Expense> expenses) =>
    billPayments(bill, expenses).map((e) => dateOnly(e.billPeriod!)).toSet();

DateTime? currentDueDate(HouseholdBill bill, List<Expense> expenses) {
  final paid = paidPeriods(bill, expenses);
  if (bill.frequency == BillFrequency.once) {
    return paid.contains(dateOnly(bill.firstDueDate))
        ? null
        : bill.firstDueDate;
  }
  for (var i = 0; i < _maxPeriods; i++) {
    final period = billPeriodDate(bill, i);
    if (!paid.contains(dateOnly(period))) return period;
  }
  return null;
}

BillStatus billStatus(DateTime? due, DateTime today) {
  if (due == null) return BillStatus.settled;
  final days = daysBetween(today, due);
  if (days < 0) return BillStatus.overdue;
  if (days <= billDueSoonDays) return BillStatus.dueSoon;
  return BillStatus.upcoming;
}

BillOverview overviewOf(
  HouseholdBill bill,
  List<Expense> expenses,
  DateTime today,
) {
  final due = currentDueDate(bill, expenses);
  final payments = billPayments(bill, expenses);
  return BillOverview(
    bill: bill,
    currentDue: due,
    status: billStatus(due, today),
    lastPayment: payments.isEmpty ? null : payments.first,
  );
}

List<BillOverview> billOverviews(
  List<HouseholdBill> bills,
  List<Expense> expenses,
  DateTime today,
) {
  final overviews = bills
      .where((b) => b.isActive)
      .map((b) => overviewOf(b, expenses, today))
      .toList();
  overviews.sort((a, b) {
    if (a.currentDue == null && b.currentDue == null) {
      return a.bill.name.compareTo(b.bill.name);
    }
    if (a.currentDue == null) return 1;
    if (b.currentDue == null) return -1;
    return a.currentDue!.compareTo(b.currentDue!);
  });
  return overviews;
}

int expectedForMonth(List<HouseholdBill> bills, DateTime month) {
  final start = startOfMonth(month);
  final end = addMonths(start, 1);
  var total = 0;
  for (final bill in bills.where((b) => b.isActive)) {
    for (var i = 0; i < _maxPeriods; i++) {
      final period = billPeriodDate(bill, i);
      if (!period.isBefore(end)) break;
      if (!period.isBefore(start)) total += bill.expectedAmountUzs;
      if (bill.frequency == BillFrequency.once) break;
    }
  }
  return total;
}

int paidForMonth(
  List<HouseholdBill> bills,
  List<Expense> expenses,
  DateTime month,
) {
  final start = startOfMonth(month);
  final end = addMonths(start, 1);
  final billIds = bills.map((b) => b.id).toSet();
  var total = 0;
  for (final e in expenses) {
    if (e.billId == null ||
        e.billPeriod == null ||
        !billIds.contains(e.billId)) {
      continue;
    }
    if (!e.billPeriod!.isBefore(start) && e.billPeriod!.isBefore(end)) {
      total += e.amountUzs;
    }
  }
  return total;
}

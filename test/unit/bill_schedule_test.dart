import 'package:birga/models/expense.dart';
import 'package:birga/models/household_bill.dart';
import 'package:birga/services/calculations/bill_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

HouseholdBill bill({
  String id = 'internet',
  BillFrequency frequency = BillFrequency.monthly,
  DateTime? first,
  int amount = 160000,
}) => HouseholdBill(
  id: id,
  householdId: 'h',
  name: id,
  type: BillType.internet,
  expectedAmountUzs: amount,
  firstDueDate: first ?? DateTime(2026, 8, 25),
  frequency: frequency,
  responsibleMemberId: 'madina',
  participantMemberIds: const ['aziz', 'madina'],
  createdAt: DateTime(2026, 8, 1),
);

Expense paymentFor(HouseholdBill b, DateTime period, {int amount = 160000}) =>
    Expense(
      id: 'pay-${period.month}',
      householdId: 'h',
      title: b.name,
      amountUzs: amount,
      payerMemberId: 'madina',
      splitAmountsByMemberId: {
        'aziz': amount ~/ 2,
        'madina': amount - amount ~/ 2,
      },
      splitMode: SplitMode.equal,
      category: ExpenseCategory.internet,
      date: period,
      createdAt: period,
      createdById: 'madina',
      billId: b.id,
      billPeriod: period,
    );

void main() {
  final today = DateTime(2026, 10, 22);

  test('the current due date is the first unpaid period', () {
    final b = bill();
    final payments = [
      paymentFor(b, DateTime(2026, 8, 25)),
      paymentFor(b, DateTime(2026, 9, 25)),
    ];
    expect(currentDueDate(b, payments), DateTime(2026, 10, 25));
    expect(billStatus(currentDueDate(b, payments), today), BillStatus.dueSoon);
  });

  test('a skipped month stays due and becomes overdue', () {
    final b = bill();
    final payments = [
      paymentFor(b, DateTime(2026, 8, 25)),
      paymentFor(b, DateTime(2026, 10, 25)),
    ];
    expect(currentDueDate(b, payments), DateTime(2026, 9, 25));
    expect(billStatus(DateTime(2026, 9, 25), today), BillStatus.overdue);
  });

  test('deleting the payment expense re-opens that period, so nothing is counted twice', () {
    final b = bill();
    final payments = [
      paymentFor(b, DateTime(2026, 8, 25)),
      paymentFor(b, DateTime(2026, 9, 25)),
    ];
    payments.removeLast();
    expect(currentDueDate(b, payments), DateTime(2026, 9, 25));
  });

  test('one-time bills are settled after a single payment', () {
    final b = bill(
      frequency: BillFrequency.once,
      first: DateTime(2026, 10, 30),
    );
    expect(currentDueDate(b, []), DateTime(2026, 10, 30));
    expect(currentDueDate(b, [paymentFor(b, DateTime(2026, 10, 30))]), isNull);
    expect(billStatus(null, today), BillStatus.settled);
  });

  test(
    'monthly periods anchored on the 31st clamp to the end of shorter months',
    () {
      final b = bill(first: DateTime(2026, 1, 31));
      expect(billPeriodDate(b, 1), DateTime(2026, 2, 28));
      expect(billPeriodDate(b, 2), DateTime(2026, 3, 31));
    },
  );

  test('quarterly bills step by three months', () {
    final b = bill(
      frequency: BillFrequency.quarterly,
      first: DateTime(2026, 1, 10),
    );
    expect(billPeriodDate(b, 3), DateTime(2026, 10, 10));
  });

  test('status thresholds: overdue, due soon (3 days), upcoming', () {
    expect(billStatus(DateTime(2026, 10, 21), today), BillStatus.overdue);
    expect(billStatus(DateTime(2026, 10, 22), today), BillStatus.dueSoon);
    expect(billStatus(DateTime(2026, 10, 25), today), BillStatus.dueSoon);
    expect(billStatus(DateTime(2026, 10, 26), today), BillStatus.upcoming);
  });

  test('monthly summary adds expected amounts and paid bill expenses', () {
    final internet = bill();
    final rent = bill(
      id: 'rent',
      amount: 6000000,
      first: DateTime(2026, 10, 1),
    );
    final quarterly = bill(
      id: 'q',
      amount: 90000,
      frequency: BillFrequency.quarterly,
      first: DateTime(2026, 9, 5),
    );
    final bills = [internet, rent, quarterly];
    expect(expectedForMonth(bills, today), 160000 + 6000000);
    expect(
      expectedForMonth(bills, DateTime(2026, 12, 1)),
      160000 + 6000000 + 90000,
    );

    final payments = [
      paymentFor(internet, DateTime(2026, 10, 25), amount: 150000),
    ];
    expect(paidForMonth(bills, payments, today), 150000);
  });

  test('overviews list overdue first and settled bills last', () {
    final a = bill(id: 'a', first: DateTime(2026, 10, 30));
    final b = bill(id: 'b', first: DateTime(2026, 10, 20));
    final c = bill(
      id: 'c',
      frequency: BillFrequency.once,
      first: DateTime(2026, 10, 1),
    );
    final overviews = billOverviews(
      [a, b, c],
      [paymentFor(c, DateTime(2026, 10, 1))],
      today,
    );
    expect(overviews.map((o) => o.bill.id), ['b', 'a', 'c']);
    expect(overviews.first.status, BillStatus.overdue);
    expect(overviews.last.status, BillStatus.settled);
  });
}

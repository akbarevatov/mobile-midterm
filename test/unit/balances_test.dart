import 'dart:math';

import 'package:birga/models/expense.dart';
import 'package:birga/models/settlement.dart';
import 'package:birga/services/calculations/balances.dart';
import 'package:birga/services/calculations/money_split.dart';
import 'package:flutter_test/flutter_test.dart';

const members = ['aziz', 'madina', 'sardor', 'dilnoza'];
final day = DateTime(2026, 10, 20);

Expense expense(
  String payer,
  int amount,
  Map<String, int> shares, {
  DateTime? date,
}) => Expense(
  id: 'e$payer$amount${shares.length}',
  householdId: 'h',
  title: 'test',
  amountUzs: amount,
  payerMemberId: payer,
  splitAmountsByMemberId: shares,
  splitMode: SplitMode.custom,
  category: ExpenseCategory.groceries,
  date: date ?? day,
  createdAt: day,
  createdById: payer,
);

Settlement payment(String from, String to, int amount) => Settlement(
  id: 's$from$to$amount',
  householdId: 'h',
  fromMemberId: from,
  toMemberId: to,
  amountUzs: amount,
  method: PaymentMethod.cash,
  date: day,
  createdAt: day,
  recordedById: from,
);

Map<String, int> nets(Map<String, MemberBalance> balances) =>
    balances.map((id, b) => MapEntry(id, b.net));

void main() {
  test('payer is owed only the other roommates\' shares, not their own', () {
    final balances = computeBalances(
      memberIds: members,
      expenses: [expense('aziz', 120000, splitEqually(120000, members))],
      settlements: [],
    );
    expect(balances['aziz']!.net, 90000);
    expect(balances['madina']!.net, -30000);
    expect(balances['sardor']!.net, -30000);
    expect(balances['dilnoza']!.net, -30000);
    expect(balances['aziz']!.paidForExpenses, 120000);
    expect(balances['aziz']!.shareOfExpenses, 30000);
  });

  test('payer who did not participate is owed the full amount', () {
    final balances = computeBalances(
      memberIds: members,
      expenses: [
        expense('sardor', 50000, {'madina': 25000, 'dilnoza': 25000}),
      ],
      settlements: [],
    );
    expect(balances['sardor']!.net, 50000);
    expect(balances['aziz']!.net, 0);
  });

  test('recorded payments reduce debts in both directions', () {
    final balances = computeBalances(
      memberIds: members,
      expenses: [expense('aziz', 120000, splitEqually(120000, members))],
      settlements: [payment('madina', 'aziz', 30000)],
    );
    expect(balances['madina']!.net, 0);
    expect(balances['aziz']!.net, 60000);
  });

  test('net balances always sum to zero', () {
    final random = Random(7);
    final expenses = <Expense>[];
    for (var i = 0; i < 50; i++) {
      final participants = members.where((_) => random.nextBool()).toList();
      if (participants.isEmpty) participants.add(members[i % 4]);
      final amount = 1000 + random.nextInt(500000);
      expenses.add(
        expense(
          members[random.nextInt(4)],
          amount,
          splitEqually(amount, participants),
        ),
      );
    }
    final balances = computeBalances(
      memberIds: members,
      expenses: expenses,
      settlements: [payment('sardor', 'aziz', 12345)],
    );
    expect(nets(balances).values.reduce((a, b) => a + b), 0);
  });

  group('suggestSettlements', () {
    test('settles everyone with at most n-1 transfers and keeps nets', () {
      final random = Random(42);
      for (var round = 0; round < 30; round++) {
        final expenses = <Expense>[];
        for (var i = 0; i < 12; i++) {
          final amount = 1000 + random.nextInt(300000);
          expenses.add(
            expense(
              members[random.nextInt(4)],
              amount,
              splitEqually(amount, members),
            ),
          );
        }
        final netMap = nets(
          computeBalances(
            memberIds: members,
            expenses: expenses,
            settlements: [],
          ),
        );
        final transfers = suggestSettlements(netMap, members);

        expect(transfers.length, lessThanOrEqualTo(members.length - 1));
        final after = Map.of(netMap);
        for (final t in transfers) {
          expect(t.amountUzs, greaterThan(0));
          after[t.fromMemberId] = after[t.fromMemberId]! + t.amountUzs;
          after[t.toMemberId] = after[t.toMemberId]! - t.amountUzs;
        }
        expect(after.values.every((v) => v == 0), isTrue);
      }
    });

    test('simplifies a chain of debts into one transfer', () {
      final transfers = suggestSettlements(
        {'a': -10000, 'b': 0, 'c': 10000},
        ['a', 'b', 'c'],
      );
      expect(transfers.length, 1);
      expect(transfers.single.fromMemberId, 'a');
      expect(transfers.single.toMemberId, 'c');
      expect(transfers.single.amountUzs, 10000);
    });

    test('nothing to suggest when everyone is even', () {
      expect(suggestSettlements({'a': 0, 'b': 0}, ['a', 'b']), isEmpty);
    });
  });

  test('total spending excludes settlements and respects the date range', () {
    final expenses = [
      expense('aziz', 100000, {'aziz': 100000}, date: DateTime(2026, 9, 30)),
      expense('aziz', 40000, {'aziz': 40000}, date: DateTime(2026, 10, 1)),
      expense('madina', 60000, {
        'aziz': 30000,
        'madina': 30000,
      }, date: DateTime(2026, 10, 31, 23)),
    ];
    expect(totalSpending(expenses), 200000);
    expect(
      totalSpending(expenses, from: DateTime(2026, 10), to: DateTime(2026, 11)),
      100000,
    );
    expect(
      shareSpending(
        expenses,
        'aziz',
        from: DateTime(2026, 10),
        to: DateTime(2026, 11),
      ),
      70000,
    );
  });
}

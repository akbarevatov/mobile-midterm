import 'dart:convert';

import 'package:birga/l10n/app_language.dart';
import 'package:birga/models/chore.dart';
import 'package:birga/models/expense.dart';
import 'package:birga/models/planner_item.dart';
import 'package:birga/models/priority.dart';
import 'package:birga/models/shopping_item.dart';
import 'package:birga/services/calculations/bill_schedule.dart';
import 'package:birga/services/calculations/chore_rotation.dart';
import 'package:birga/services/calculations/money_split.dart';
import 'package:birga/services/local_storage/key_value_store.dart';
import 'package:birga/services/repositories/app_repository.dart';
import 'package:birga/state/app_state.dart';
import 'package:birga/utils/date_math.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final fixedNow = DateTime(2026, 10, 22, 10, 0);

Future<AppState> demoState({MemoryStore? store}) async {
  final state = AppState(
    repository: AppRepository(store ?? MemoryStore()),
    clock: () => fixedNow,
  );
  await state.load();
  state.startDemo();
  await state.flushSaves();
  return state;
}

Expense simpleExpense(
  AppState app, {
  int amount = 100000,
  String? id,
  String? billId,
  DateTime? billPeriod,
}) {
  final members = app.activeMembers.map((m) => m.id).toList();
  return Expense(
    id: id ?? 'test-${DateTime.now().microsecondsSinceEpoch}',
    householdId: app.data.household.id,
    title: 'Test',
    amountUzs: amount,
    payerMemberId: members.first,
    splitAmountsByMemberId: splitEqually(amount, members),
    splitMode: SplitMode.equal,
    category: ExpenseCategory.groceries,
    date: fixedNow,
    createdAt: fixedNow,
    createdById: members.first,
    billId: billId,
    billPeriod: billPeriod,
  );
}

void main() {
  group('demo data', () {
    test('has four fictional roommates and balanced books', () async {
      final app = await demoState();
      expect(app.members.map((m) => m.displayName), [
        'Aziz',
        'Madina',
        'Sardor',
        'Dilnoza',
      ]);
      expect(app.currentMember.displayName, 'Aziz');
      final total = app.balances.values.fold<int>(0, (sum, b) => sum + b.net);
      expect(total, 0);
    });

    test('shows the scenarios the home screen relies on', () async {
      final app = await demoState();
      final overviews = {for (final o in app.billOverviewList) o.bill.id: o};
      expect(overviews['demo-internet']!.currentDue, DateTime(2026, 10, 25));
      expect(overviews['demo-electricity']!.status, BillStatus.overdue);
      final dishes = app.currentAssignmentFor('demo-dishes')!;
      expect(dishes.assigneeMemberId, 'demo-aziz');
      expect(dishes.dueDate, DateTime(2026, 10, 22));
      expect(
        app.currentAssignmentFor('demo-bathroom')!.isOverdue(app.today),
        isTrue,
      );
    });

    test(
      'every untouched current assignment matches the rotation rules',
      () async {
        final app = await demoState();
        for (final chore in app.activeChores) {
          final current = app.currentAssignmentFor(chore.id)!;
          if (current.changes.isNotEmpty) continue;
          final history = app.data.assignments
              .where((a) => a.id != current.id)
              .toList();
          final decision = decideNextAssignee(
            chore: chore,
            allAssignments: history,
            activeMemberIds: app.activeMemberIds,
          );
          expect(
            current.assigneeMemberId,
            decision.memberId,
            reason: chore.title,
          );
        }
      },
    );

    test('can be generated in Russian', () async {
      final state = AppState(
        repository: AppRepository(MemoryStore()),
        clock: () => fixedNow,
      );
      await state.load();
      await state.setLanguage(AppLanguage.ru);
      state.startDemo();
      expect(state.data.household.name, 'Квартира на Чиланзаре');
    });
  });

  group('expenses', () {
    test(
      'rejects invalid amounts, unknown payers and mismatched shares',
      () async {
        final app = await demoState();
        final good = simpleExpense(app);
        expect(
          () => app.saveExpense(
            Expense(
              id: 'bad-1',
              householdId: good.householdId,
              title: 'x',
              amountUzs: 0,
              payerMemberId: good.payerMemberId,
              splitAmountsByMemberId: {good.payerMemberId: 0},
              splitMode: SplitMode.custom,
              category: ExpenseCategory.other,
              date: fixedNow,
              createdAt: fixedNow,
              createdById: good.payerMemberId,
            ),
          ),
          throwsArgumentError,
        );
        expect(
          () => app.saveExpense(
            Expense(
              id: 'bad-2',
              householdId: good.householdId,
              title: 'x',
              amountUzs: 1000,
              payerMemberId: good.payerMemberId,
              splitAmountsByMemberId: {good.payerMemberId: 400},
              splitMode: SplitMode.custom,
              category: ExpenseCategory.other,
              date: fixedNow,
              createdAt: fixedNow,
              createdById: good.payerMemberId,
            ),
          ),
          throwsArgumentError,
        );
        expect(
          () => app.saveExpense(
            Expense(
              id: 'bad-3',
              householdId: good.householdId,
              title: 'x',
              amountUzs: 1000,
              payerMemberId: 'ghost',
              splitAmountsByMemberId: {good.payerMemberId: 1000},
              splitMode: SplitMode.custom,
              category: ExpenseCategory.other,
              date: fixedNow,
              createdAt: fixedNow,
              createdById: good.payerMemberId,
            ),
          ),
          throwsArgumentError,
        );
      },
    );

    test('adding, editing and deleting an expense updates balances', () async {
      final app = await demoState();
      final before = app.balanceOf('demo-aziz');
      final e = simpleExpense(app, amount: 120000, id: 'flow');
      app.saveExpense(e);
      expect(app.balanceOf('demo-aziz'), before + 90000);

      app.saveExpense(
        Expense(
          id: 'flow',
          householdId: e.householdId,
          title: 'Edited',
          amountUzs: 40000,
          payerMemberId: 'demo-aziz',
          splitAmountsByMemberId: splitEqually(40000, [
            'demo-aziz',
            'demo-madina',
          ]),
          splitMode: SplitMode.equal,
          category: ExpenseCategory.groceries,
          date: fixedNow,
          createdAt: fixedNow,
          createdById: 'demo-aziz',
        ),
      );
      expect(app.balanceOf('demo-aziz'), before + 20000);

      app.deleteExpense('flow');
      expect(app.balanceOf('demo-aziz'), before);
    });

    test('a bill period can only be paid once and reopens when its expense is deleted', () async {
      final app = await demoState();
      final bill = app.billById('demo-internet')!;
      final due = currentDueDate(bill, app.data.expenses)!;
      app.saveExpense(
        simpleExpense(
          app,
          id: 'pay-1',
          amount: 160000,
          billId: bill.id,
          billPeriod: due,
        ),
      );
      expect(currentDueDate(bill, app.data.expenses), addMonths(due, 1));
      expect(
        () => app.saveExpense(
          simpleExpense(
            app,
            id: 'pay-2',
            amount: 160000,
            billId: bill.id,
            billPeriod: due,
          ),
        ),
        throwsStateError,
      );
      app.deleteExpense('pay-1');
      expect(currentDueDate(bill, app.data.expenses), due);
    });

    test('recording a payment settles a suggested transfer', () async {
      final app = await demoState();
      final suggestion = app.settlementSuggestions.first;
      app.recordSettlement(
        fromMemberId: suggestion.fromMemberId,
        toMemberId: suggestion.toMemberId,
        amountUzs: suggestion.amountUzs,
        method: app.data.settlements.first.method,
        date: fixedNow,
      );
      expect(app.settlementSuggestions.length, lessThan(3));
      expect(
        () => app.recordSettlement(
          fromMemberId: 'demo-aziz',
          toMemberId: 'demo-aziz',
          amountUzs: 10,
          method: app.data.settlements.first.method,
          date: fixedNow,
        ),
        throwsArgumentError,
      );
    });
  });

  group('chores', () {
    test(
      'completing creates the next turn by rotation, and undo restores it',
      () async {
        final app = await demoState();
        final current = app.currentAssignmentFor('demo-dishes')!;
        final next = app.completeAssignment(current.id)!;
        expect(current.status, AssignmentStatus.completed);
        expect(next.dueDate, DateTime(2026, 10, 23));
        expect(next.assigneeMemberId, 'demo-madina');
        expect(app.currentAssignmentFor('demo-dishes')!.id, next.id);

        app.undoCompletion(current.id, next.id);
        expect(current.isPending, isTrue);
        expect(app.assignmentById(next.id), isNull);
      },
    );

    test(
      'skipping needs a reason and keeps the same person first in line',
      () async {
        final app = await demoState();
        final current = app.currentAssignmentFor('demo-dishes')!;
        expect(() => app.skipAssignment(current.id, '  '), throwsArgumentError);
        final next = app.skipAssignment(current.id, 'Imtihon')!;
        expect(current.status, AssignmentStatus.skipped);
        expect(next.assigneeMemberId, current.assigneeMemberId);
      },
    );

    test(
      'reassigning changes only the assignee and keeps the history',
      () async {
        final app = await demoState();
        final current = app.currentAssignmentFor('demo-trash')!;
        final original = current.assigneeMemberId;
        app.reassign(current.id, 'demo-sardor');
        expect(current.isPending, isTrue);
        expect(current.assigneeMemberId, 'demo-sardor');
        expect(current.changes.single.fromMemberId, original);
        expect(current.originalAssigneeId, original);
      },
    );

    test('swapping exchanges two assignees and records both changes', () async {
      final app = await demoState();
      final a = app.currentAssignmentFor('demo-dishes')!;
      final b = app.currentAssignmentFor('demo-bathroom')!;
      final aMember = a.assigneeMemberId;
      final bMember = b.assigneeMemberId;
      app.swapAssignments(a.id, b.id);
      expect(a.assigneeMemberId, bMember);
      expect(b.assigneeMemberId, aMember);
      expect(a.changes.last.type, AssignmentChangeType.swapped);
      expect(b.changes.last.type, AssignmentChangeType.swapped);
    });

    test(
      'new chores spread first turns and archived chores keep their history',
      () async {
        final app = await demoState();
        final chore = app.createChore(
          title: 'Oshxonani tozalash',
          frequency: ChoreFrequency.weekly,
          eligibleMemberIds: app.activeMembers.map((m) => m.id).toList(),
          priority: Priority.medium,
          firstDueDate: app.today,
        );
        expect(app.currentAssignmentFor(chore.id), isNotNull);
        final historyBefore = app.closedAssignments.length;
        app.archiveChore('demo-dishes');
        expect(app.currentAssignmentFor('demo-dishes'), isNull);
        expect(app.closedAssignments.length, historyBefore);
      },
    );

    test('a roommate who moves out has open chores handed to others', () async {
      final app = await demoState();
      app.setMemberActive('demo-sardor', false);
      expect(
        app.pendingAssignments.where(
          (a) => a.assigneeMemberId == 'demo-sardor',
        ),
        isEmpty,
      );
      expect(app.balances.containsKey('demo-sardor'), isTrue);
      expect(app.canMoveOut(app.data.currentMemberId), isFalse);
    });
  });

  group('shopping', () {
    test(
      'finds duplicates among items still to buy, ignoring case and spaces',
      () async {
        final app = await demoState();
        expect(app.findActiveDuplicate('  non ')?.id, 'demo-bread');
        expect(
          app.findActiveDuplicate('Ichimlik suvi'),
          isNull,
          reason: 'already purchased',
        );
      },
    );

    test('linking purchases to an expense prevents linking them twice and restore unlinks', () async {
      final app = await demoState();
      final itemId = 'demo-tissue';
      expect(app.unrecordedPurchases.map((i) => i.id), contains(itemId));
      final members = app.activeMembers.map((m) => m.id).toList();
      app.saveExpense(
        Expense(
          id: 'tissue-exp',
          householdId: app.data.household.id,
          title: 'Xarid',
          amountUzs: 24000,
          payerMemberId: 'demo-madina',
          splitAmountsByMemberId: splitEqually(24000, members),
          splitMode: SplitMode.equal,
          category: ExpenseCategory.household,
          date: fixedNow,
          createdAt: fixedNow,
          createdById: 'demo-madina',
          shoppingItemIds: [itemId, 'demo-water'],
        ),
      );
      expect(app.expenseForShoppingItem(itemId)!.id, 'tissue-exp');
      expect(app.expenseById('tissue-exp')!.shoppingItemIds, [
        itemId,
      ], reason: 'water was already linked');

      app.setPurchased(itemId, false);
      expect(app.expenseForShoppingItem(itemId), isNull);
      expect(app.expenseById('tissue-exp')!.amountUzs, 24000);
    });

    test('add, purchase, restore and remove an item', () async {
      final app = await demoState();
      app.addShoppingItem(
        name: 'Shakar',
        category: ShoppingCategory.food,
        quantity: '1 kg',
      );
      final item = app.itemsToBuy.firstWhere((i) => i.name == 'Shakar');
      app.setPurchased(item.id, true);
      expect(item.purchasedById, app.data.currentMemberId);
      app.setPurchased(item.id, false);
      expect(item.isPurchased, isFalse);
      app.removeShoppingItem(item.id);
      expect(app.shoppingItemById(item.id), isNull);
    });
  });

  group('planner privacy', () {
    test('each profile only sees its own planner items', () async {
      final app = await demoState();
      final azizItems = app.myPlannerItems.map((p) => p.id).toSet();
      expect(
        app.myPlannerItems.every((p) => p.ownerMemberId == 'demo-aziz'),
        isTrue,
      );
      app.switchMember('demo-madina');
      expect(
        app.myPlannerItems.every((p) => p.ownerMemberId == 'demo-madina'),
        isTrue,
      );
      expect(
        app.myPlannerItems.map((p) => p.id).toSet().intersection(azizItems),
        isEmpty,
      );
    });

    test('items owned by someone else cannot be saved or completed', () async {
      final app = await demoState();
      final foreign = app.data.plannerItems.firstWhere(
        (p) => p.ownerMemberId == 'demo-madina',
      );
      expect(() => app.savePlannerItem(foreign), throwsStateError);
      app.setPlannerCompleted(foreign.id, true);
      expect(foreign.isCompleted, isFalse);
    });

    test('completing a task moves it out of active views', () async {
      final app = await demoState();
      final task = app.myPlannerItems.firstWhere(
        (p) => p.category == PlannerCategory.exam,
      );
      app.setPlannerCompleted(task.id, true);
      expect(task.completedAt, fixedNow);
      app.setPlannerCompleted(task.id, false);
      expect(task.completedAt, isNull);
    });
  });

  group('persistence', () {
    test('everything survives a restart', () async {
      final store = MemoryStore();
      final app = await demoState(store: store);
      app.addShoppingItem(name: 'Shakar', category: ShoppingCategory.food);
      app.switchMember('demo-dilnoza');
      await app.flushSaves();

      final restarted = AppState(
        repository: AppRepository(store),
        clock: () => fixedNow,
      );
      await restarted.load();
      expect(restarted.hasHousehold, isTrue);
      expect(restarted.currentMember.displayName, 'Dilnoza');
      expect(restarted.itemsToBuy.any((i) => i.name == 'Shakar'), isTrue);
      expect(
        jsonEncode(restarted.data.toJson()),
        jsonEncode(app.data.toJson()),
      );
    });

    test(
      'missing data starts at the welcome screen without inventing anything',
      () async {
        final app = AppState(
          repository: AppRepository(MemoryStore()),
          clock: () => fixedNow,
        );
        await app.load();
        expect(app.hasHousehold, isFalse);
        expect(app.storedDataWasUnreadable, isFalse);
      },
    );

    test('corrupted data is backed up, never silently erased', () async {
      final store = MemoryStore({
        AppRepository.dataKey: '{"schemaVersion": 1, "members": [',
      });
      final app = AppState(
        repository: AppRepository(store),
        clock: () => fixedNow,
      );
      await app.load();
      expect(app.hasHousehold, isFalse);
      expect(app.storedDataWasUnreadable, isTrue);
      expect(
        store.values[AppRepository.backupKey],
        '{"schemaVersion": 1, "members": [',
      );
      expect(store.values[AppRepository.dataKey], isNotNull);
    });

    test(
      'a storage failure on launch still finishes loading and is reported',
      () async {
        final app = AppState(
          repository: AppRepository(_FailingStore()),
          clock: () => fixedNow,
        );
        await app.load();
        expect(app.isLoading, isFalse);
        expect(app.storageUnavailable, isTrue);
        expect(app.hasHousehold, isFalse);
      },
    );

    test('data from a newer app version is treated as unreadable', () async {
      final store = MemoryStore({
        AppRepository.dataKey: '{"schemaVersion": 99}',
      });
      final app = AppState(
        repository: AppRepository(store),
        clock: () => fixedNow,
      );
      await app.load();
      expect(app.storedDataWasUnreadable, isTrue);
    });

    test(
      'settings are stored separately and survive leaving the household',
      () async {
        final store = MemoryStore();
        final app = await demoState(store: store);
        await app.setLanguage(AppLanguage.ru);
        await app.setThemeMode(ThemeMode.dark);
        app.leaveHousehold();
        await app.flushSaves();
        expect(store.values.containsKey(AppRepository.dataKey), isFalse);

        final restarted = AppState(
          repository: AppRepository(store),
          clock: () => fixedNow,
        );
        await restarted.load();
        expect(restarted.settings.language, AppLanguage.ru);
        expect(restarted.settings.themeMode, ThemeMode.dark);
        expect(restarted.hasHousehold, isFalse);
      },
    );
  });
}

class _FailingStore implements KeyValueStore {
  @override
  Future<String?> read(String key) =>
      Future.error(StateError('storage unavailable'));

  @override
  Future<void> write(String key, String value) =>
      Future.error(StateError('storage unavailable'));

  @override
  Future<void> remove(String key) =>
      Future.error(StateError('storage unavailable'));
}

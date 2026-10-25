import 'package:flutter/material.dart';

import '../l10n/app_language.dart';
import '../l10n/app_strings.dart';
import '../models/activity_entry.dart';
import '../models/app_data.dart';
import '../models/chore.dart';
import '../models/expense.dart';
import '../models/house_notes.dart';
import '../models/household.dart';
import '../models/household_bill.dart';
import '../models/household_event.dart';
import '../models/household_issue.dart';
import '../models/household_member.dart';
import '../models/household_poll.dart';
import '../models/planner_item.dart';
import '../models/priority.dart';
import '../models/settlement.dart';
import '../models/shopping_item.dart';
import '../services/calculations/attention.dart';
import '../services/calculations/balances.dart';
import '../services/calculations/bill_schedule.dart';
import '../services/calculations/chore_rotation.dart';
import '../services/calculations/money_split.dart';
import '../services/demo_data.dart';
import '../services/repositories/app_repository.dart';
import '../utils/date_math.dart';
import '../utils/id_generator.dart';
import '../utils/validators.dart';

class AppState extends ChangeNotifier {
  AppState({required this.repository, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppRepository repository;
  final DateTime Function() _clock;

  AppData? _data;
  AppSettings _settings = const AppSettings();
  bool _isLoading = true;
  bool _storedDataWasUnreadable = false;
  bool _saveFailed = false;
  bool _storageUnavailable = false;
  Future<void> _saveQueue = Future.value();

  static const int _activityLimit = 60;

  DateTime now() => _clock();
  DateTime get today => dateOnly(now());

  bool get isLoading => _isLoading;
  bool get hasHousehold => _data != null;
  bool get storedDataWasUnreadable => _storedDataWasUnreadable;
  bool get saveFailed => _saveFailed;
  bool get storageUnavailable => _storageUnavailable;
  AppData get data => _data!;
  AppSettings get settings => _settings;
  AppStrings get strings => AppStrings(_settings.language);

  Future<void> load() async {
    try {
      _settings = await repository.loadSettings();
      final result = await repository.load();
      _data = result.data;
      _storedDataWasUnreadable = result.status == LoadStatus.unreadable;
    } catch (_) {
      _storageUnavailable = true;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> flushSaves() => _saveQueue;

  void _commit() {
    notifyListeners();
    final snapshot = _data;
    _saveQueue = _saveQueue.then((_) async {
      try {
        if (snapshot == null) {
          await repository.clear();
        } else {
          await repository.save(snapshot);
        }
        if (_saveFailed) {
          _saveFailed = false;
          notifyListeners();
        }
      } catch (_) {
        _saveFailed = true;
        notifyListeners();
      }
    });
  }

  void _log(
    ActivityType type, {
    String subject = '',
    int? amountUzs,
    String? otherMemberId,
  }) {
    data.activity.insert(
      0,
      ActivityEntry(
        id: newId('act'),
        type: type,
        actorId: data.currentMemberId,
        at: now(),
        subject: subject,
        amountUzs: amountUzs,
        otherMemberId: otherMemberId,
      ),
    );
    if (data.activity.length > _activityLimit) {
      data.activity.removeRange(_activityLimit, data.activity.length);
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    _settings = AppSettings(language: language, themeMode: _settings.themeMode);
    notifyListeners();
    await repository.saveSettings(_settings);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _settings = AppSettings(language: _settings.language, themeMode: mode);
    notifyListeners();
    await repository.saveSettings(_settings);
  }

  void startDemo() {
    _data = buildDemoData(now(), _settings.language);
    _storedDataWasUnreadable = false;
    _commit();
  }

  void createHousehold({
    required String householdName,
    required String yourName,
    required List<String> roommateNames,
  }) {
    final household = Household(
      id: newId('house'),
      name: householdName.trim(),
      createdAt: now(),
    );
    final names = [
      yourName,
      ...roommateNames,
    ].map((n) => n.trim()).where((n) => n.isNotEmpty).toList();
    final members = <HouseholdMember>[];
    for (var i = 0; i < names.length; i++) {
      members.add(
        HouseholdMember(
          id: newId('member'),
          householdId: household.id,
          displayName: names[i],
          colorIndex: i,
          createdAt: now(),
        ),
      );
    }
    _data = AppData(
      household: household,
      members: members,
      currentMemberId: members.first.id,
    );
    _storedDataWasUnreadable = false;
    _commit();
  }

  void leaveHousehold() {
    _data = null;
    _commit();
  }

  void renameHousehold(String name) {
    data.household.name = name.trim();
    _commit();
  }

  List<HouseholdMember> get members => data.members;
  List<HouseholdMember> get activeMembers =>
      data.members.where((m) => m.isActive).toList();
  Set<String> get activeMemberIds => activeMembers.map((m) => m.id).toSet();
  List<String> get memberOrder => data.members.map((m) => m.id).toList();

  HouseholdMember get currentMember => member(data.currentMemberId)!;

  HouseholdMember? member(String? id) {
    if (id == null) return null;
    for (final m in data.members) {
      if (m.id == id) return m;
    }
    return null;
  }

  String memberName(String? id) => member(id)?.displayName ?? '—';

  void switchMember(String id) {
    final target = member(id);
    if (target == null || !target.isActive) return;
    data.currentMemberId = id;
    _commit();
  }

  void addMember(
    String name,
    int colorIndex, {
    bool joinChoreRotations = true,
  }) {
    final newMember = HouseholdMember(
      id: newId('member'),
      householdId: data.household.id,
      displayName: name.trim(),
      colorIndex: colorIndex,
      createdAt: now(),
    );
    data.members.add(newMember);
    if (joinChoreRotations) {
      for (final chore in data.chores.where((c) => c.isActive)) {
        chore.eligibleMemberIds.add(newMember.id);
      }
    }
    _log(ActivityType.memberAdded, subject: newMember.displayName);
    _commit();
  }

  void updateMember(
    String id, {
    required String name,
    required int colorIndex,
  }) {
    final target = member(id);
    if (target == null) return;
    target.displayName = name.trim();
    target.colorIndex = colorIndex;
    _commit();
  }

  bool canMoveOut(String id) =>
      id != data.currentMemberId &&
      activeMembers.length > 1 &&
      (member(id)?.isActive ?? false);

  void setMemberActive(String id, bool active) {
    final target = member(id);
    if (target == null) return;
    if (!active && !canMoveOut(id)) return;
    target.isActive = active;
    if (!active) {
      for (final a
          in data.assignments
              .where((a) => a.isPending && a.assigneeMemberId == id)
              .toList()) {
        final chore = choreById(a.choreId);
        if (chore == null) continue;
        final decision = decideNextAssignee(
          chore: chore,
          allAssignments: data.assignments.where((x) => x.id != a.id).toList(),
          activeMemberIds: activeMemberIds,
        );
        if (decision.memberId != null) _reassignInternal(a, decision.memberId!);
      }
    }
    _commit();
  }

  List<Expense> get expensesNewestFirst => List.of(data.expenses)
    ..sort((a, b) {
      final byDate = b.date.compareTo(a.date);
      return byDate != 0 ? byDate : b.createdAt.compareTo(a.createdAt);
    });

  List<Settlement> get settlementsNewestFirst =>
      List.of(data.settlements)..sort((a, b) => b.date.compareTo(a.date));

  Expense? expenseById(String? id) {
    if (id == null) return null;
    for (final e in data.expenses) {
      if (e.id == id) return e;
    }
    return null;
  }

  Map<String, MemberBalance> get balances => computeBalances(
    memberIds: memberOrder,
    expenses: data.expenses,
    settlements: data.settlements,
  );

  int balanceOf(String memberId) => balances[memberId]?.net ?? 0;

  List<Transfer> get settlementSuggestions => suggestSettlements(
    balances.map((id, b) => MapEntry(id, b.net)),
    memberOrder,
  );

  int spendingInMonth(DateTime month) => totalSpending(
    data.expenses,
    from: startOfMonth(month),
    to: addMonths(startOfMonth(month), 1),
  );

  int myShareInMonth(DateTime month) => shareSpending(
    data.expenses,
    data.currentMemberId,
    from: startOfMonth(month),
    to: addMonths(startOfMonth(month), 1),
  );

  bool isBillPeriodPaid(
    String billId,
    DateTime period, {
    String? exceptExpenseId,
  }) => data.expenses.any(
    (e) =>
        e.id != exceptExpenseId &&
        e.billId == billId &&
        e.billPeriod != null &&
        isSameDay(e.billPeriod!, period),
  );

  void _checkExpense(Expense e) {
    if (e.amountUzs <= 0 || e.amountUzs > maxAmountUzs) {
      throw ArgumentError('Amount must be between 1 and $maxAmountUzs soʻm');
    }
    if (member(e.payerMemberId) == null) throw ArgumentError('Unknown payer');
    if (e.splitAmountsByMemberId.keys.any((id) => member(id) == null)) {
      throw ArgumentError('Unknown participant');
    }
    if (validateCustomSplit(e.amountUzs, e.splitAmountsByMemberId) != null) {
      throw ArgumentError('Shares must be positive and add up to the total');
    }
    if (e.billId != null &&
        e.billPeriod != null &&
        isBillPeriodPaid(e.billId!, e.billPeriod!, exceptExpenseId: e.id)) {
      throw StateError('This bill period is already recorded');
    }
  }

  void saveExpense(Expense expense) {
    _checkExpense(expense);
    expense.shoppingItemIds.removeWhere((itemId) {
      final linked = expenseForShoppingItem(itemId);
      return linked != null && linked.id != expense.id;
    });
    final index = data.expenses.indexWhere((e) => e.id == expense.id);
    if (index == -1) {
      data.expenses.add(expense);
      for (final itemId in expense.shoppingItemIds) {
        final item = shoppingItemById(itemId);
        if (item != null && !item.isPurchased) {
          item.isPurchased = true;
          item.purchasedById = expense.payerMemberId;
          item.purchasedAt = expense.date;
        }
      }
      _log(
        expense.isBillPayment
            ? ActivityType.billPaid
            : ActivityType.expenseAdded,
        subject: expense.title,
        amountUzs: expense.amountUzs,
      );
    } else {
      data.expenses[index] = expense;
      _log(
        ActivityType.expenseEdited,
        subject: expense.title,
        amountUzs: expense.amountUzs,
      );
    }
    _commit();
  }

  void deleteExpense(String id) {
    final expense = expenseById(id);
    if (expense == null) return;
    data.expenses.remove(expense);
    _log(
      ActivityType.expenseDeleted,
      subject: expense.title,
      amountUzs: expense.amountUzs,
    );
    _commit();
  }

  void recordSettlement({
    required String fromMemberId,
    required String toMemberId,
    required int amountUzs,
    required PaymentMethod method,
    required DateTime date,
    String note = '',
  }) {
    if (fromMemberId == toMemberId) {
      throw ArgumentError('A payment needs two different people');
    }
    if (amountUzs <= 0 || amountUzs > maxAmountUzs) {
      throw ArgumentError('Invalid amount');
    }
    data.settlements.add(
      Settlement(
        id: newId('pay'),
        householdId: data.household.id,
        fromMemberId: fromMemberId,
        toMemberId: toMemberId,
        amountUzs: amountUzs,
        method: method,
        date: date,
        createdAt: now(),
        recordedById: data.currentMemberId,
        note: note.trim(),
      ),
    );
    _log(
      ActivityType.settlementRecorded,
      subject: memberName(fromMemberId),
      amountUzs: amountUzs,
      otherMemberId: toMemberId,
    );
    _commit();
  }

  void deleteSettlement(String id) {
    data.settlements.removeWhere((s) => s.id == id);
    _commit();
  }

  List<Chore> get activeChores => data.chores.where((c) => c.isActive).toList();

  Chore? choreById(String? id) {
    if (id == null) return null;
    for (final c in data.chores) {
      if (c.id == id) return c;
    }
    return null;
  }

  ChoreAssignment? assignmentById(String? id) {
    if (id == null) return null;
    for (final a in data.assignments) {
      if (a.id == id) return a;
    }
    return null;
  }

  List<ChoreAssignment> get pendingAssignments {
    final activeIds = activeChores.map((c) => c.id).toSet();
    return data.assignments
        .where((a) => a.isPending && activeIds.contains(a.choreId))
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  List<ChoreAssignment> get closedAssignments =>
      data.assignments.where((a) => !a.isPending).toList()..sort(
        (a, b) =>
            (b.completedAt ?? b.dueDate).compareTo(a.completedAt ?? a.dueDate),
      );

  ChoreAssignment? currentAssignmentFor(String choreId) {
    final pending =
        data.assignments
            .where((a) => a.choreId == choreId && a.isPending)
            .toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return pending.isEmpty ? null : pending.first;
  }

  RotationDecision rotationFor(Chore chore) {
    final current = currentAssignmentFor(chore.id);
    final history = [
      for (final a in data.assignments)
        if (a.id == current?.id)
          ChoreAssignment(
            id: a.id,
            choreId: a.choreId,
            assigneeMemberId: a.assigneeMemberId,
            dueDate: a.dueDate,
            createdAt: a.createdAt,
            status: AssignmentStatus.completed,
          )
        else
          a,
    ];
    return decideNextAssignee(
      chore: chore,
      allAssignments: history,
      activeMemberIds: activeMemberIds,
    );
  }

  List<ProjectedTurn> projectionFor(Chore chore, {int count = 4}) =>
      projectUpcomingTurns(
        chore: chore,
        allAssignments: data.assignments,
        activeMemberIds: activeMemberIds,
        today: today,
        count: count,
      );

  String? suggestFirstAssignee(List<String> eligibleMemberIds) {
    final draft = Chore(
      id: 'draft',
      householdId: data.household.id,
      title: '',
      frequency: ChoreFrequency.weekly,
      eligibleMemberIds: eligibleMemberIds,
      priority: Priority.medium,
      createdAt: now(),
      createdById: data.currentMemberId,
    );
    return decideNextAssignee(
      chore: draft,
      allAssignments: data.assignments,
      activeMemberIds: activeMemberIds,
    ).memberId;
  }

  Chore createChore({
    required String title,
    required ChoreFrequency frequency,
    required List<String> eligibleMemberIds,
    required Priority priority,
    required DateTime firstDueDate,
    String? assigneeId,
    String notes = '',
  }) {
    if (eligibleMemberIds.isEmpty) {
      throw ArgumentError('Choose at least one roommate');
    }
    final chore = Chore(
      id: newId('chore'),
      householdId: data.household.id,
      title: title.trim(),
      frequency: frequency,
      eligibleMemberIds: List.of(eligibleMemberIds),
      priority: priority,
      notes: notes.trim(),
      createdAt: now(),
      createdById: data.currentMemberId,
    );
    data.chores.add(chore);
    final assignee =
        assigneeId ??
        decideNextAssignee(
          chore: chore,
          allAssignments: data.assignments,
          activeMemberIds: activeMemberIds,
        ).memberId;
    if (assignee != null) {
      data.assignments.add(
        ChoreAssignment(
          id: newId('turn'),
          choreId: chore.id,
          assigneeMemberId: assignee,
          dueDate: dateOnly(firstDueDate),
          createdAt: now(),
        ),
      );
    }
    _log(
      ActivityType.choreCreated,
      subject: chore.title,
      otherMemberId: assignee,
    );
    _commit();
    return chore;
  }

  void updateChore(
    Chore chore, {
    required String title,
    required ChoreFrequency frequency,
    required List<String> eligibleMemberIds,
    required Priority priority,
    required String notes,
  }) {
    if (eligibleMemberIds.isEmpty) {
      throw ArgumentError('Choose at least one roommate');
    }
    chore.title = title.trim();
    chore.frequency = frequency;
    chore.eligibleMemberIds = List.of(eligibleMemberIds);
    chore.priority = priority;
    chore.notes = notes.trim();
    _commit();
  }

  void archiveChore(String choreId) {
    final chore = choreById(choreId);
    if (chore == null) return;
    chore.isActive = false;
    data.assignments.removeWhere((a) => a.choreId == choreId && a.isPending);
    _commit();
  }

  ChoreAssignment? _generateNext(ChoreAssignment previous) {
    final chore = choreById(previous.choreId);
    if (chore == null || !chore.isActive || !chore.isRecurring) return null;
    if (data.assignments.any((a) => a.choreId == chore.id && a.isPending)) {
      return null;
    }
    final due = nextDueDate(previous.dueDate, chore.frequency, today);
    if (due == null) return null;
    final decision = decideNextAssignee(
      chore: chore,
      allAssignments: data.assignments,
      activeMemberIds: activeMemberIds,
    );
    if (decision.memberId == null) return null;
    final next = ChoreAssignment(
      id: newId('turn'),
      choreId: chore.id,
      assigneeMemberId: decision.memberId!,
      dueDate: due,
      createdAt: now(),
    );
    data.assignments.add(next);
    return next;
  }

  ChoreAssignment? completeAssignment(String assignmentId) {
    final a = assignmentById(assignmentId);
    if (a == null || !a.isPending) return null;
    a.status = AssignmentStatus.completed;
    a.completedAt = now();
    final chore = choreById(a.choreId);
    _log(
      ActivityType.choreCompleted,
      subject: chore?.title ?? '',
      otherMemberId: a.assigneeMemberId == data.currentMemberId
          ? null
          : a.assigneeMemberId,
    );
    final next = _generateNext(a);
    _commit();
    return next;
  }

  void undoCompletion(String assignmentId, String? generatedNextId) {
    final a = assignmentById(assignmentId);
    if (a == null || a.status != AssignmentStatus.completed) return;
    final next = assignmentById(generatedNextId);
    if (next != null && next.isPending && next.changes.isEmpty) {
      data.assignments.remove(next);
    }
    a.status = AssignmentStatus.pending;
    a.completedAt = null;
    if (data.activity.isNotEmpty &&
        data.activity.first.type == ActivityType.choreCompleted) {
      data.activity.removeAt(0);
    }
    _commit();
  }

  ChoreAssignment? skipAssignment(String assignmentId, String reason) {
    final a = assignmentById(assignmentId);
    if (a == null || !a.isPending) return null;
    if (reason.trim().isEmpty) throw ArgumentError('A reason is required');
    a.status = AssignmentStatus.skipped;
    a.skipReason = reason.trim();
    _log(
      ActivityType.choreSkipped,
      subject: choreById(a.choreId)?.title ?? '',
      otherMemberId: a.assigneeMemberId,
    );
    final next = _generateNext(a);
    _commit();
    return next;
  }

  void _reassignInternal(ChoreAssignment a, String toMemberId) {
    a.changes.add(
      AssignmentChange(
        type: AssignmentChangeType.reassigned,
        fromMemberId: a.assigneeMemberId,
        toMemberId: toMemberId,
        changedById: data.currentMemberId,
        at: now(),
      ),
    );
    a.assigneeMemberId = toMemberId;
  }

  void reassign(String assignmentId, String toMemberId) {
    final a = assignmentById(assignmentId);
    if (a == null || !a.isPending || a.assigneeMemberId == toMemberId) return;
    _reassignInternal(a, toMemberId);
    _log(
      ActivityType.choreReassigned,
      subject: choreById(a.choreId)?.title ?? '',
      otherMemberId: toMemberId,
    );
    _commit();
  }

  void swapAssignments(String firstId, String secondId) {
    final a = assignmentById(firstId);
    final b = assignmentById(secondId);
    if (a == null || b == null || !a.isPending || !b.isPending) return;
    if (a.assigneeMemberId == b.assigneeMemberId) return;
    final aMember = a.assigneeMemberId;
    final bMember = b.assigneeMemberId;
    final at = now();
    a.changes.add(
      AssignmentChange(
        type: AssignmentChangeType.swapped,
        fromMemberId: aMember,
        toMemberId: bMember,
        changedById: data.currentMemberId,
        at: at,
      ),
    );
    b.changes.add(
      AssignmentChange(
        type: AssignmentChangeType.swapped,
        fromMemberId: bMember,
        toMemberId: aMember,
        changedById: data.currentMemberId,
        at: at,
      ),
    );
    a.assigneeMemberId = bMember;
    b.assigneeMemberId = aMember;
    _log(
      ActivityType.choreSwapped,
      subject: memberName(aMember),
      otherMemberId: bMember,
    );
    _commit();
  }

  List<MemberChoreLoad> get choreLoads => choreLoadByMember(
    memberIds: activeMembers.map((m) => m.id).toList(),
    assignments: data.assignments,
    today: today,
  );

  List<ShoppingItem> get itemsToBuy =>
      data.shoppingItems.where((i) => !i.isPurchased).toList()..sort(
        (a, b) => a.category.index != b.category.index
            ? a.category.index.compareTo(b.category.index)
            : a.createdAt.compareTo(b.createdAt),
      );

  List<ShoppingItem> get purchasedItems =>
      data.shoppingItems.where((i) => i.isPurchased).toList()..sort(
        (a, b) => (b.purchasedAt ?? b.createdAt).compareTo(
          a.purchasedAt ?? a.createdAt,
        ),
      );

  ShoppingItem? shoppingItemById(String id) {
    for (final i in data.shoppingItems) {
      if (i.id == id) return i;
    }
    return null;
  }

  Expense? expenseForShoppingItem(String itemId) {
    for (final e in data.expenses) {
      if (e.shoppingItemIds.contains(itemId)) return e;
    }
    return null;
  }

  List<ShoppingItem> get unrecordedPurchases => purchasedItems
      .where((i) => expenseForShoppingItem(i.id) == null)
      .toList();

  ShoppingItem? findActiveDuplicate(String name, {String? exceptId}) {
    final key = normalizeName(name);
    for (final item in data.shoppingItems) {
      if (!item.isPurchased &&
          item.id != exceptId &&
          normalizeName(item.name) == key) {
        return item;
      }
    }
    return null;
  }

  void addShoppingItem({
    required String name,
    required ShoppingCategory category,
    String quantity = '',
    String notes = '',
    String? buyerMemberId,
  }) {
    final item = ShoppingItem(
      id: newId('item'),
      householdId: data.household.id,
      name: name.trim(),
      quantity: quantity.trim(),
      notes: notes.trim(),
      category: category,
      addedById: data.currentMemberId,
      buyerMemberId: buyerMemberId,
      createdAt: now(),
    );
    data.shoppingItems.add(item);
    _log(ActivityType.shoppingAdded, subject: item.name);
    _commit();
  }

  void updateShoppingItem(
    ShoppingItem item, {
    required String name,
    required ShoppingCategory category,
    required String quantity,
    required String notes,
    required String? buyerMemberId,
  }) {
    item.name = name.trim();
    item.category = category;
    item.quantity = quantity.trim();
    item.notes = notes.trim();
    item.buyerMemberId = buyerMemberId;
    _commit();
  }

  void setPurchased(String itemId, bool purchased) {
    final item = shoppingItemById(itemId);
    if (item == null || item.isPurchased == purchased) return;
    item.isPurchased = purchased;
    if (purchased) {
      item.purchasedById = data.currentMemberId;
      item.purchasedAt = now();
      _log(ActivityType.shoppingPurchased, subject: item.name);
    } else {
      item.purchasedById = null;
      item.purchasedAt = null;
      expenseForShoppingItem(itemId)?.shoppingItemIds.remove(itemId);
    }
    _commit();
  }

  void removeShoppingItem(String itemId) {
    expenseForShoppingItem(itemId)?.shoppingItemIds.remove(itemId);
    data.shoppingItems.removeWhere((i) => i.id == itemId);
    _commit();
  }

  void clearPurchased() {
    for (final item in purchasedItems) {
      expenseForShoppingItem(item.id)?.shoppingItemIds.remove(item.id);
    }
    data.shoppingItems.removeWhere((i) => i.isPurchased);
    _commit();
  }

  List<PlannerItem> get myPlannerItems => data.plannerItems
      .where((p) => p.ownerMemberId == data.currentMemberId)
      .toList();

  PlannerItem? plannerItemById(String id) {
    for (final p in myPlannerItems) {
      if (p.id == id) return p;
    }
    return null;
  }

  void savePlannerItem(PlannerItem item) {
    if (item.ownerMemberId != data.currentMemberId) {
      throw StateError('Planner items can only be changed by their owner');
    }
    final index = data.plannerItems.indexWhere((p) => p.id == item.id);
    if (index == -1) {
      data.plannerItems.add(item);
    } else {
      data.plannerItems[index] = item;
    }
    _commit();
  }

  void setPlannerCompleted(String id, bool completed) {
    final item = plannerItemById(id);
    if (item == null || !item.canBeCompleted) return;
    item.isCompleted = completed;
    item.completedAt = completed ? now() : null;
    _commit();
  }

  void deletePlannerItem(String id) {
    data.plannerItems.removeWhere(
      (p) => p.id == id && p.ownerMemberId == data.currentMemberId,
    );
    _commit();
  }

  List<BillOverview> get billOverviewList =>
      billOverviews(data.bills, data.expenses, today);

  HouseholdBill? billById(String? id) {
    if (id == null) return null;
    for (final b in data.bills) {
      if (b.id == id) return b;
    }
    return null;
  }

  void saveBill(HouseholdBill bill) {
    if (bill.expectedAmountUzs <= 0) throw ArgumentError('Invalid amount');
    if (bill.participantMemberIds.isEmpty) {
      throw ArgumentError('Choose who shares the bill');
    }
    final index = data.bills.indexWhere((b) => b.id == bill.id);
    if (index == -1) {
      data.bills.add(bill);
    } else {
      data.bills[index] = bill;
    }
    _commit();
  }

  void archiveBill(String id) {
    billById(id)?.isActive = false;
    _commit();
  }

  List<HouseholdEvent> get eventsChronological =>
      List.of(data.events)..sort((a, b) => a.startAt.compareTo(b.startAt));

  void saveEvent(HouseholdEvent event) {
    final index = data.events.indexWhere((e) => e.id == event.id);
    if (index == -1) {
      data.events.add(event);
      _log(ActivityType.eventAdded, subject: event.title);
    } else {
      data.events[index] = event;
    }
    _commit();
  }

  void deleteEvent(String id) {
    data.events.removeWhere((e) => e.id == id);
    _commit();
  }

  HouseholdPoll? pollById(String id) {
    for (final p in data.polls) {
      if (p.id == id) return p;
    }
    return null;
  }

  void createPoll({
    required String question,
    required List<String> options,
    DateTime? deadline,
  }) {
    final cleaned = options
        .map((o) => o.trim())
        .where((o) => o.isNotEmpty)
        .toList();
    if (cleaned.length < 2) {
      throw ArgumentError('A poll needs at least two options');
    }
    final poll = HouseholdPoll(
      id: newId('poll'),
      householdId: data.household.id,
      question: question.trim(),
      options: [
        for (final text in cleaned) PollOption(id: newId('opt'), text: text),
      ],
      createdById: data.currentMemberId,
      createdAt: now(),
      deadline: deadline,
    );
    data.polls.add(poll);
    _log(ActivityType.pollCreated, subject: poll.question);
    _commit();
  }

  void vote(String pollId, String optionId) {
    final poll = pollById(pollId);
    if (poll == null || !poll.isOpen(now())) return;
    if (!poll.options.any((o) => o.id == optionId)) return;
    poll.votesByMemberId[data.currentMemberId] = optionId;
    _commit();
  }

  void closePoll(String pollId) {
    final poll = pollById(pollId);
    if (poll == null || poll.closedAt != null) return;
    poll.closedAt = now();
    poll.closedById = data.currentMemberId;
    _log(ActivityType.pollClosed, subject: poll.question);
    _commit();
  }

  void deletePoll(String pollId) {
    data.polls.removeWhere((p) => p.id == pollId);
    _commit();
  }

  HouseholdIssue? issueById(String id) {
    for (final i in data.issues) {
      if (i.id == id) return i;
    }
    return null;
  }

  void saveIssue(HouseholdIssue issue) {
    final index = data.issues.indexWhere((i) => i.id == issue.id);
    if (index == -1) {
      data.issues.add(issue);
      _log(ActivityType.issueReported, subject: issue.title);
    } else {
      data.issues[index] = issue;
    }
    _commit();
  }

  void setIssueStatus(
    String id,
    IssueStatus status, {
    String? resolutionNotes,
  }) {
    final issue = issueById(id);
    if (issue == null) return;
    final wasResolved = issue.status == IssueStatus.resolved;
    issue.status = status;
    if (resolutionNotes != null) issue.resolutionNotes = resolutionNotes.trim();
    if (status == IssueStatus.resolved && !wasResolved) {
      issue.resolvedAt = now();
      _log(ActivityType.issueResolved, subject: issue.title);
    }
    if (status != IssueStatus.resolved) issue.resolvedAt = null;
    _commit();
  }

  void deleteIssue(String id) {
    data.issues.removeWhere((i) => i.id == id);
    _commit();
  }

  void saveRule(HouseRule rule) {
    final index = data.rules.indexWhere((r) => r.id == rule.id);
    if (index == -1) {
      data.rules.add(rule);
    } else {
      data.rules[index] = rule;
    }
    _commit();
  }

  void deleteRule(String id) {
    data.rules.removeWhere((r) => r.id == id);
    _commit();
  }

  List<Announcement> get announcementsNewestFirst =>
      List.of(data.announcements)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<Announcement> get pinnedAnnouncements =>
      announcementsNewestFirst.where((a) => a.isPinned).toList();

  void postAnnouncement(String message) {
    data.announcements.add(
      Announcement(
        id: newId('note'),
        householdId: data.household.id,
        message: message.trim(),
        authorId: data.currentMemberId,
        createdAt: now(),
      ),
    );
    _log(ActivityType.announcementPosted, subject: message.trim());
    _commit();
  }

  void setAnnouncementPinned(String id, bool pinned) {
    for (final a in data.announcements) {
      if (a.id == id) a.isPinned = pinned;
    }
    _commit();
  }

  void deleteAnnouncement(String id) {
    data.announcements.removeWhere((a) => a.id == id);
    _commit();
  }

  List<AttentionItem> get attentionItems =>
      buildAttention(data: data, memberId: data.currentMemberId, now: now());

  List<ActivityEntry> get recentActivity => data.activity;
}

import 'activity_entry.dart';
import 'chore.dart';
import 'expense.dart';
import 'house_notes.dart';
import 'household.dart';
import 'household_bill.dart';
import 'household_event.dart';
import 'household_issue.dart';
import 'household_member.dart';
import 'household_poll.dart';
import 'json_helpers.dart';
import 'planner_item.dart';
import 'settlement.dart';
import 'shopping_item.dart';

class UnsupportedSchemaException implements Exception {
  UnsupportedSchemaException(this.version);
  final int version;

  @override
  String toString() => 'Unsupported data schema version $version';
}

class AppData {
  AppData({
    required this.household,
    required this.members,
    required this.currentMemberId,
    this.isDemo = false,
    List<Expense>? expenses,
    List<Settlement>? settlements,
    List<Chore>? chores,
    List<ChoreAssignment>? assignments,
    List<ShoppingItem>? shoppingItems,
    List<PlannerItem>? plannerItems,
    List<HouseholdBill>? bills,
    List<HouseholdEvent>? events,
    List<HouseholdPoll>? polls,
    List<HouseholdIssue>? issues,
    List<HouseRule>? rules,
    List<Announcement>? announcements,
    List<ActivityEntry>? activity,
  }) : expenses = expenses ?? [],
       settlements = settlements ?? [],
       chores = chores ?? [],
       assignments = assignments ?? [],
       shoppingItems = shoppingItems ?? [],
       plannerItems = plannerItems ?? [],
       bills = bills ?? [],
       events = events ?? [],
       polls = polls ?? [],
       issues = issues ?? [],
       rules = rules ?? [],
       announcements = announcements ?? [],
       activity = activity ?? [];

  static const int schemaVersion = 1;

  final Household household;
  final List<HouseholdMember> members;
  String currentMemberId;
  final bool isDemo;
  final List<Expense> expenses;
  final List<Settlement> settlements;
  final List<Chore> chores;
  final List<ChoreAssignment> assignments;
  final List<ShoppingItem> shoppingItems;
  final List<PlannerItem> plannerItems;
  final List<HouseholdBill> bills;
  final List<HouseholdEvent> events;
  final List<HouseholdPoll> polls;
  final List<HouseholdIssue> issues;
  final List<HouseRule> rules;
  final List<Announcement> announcements;
  final List<ActivityEntry> activity;

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'household': household.toJson(),
    'members': members.map((m) => m.toJson()).toList(),
    'currentMemberId': currentMemberId,
    'isDemo': isDemo,
    'expenses': expenses.map((e) => e.toJson()).toList(),
    'settlements': settlements.map((s) => s.toJson()).toList(),
    'chores': chores.map((c) => c.toJson()).toList(),
    'assignments': assignments.map((a) => a.toJson()).toList(),
    'shoppingItems': shoppingItems.map((i) => i.toJson()).toList(),
    'plannerItems': plannerItems.map((p) => p.toJson()).toList(),
    'bills': bills.map((b) => b.toJson()).toList(),
    'events': events.map((e) => e.toJson()).toList(),
    'polls': polls.map((p) => p.toJson()).toList(),
    'issues': issues.map((i) => i.toJson()).toList(),
    'rules': rules.map((r) => r.toJson()).toList(),
    'announcements': announcements.map((a) => a.toJson()).toList(),
    'activity': activity.map((a) => a.toJson()).toList(),
  };

  factory AppData.fromJson(Map<String, dynamic> json) {
    final version = json['schemaVersion'];
    if (version is! int || version < 1 || version > schemaVersion) {
      throw UnsupportedSchemaException(version is int ? version : -1);
    }
    final members = readList(json['members'], HouseholdMember.fromJson);
    if (members.isEmpty) {
      throw const FormatException('Household has no members');
    }
    var currentMemberId =
        readStringOrNull(json, 'currentMemberId') ?? members.first.id;
    if (!members.any((m) => m.id == currentMemberId)) {
      currentMemberId = members.first.id;
    }

    return AppData(
      household: Household.fromJson(
        Map<String, dynamic>.from(json['household'] as Map),
      ),
      members: members,
      currentMemberId: currentMemberId,
      isDemo: readBool(json, 'isDemo'),
      expenses: readList(json['expenses'], Expense.fromJson),
      settlements: readList(json['settlements'], Settlement.fromJson),
      chores: readList(json['chores'], Chore.fromJson),
      assignments: readList(json['assignments'], ChoreAssignment.fromJson),
      shoppingItems: readList(json['shoppingItems'], ShoppingItem.fromJson),
      plannerItems: readList(json['plannerItems'], PlannerItem.fromJson),
      bills: readList(json['bills'], HouseholdBill.fromJson),
      events: readList(json['events'], HouseholdEvent.fromJson),
      polls: readList(json['polls'], HouseholdPoll.fromJson),
      issues: readList(json['issues'], HouseholdIssue.fromJson),
      rules: readList(json['rules'], HouseRule.fromJson),
      announcements: readList(json['announcements'], Announcement.fromJson),
      activity: readList(json['activity'], ActivityEntry.fromJson),
    );
  }
}

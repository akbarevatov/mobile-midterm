import 'json_helpers.dart';
import 'priority.dart';

enum ChoreFrequency { once, daily, everyOtherDay, weekly, biweekly, monthly }

class Chore {
  Chore({
    required this.id,
    required this.householdId,
    required this.title,
    required this.frequency,
    required this.eligibleMemberIds,
    required this.priority,
    required this.createdAt,
    required this.createdById,
    this.notes = '',
    this.isActive = true,
  });

  final String id;
  final String householdId;
  String title;
  ChoreFrequency frequency;
  List<String> eligibleMemberIds;
  Priority priority;
  String notes;
  bool isActive;
  final DateTime createdAt;
  final String createdById;

  bool get isRecurring => frequency != ChoreFrequency.once;

  Map<String, dynamic> toJson() => {
    'id': id,
    'householdId': householdId,
    'title': title,
    'frequency': frequency.name,
    'eligibleMemberIds': eligibleMemberIds,
    'priority': priority.name,
    'notes': notes,
    'isActive': isActive,
    'createdAt': dateToJson(createdAt),
    'createdById': createdById,
  };

  factory Chore.fromJson(Map<String, dynamic> json) => Chore(
    id: readString(json, 'id'),
    householdId: readString(json, 'householdId'),
    title: readString(json, 'title'),
    frequency: readEnum(
      ChoreFrequency.values,
      json['frequency'],
      ChoreFrequency.weekly,
    ),
    eligibleMemberIds: readStringList(json['eligibleMemberIds']),
    priority: readEnum(Priority.values, json['priority'], Priority.medium),
    notes: readStringOrNull(json, 'notes') ?? '',
    isActive: readBool(json, 'isActive', fallback: true),
    createdAt: readDate(json, 'createdAt'),
    createdById: readStringOrNull(json, 'createdById') ?? '',
  );
}

enum AssignmentStatus { pending, completed, skipped }

enum AssignmentChangeType { reassigned, swapped }

class AssignmentChange {
  AssignmentChange({
    required this.type,
    required this.fromMemberId,
    required this.toMemberId,
    required this.changedById,
    required this.at,
  });

  final AssignmentChangeType type;
  final String fromMemberId;
  final String toMemberId;
  final String changedById;
  final DateTime at;

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'fromMemberId': fromMemberId,
    'toMemberId': toMemberId,
    'changedById': changedById,
    'at': dateToJson(at),
  };

  factory AssignmentChange.fromJson(Map<String, dynamic> json) =>
      AssignmentChange(
        type: readEnum(
          AssignmentChangeType.values,
          json['type'],
          AssignmentChangeType.reassigned,
        ),
        fromMemberId: readString(json, 'fromMemberId'),
        toMemberId: readString(json, 'toMemberId'),
        changedById: readStringOrNull(json, 'changedById') ?? '',
        at: readDate(json, 'at'),
      );
}

class ChoreAssignment {
  ChoreAssignment({
    required this.id,
    required this.choreId,
    required this.assigneeMemberId,
    required this.dueDate,
    required this.createdAt,
    this.status = AssignmentStatus.pending,
    this.completedAt,
    this.skipReason,
    List<AssignmentChange>? changes,
  }) : changes = changes ?? [];

  final String id;
  final String choreId;
  String assigneeMemberId;
  final DateTime dueDate;
  AssignmentStatus status;
  DateTime? completedAt;
  String? skipReason;
  final List<AssignmentChange> changes;
  final DateTime createdAt;

  bool get isPending => status == AssignmentStatus.pending;

  bool isOverdue(DateTime today) => isPending && dueDate.isBefore(today);

  String get originalAssigneeId =>
      changes.isEmpty ? assigneeMemberId : changes.first.fromMemberId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'choreId': choreId,
    'assigneeMemberId': assigneeMemberId,
    'dueDate': dateToJson(dueDate),
    'status': status.name,
    'completedAt': dateToJson(completedAt),
    'skipReason': skipReason,
    'changes': changes.map((c) => c.toJson()).toList(),
    'createdAt': dateToJson(createdAt),
  };

  factory ChoreAssignment.fromJson(Map<String, dynamic> json) =>
      ChoreAssignment(
        id: readString(json, 'id'),
        choreId: readString(json, 'choreId'),
        assigneeMemberId: readString(json, 'assigneeMemberId'),
        dueDate: readDate(json, 'dueDate'),
        status: readEnum(
          AssignmentStatus.values,
          json['status'],
          AssignmentStatus.pending,
        ),
        completedAt: readDateOrNull(json, 'completedAt'),
        skipReason: readStringOrNull(json, 'skipReason'),
        changes: readList(json['changes'], AssignmentChange.fromJson),
        createdAt: readDate(json, 'createdAt'),
      );
}

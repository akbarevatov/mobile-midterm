import 'json_helpers.dart';
import 'priority.dart';

enum IssueCategory {
  plumbing,
  electrical,
  appliance,
  internet,
  furniture,
  supplies,
  other,
}

enum IssueStatus { open, inProgress, resolved }

class HouseholdIssue {
  HouseholdIssue({
    required this.id,
    required this.householdId,
    required this.title,
    required this.category,
    required this.priority,
    required this.reportedById,
    required this.createdAt,
    this.description = '',
    this.status = IssueStatus.open,
    this.assigneeMemberId,
    this.resolvedAt,
    this.resolutionNotes = '',
  });

  final String id;
  final String householdId;
  String title;
  String description;
  IssueCategory category;
  Priority priority;
  IssueStatus status;
  String? assigneeMemberId;
  final String reportedById;
  final DateTime createdAt;
  DateTime? resolvedAt;
  String resolutionNotes;

  bool get isOpen => status != IssueStatus.resolved;

  Map<String, dynamic> toJson() => {
    'id': id,
    'householdId': householdId,
    'title': title,
    'description': description,
    'category': category.name,
    'priority': priority.name,
    'status': status.name,
    'assigneeMemberId': assigneeMemberId,
    'reportedById': reportedById,
    'createdAt': dateToJson(createdAt),
    'resolvedAt': dateToJson(resolvedAt),
    'resolutionNotes': resolutionNotes,
  };

  factory HouseholdIssue.fromJson(Map<String, dynamic> json) => HouseholdIssue(
    id: readString(json, 'id'),
    householdId: readString(json, 'householdId'),
    title: readString(json, 'title'),
    description: readStringOrNull(json, 'description') ?? '',
    category: readEnum(
      IssueCategory.values,
      json['category'],
      IssueCategory.other,
    ),
    priority: readEnum(Priority.values, json['priority'], Priority.medium),
    status: readEnum(IssueStatus.values, json['status'], IssueStatus.open),
    assigneeMemberId: readStringOrNull(json, 'assigneeMemberId'),
    reportedById: readStringOrNull(json, 'reportedById') ?? '',
    createdAt: readDate(json, 'createdAt'),
    resolvedAt: readDateOrNull(json, 'resolvedAt'),
    resolutionNotes: readStringOrNull(json, 'resolutionNotes') ?? '',
  );
}

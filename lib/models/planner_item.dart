import 'json_helpers.dart';
import 'priority.dart';

enum PlannerCategory {
  assignment,
  homework,
  exam,
  project,
  classSession,
  study,
  personalTask,
  event,
}

enum Recurrence { none, weekly }

extension PlannerCategoryInfo on PlannerCategory {
  bool get isAcademicDeadline =>
      this == PlannerCategory.assignment ||
      this == PlannerCategory.homework ||
      this == PlannerCategory.exam ||
      this == PlannerCategory.project;

  bool get isTimeBlock =>
      this == PlannerCategory.classSession ||
      this == PlannerCategory.study ||
      this == PlannerCategory.event;
}

class PlannerItem {
  PlannerItem({
    required this.id,
    required this.ownerMemberId,
    required this.title,
    required this.category,
    required this.dueAt,
    required this.priority,
    required this.createdAt,
    this.description = '',
    this.course = '',
    this.endAt,
    this.recurrence = Recurrence.none,
    this.isCompleted = false,
    this.completedAt,
  });

  final String id;
  final String ownerMemberId;
  String title;
  String description;
  PlannerCategory category;
  String course;
  DateTime dueAt;
  DateTime? endAt;
  Priority priority;
  Recurrence recurrence;
  bool isCompleted;
  DateTime? completedAt;
  final DateTime createdAt;

  bool get isRecurring => recurrence != Recurrence.none;

  bool get canBeCompleted => !isRecurring;

  Map<String, dynamic> toJson() => {
    'id': id,
    'ownerMemberId': ownerMemberId,
    'title': title,
    'description': description,
    'category': category.name,
    'course': course,
    'dueAt': dateToJson(dueAt),
    'endAt': dateToJson(endAt),
    'priority': priority.name,
    'recurrence': recurrence.name,
    'isCompleted': isCompleted,
    'completedAt': dateToJson(completedAt),
    'createdAt': dateToJson(createdAt),
  };

  factory PlannerItem.fromJson(Map<String, dynamic> json) => PlannerItem(
    id: readString(json, 'id'),
    ownerMemberId: readString(json, 'ownerMemberId'),
    title: readString(json, 'title'),
    description: readStringOrNull(json, 'description') ?? '',
    category: readEnum(
      PlannerCategory.values,
      json['category'],
      PlannerCategory.personalTask,
    ),
    course: readStringOrNull(json, 'course') ?? '',
    dueAt: readDate(json, 'dueAt'),
    endAt: readDateOrNull(json, 'endAt'),
    priority: readEnum(Priority.values, json['priority'], Priority.medium),
    recurrence: readEnum(
      Recurrence.values,
      json['recurrence'],
      Recurrence.none,
    ),
    isCompleted: readBool(json, 'isCompleted'),
    completedAt: readDateOrNull(json, 'completedAt'),
    createdAt: readDate(json, 'createdAt'),
  );
}

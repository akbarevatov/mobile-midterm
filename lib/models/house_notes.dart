import 'json_helpers.dart';

class HouseRule {
  HouseRule({
    required this.id,
    required this.householdId,
    required this.title,
    required this.createdById,
    required this.createdAt,
    this.details = '',
  });

  final String id;
  final String householdId;
  String title;
  String details;
  final String createdById;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'householdId': householdId,
    'title': title,
    'details': details,
    'createdById': createdById,
    'createdAt': dateToJson(createdAt),
  };

  factory HouseRule.fromJson(Map<String, dynamic> json) => HouseRule(
    id: readString(json, 'id'),
    householdId: readString(json, 'householdId'),
    title: readString(json, 'title'),
    details: readStringOrNull(json, 'details') ?? '',
    createdById: readStringOrNull(json, 'createdById') ?? '',
    createdAt: readDate(json, 'createdAt'),
  );
}

class Announcement {
  Announcement({
    required this.id,
    required this.householdId,
    required this.message,
    required this.authorId,
    required this.createdAt,
    this.isPinned = true,
  });

  final String id;
  final String householdId;
  String message;
  final String authorId;
  final DateTime createdAt;
  bool isPinned;

  Map<String, dynamic> toJson() => {
    'id': id,
    'householdId': householdId,
    'message': message,
    'authorId': authorId,
    'createdAt': dateToJson(createdAt),
    'isPinned': isPinned,
  };

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
    id: readString(json, 'id'),
    householdId: readString(json, 'householdId'),
    message: readString(json, 'message'),
    authorId: readStringOrNull(json, 'authorId') ?? '',
    createdAt: readDate(json, 'createdAt'),
    isPinned: readBool(json, 'isPinned', fallback: true),
  );
}

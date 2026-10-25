import 'json_helpers.dart';

enum EventType { guests, maintenance, meeting, shopping, cleaning, other }

class HouseholdEvent {
  HouseholdEvent({
    required this.id,
    required this.householdId,
    required this.title,
    required this.type,
    required this.startAt,
    required this.createdById,
    required this.createdAt,
    this.endAt,
    this.notes = '',
  });

  final String id;
  final String householdId;
  String title;
  EventType type;
  DateTime startAt;
  DateTime? endAt;
  String notes;
  final String createdById;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'householdId': householdId,
    'title': title,
    'type': type.name,
    'startAt': dateToJson(startAt),
    'endAt': dateToJson(endAt),
    'notes': notes,
    'createdById': createdById,
    'createdAt': dateToJson(createdAt),
  };

  factory HouseholdEvent.fromJson(Map<String, dynamic> json) => HouseholdEvent(
    id: readString(json, 'id'),
    householdId: readString(json, 'householdId'),
    title: readString(json, 'title'),
    type: readEnum(EventType.values, json['type'], EventType.other),
    startAt: readDate(json, 'startAt'),
    endAt: readDateOrNull(json, 'endAt'),
    notes: readStringOrNull(json, 'notes') ?? '',
    createdById: readStringOrNull(json, 'createdById') ?? '',
    createdAt: readDate(json, 'createdAt'),
  );
}

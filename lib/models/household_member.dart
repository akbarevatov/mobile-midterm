import 'json_helpers.dart';

class HouseholdMember {
  HouseholdMember({
    required this.id,
    required this.householdId,
    required this.displayName,
    required this.colorIndex,
    required this.createdAt,
    this.isActive = true,
  });

  final String id;
  final String householdId;
  String displayName;
  int colorIndex;
  bool isActive;
  final DateTime createdAt;

  String get initials {
    final parts = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'householdId': householdId,
    'displayName': displayName,
    'colorIndex': colorIndex,
    'isActive': isActive,
    'createdAt': dateToJson(createdAt),
  };

  factory HouseholdMember.fromJson(Map<String, dynamic> json) =>
      HouseholdMember(
        id: readString(json, 'id'),
        householdId: readString(json, 'householdId'),
        displayName: readString(json, 'displayName'),
        colorIndex: readInt(json, 'colorIndex', fallback: 0),
        isActive: readBool(json, 'isActive', fallback: true),
        createdAt: readDate(json, 'createdAt'),
      );
}

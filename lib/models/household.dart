import 'json_helpers.dart';

class Household {
  Household({required this.id, required this.name, required this.createdAt});

  final String id;
  String name;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': dateToJson(createdAt),
  };

  factory Household.fromJson(Map<String, dynamic> json) => Household(
    id: readString(json, 'id'),
    name: readString(json, 'name'),
    createdAt: readDate(json, 'createdAt'),
  );
}

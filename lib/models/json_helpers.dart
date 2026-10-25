DateTime readDate(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) throw FormatException('Missing date "$key"');
  return DateTime.parse(value);
}

DateTime? readDateOrNull(Map<String, dynamic> json, String key) {
  final value = json[key];
  return value is String ? DateTime.tryParse(value) : null;
}

String readString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) throw FormatException('Missing text "$key"');
  return value;
}

String? readStringOrNull(Map<String, dynamic> json, String key) {
  final value = json[key];
  return value is String ? value : null;
}

int readInt(Map<String, dynamic> json, String key, {int? fallback}) {
  final value = json[key];
  if (value is int) return value;
  if (fallback != null) return fallback;
  throw FormatException('Missing number "$key"');
}

bool readBool(Map<String, dynamic> json, String key, {bool fallback = false}) {
  final value = json[key];
  return value is bool ? value : fallback;
}

T readEnum<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}

List<String> readStringList(Object? value) {
  if (value is! List) return [];
  return value.whereType<String>().toList();
}

Map<String, int> readIntMap(Object? value) {
  if (value is! Map) return {};
  final result = <String, int>{};
  value.forEach((key, amount) {
    if (key is String && amount is int) result[key] = amount;
  });
  return result;
}

Map<String, String> readStringMap(Object? value) {
  if (value is! Map) return {};
  final result = <String, String>{};
  value.forEach((key, text) {
    if (key is String && text is String) result[key] = text;
  });
  return result;
}

List<T> readList<T>(Object? value, T Function(Map<String, dynamic>) fromJson) {
  if (value is! List) return [];
  return value
      .map((item) => fromJson(Map<String, dynamic>.from(item as Map)))
      .toList();
}

String? dateToJson(DateTime? date) => date?.toIso8601String();

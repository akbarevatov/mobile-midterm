import 'json_helpers.dart';

enum PaymentMethod { cash, card }

class Settlement {
  Settlement({
    required this.id,
    required this.householdId,
    required this.fromMemberId,
    required this.toMemberId,
    required this.amountUzs,
    required this.method,
    required this.date,
    required this.createdAt,
    required this.recordedById,
    this.note = '',
  });

  final String id;
  final String householdId;
  final String fromMemberId;
  final String toMemberId;
  final int amountUzs;
  final PaymentMethod method;
  final DateTime date;
  final DateTime createdAt;
  final String recordedById;
  final String note;

  Map<String, dynamic> toJson() => {
    'id': id,
    'householdId': householdId,
    'fromMemberId': fromMemberId,
    'toMemberId': toMemberId,
    'amountUzs': amountUzs,
    'method': method.name,
    'date': dateToJson(date),
    'createdAt': dateToJson(createdAt),
    'recordedById': recordedById,
    'note': note,
  };

  factory Settlement.fromJson(Map<String, dynamic> json) => Settlement(
    id: readString(json, 'id'),
    householdId: readString(json, 'householdId'),
    fromMemberId: readString(json, 'fromMemberId'),
    toMemberId: readString(json, 'toMemberId'),
    amountUzs: readInt(json, 'amountUzs'),
    method: readEnum(PaymentMethod.values, json['method'], PaymentMethod.cash),
    date: readDate(json, 'date'),
    createdAt: readDate(json, 'createdAt'),
    recordedById:
        readStringOrNull(json, 'recordedById') ??
        readString(json, 'fromMemberId'),
    note: readStringOrNull(json, 'note') ?? '',
  );
}

import 'expense.dart';
import 'json_helpers.dart';

enum BillType {
  rent,
  electricity,
  water,
  gas,
  internet,
  maintenance,
  subscription,
  other,
}

enum BillFrequency { once, monthly, quarterly }

class HouseholdBill {
  HouseholdBill({
    required this.id,
    required this.householdId,
    required this.name,
    required this.type,
    required this.expectedAmountUzs,
    required this.firstDueDate,
    required this.frequency,
    required this.responsibleMemberId,
    required this.participantMemberIds,
    required this.createdAt,
    this.splitMode = SplitMode.equal,
    Map<String, int>? customShares,
    this.notes = '',
    this.isActive = true,
  }) : customShares = customShares ?? {};

  final String id;
  final String householdId;
  String name;
  BillType type;
  int expectedAmountUzs;
  DateTime firstDueDate;
  BillFrequency frequency;
  String responsibleMemberId;
  List<String> participantMemberIds;
  SplitMode splitMode;
  Map<String, int> customShares;
  String notes;
  bool isActive;
  final DateTime createdAt;

  ExpenseCategory get expenseCategory => switch (type) {
    BillType.rent => ExpenseCategory.rent,
    BillType.internet => ExpenseCategory.internet,
    BillType.electricity ||
    BillType.water ||
    BillType.gas => ExpenseCategory.utilities,
    _ => ExpenseCategory.other,
  };

  Map<String, dynamic> toJson() => {
    'id': id,
    'householdId': householdId,
    'name': name,
    'type': type.name,
    'expectedAmountUzs': expectedAmountUzs,
    'firstDueDate': dateToJson(firstDueDate),
    'frequency': frequency.name,
    'responsibleMemberId': responsibleMemberId,
    'participantMemberIds': participantMemberIds,
    'splitMode': splitMode.name,
    'customShares': customShares,
    'notes': notes,
    'isActive': isActive,
    'createdAt': dateToJson(createdAt),
  };

  factory HouseholdBill.fromJson(Map<String, dynamic> json) => HouseholdBill(
    id: readString(json, 'id'),
    householdId: readString(json, 'householdId'),
    name: readString(json, 'name'),
    type: readEnum(BillType.values, json['type'], BillType.other),
    expectedAmountUzs: readInt(json, 'expectedAmountUzs'),
    firstDueDate: readDate(json, 'firstDueDate'),
    frequency: readEnum(
      BillFrequency.values,
      json['frequency'],
      BillFrequency.monthly,
    ),
    responsibleMemberId: readString(json, 'responsibleMemberId'),
    participantMemberIds: readStringList(json['participantMemberIds']),
    splitMode: readEnum(SplitMode.values, json['splitMode'], SplitMode.equal),
    customShares: readIntMap(json['customShares']),
    notes: readStringOrNull(json, 'notes') ?? '',
    isActive: readBool(json, 'isActive', fallback: true),
    createdAt: readDate(json, 'createdAt'),
  );
}

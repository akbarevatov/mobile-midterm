import 'json_helpers.dart';

enum ExpenseCategory {
  groceries,
  household,
  utilities,
  rent,
  internet,
  transport,
  eatingOut,
  other,
}

enum SplitMode { equal, custom }

class Expense {
  Expense({
    required this.id,
    required this.householdId,
    required this.title,
    required this.amountUzs,
    required this.payerMemberId,
    required this.splitAmountsByMemberId,
    required this.splitMode,
    required this.category,
    required this.date,
    required this.createdAt,
    required this.createdById,
    this.notes = '',
    this.billId,
    this.billPeriod,
    List<String>? shoppingItemIds,
  }) : shoppingItemIds = shoppingItemIds ?? [];

  final String id;
  final String householdId;
  final String title;
  final int amountUzs;
  final String payerMemberId;
  final Map<String, int> splitAmountsByMemberId;
  final SplitMode splitMode;
  final ExpenseCategory category;
  final DateTime date;
  final DateTime createdAt;
  final String createdById;
  final String notes;
  final String? billId;
  final DateTime? billPeriod;
  final List<String> shoppingItemIds;

  List<String> get participantMemberIds => splitAmountsByMemberId.keys.toList();

  int shareOf(String memberId) => splitAmountsByMemberId[memberId] ?? 0;

  bool get isBillPayment => billId != null && billPeriod != null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'householdId': householdId,
    'title': title,
    'amountUzs': amountUzs,
    'payerMemberId': payerMemberId,
    'splitAmountsByMemberId': splitAmountsByMemberId,
    'splitMode': splitMode.name,
    'category': category.name,
    'date': dateToJson(date),
    'createdAt': dateToJson(createdAt),
    'createdById': createdById,
    'notes': notes,
    'billId': billId,
    'billPeriod': dateToJson(billPeriod),
    'shoppingItemIds': shoppingItemIds,
  };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
    id: readString(json, 'id'),
    householdId: readString(json, 'householdId'),
    title: readString(json, 'title'),
    amountUzs: readInt(json, 'amountUzs'),
    payerMemberId: readString(json, 'payerMemberId'),
    splitAmountsByMemberId: readIntMap(json['splitAmountsByMemberId']),
    splitMode: readEnum(SplitMode.values, json['splitMode'], SplitMode.equal),
    category: readEnum(
      ExpenseCategory.values,
      json['category'],
      ExpenseCategory.other,
    ),
    date: readDate(json, 'date'),
    createdAt: readDate(json, 'createdAt'),
    createdById:
        readStringOrNull(json, 'createdById') ??
        readString(json, 'payerMemberId'),
    notes: readStringOrNull(json, 'notes') ?? '',
    billId: readStringOrNull(json, 'billId'),
    billPeriod: readDateOrNull(json, 'billPeriod'),
    shoppingItemIds: readStringList(json['shoppingItemIds']),
  );
}

import 'json_helpers.dart';

enum ShoppingCategory { food, drinks, cleaning, hygiene, household, other }

class ShoppingItem {
  ShoppingItem({
    required this.id,
    required this.householdId,
    required this.name,
    required this.category,
    required this.addedById,
    required this.createdAt,
    this.quantity = '',
    this.notes = '',
    this.buyerMemberId,
    this.isPurchased = false,
    this.purchasedById,
    this.purchasedAt,
  });

  final String id;
  final String householdId;
  String name;
  String quantity;
  String notes;
  ShoppingCategory category;
  final String addedById;
  String? buyerMemberId;
  bool isPurchased;
  String? purchasedById;
  DateTime? purchasedAt;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'householdId': householdId,
    'name': name,
    'quantity': quantity,
    'notes': notes,
    'category': category.name,
    'addedById': addedById,
    'buyerMemberId': buyerMemberId,
    'isPurchased': isPurchased,
    'purchasedById': purchasedById,
    'purchasedAt': dateToJson(purchasedAt),
    'createdAt': dateToJson(createdAt),
  };

  factory ShoppingItem.fromJson(Map<String, dynamic> json) => ShoppingItem(
    id: readString(json, 'id'),
    householdId: readString(json, 'householdId'),
    name: readString(json, 'name'),
    quantity: readStringOrNull(json, 'quantity') ?? '',
    notes: readStringOrNull(json, 'notes') ?? '',
    category: readEnum(
      ShoppingCategory.values,
      json['category'],
      ShoppingCategory.other,
    ),
    addedById: readStringOrNull(json, 'addedById') ?? '',
    buyerMemberId: readStringOrNull(json, 'buyerMemberId'),
    isPurchased: readBool(json, 'isPurchased'),
    purchasedById: readStringOrNull(json, 'purchasedById'),
    purchasedAt: readDateOrNull(json, 'purchasedAt'),
    createdAt: readDate(json, 'createdAt'),
  );
}

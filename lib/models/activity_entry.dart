import 'json_helpers.dart';

enum ActivityType {
  expenseAdded,
  expenseEdited,
  expenseDeleted,
  settlementRecorded,
  billPaid,
  choreCreated,
  choreCompleted,
  choreSkipped,
  choreReassigned,
  choreSwapped,
  shoppingAdded,
  shoppingPurchased,
  eventAdded,
  pollCreated,
  pollClosed,
  issueReported,
  issueResolved,
  announcementPosted,
  memberAdded,
}

class ActivityEntry {
  ActivityEntry({
    required this.id,
    required this.type,
    required this.actorId,
    required this.at,
    this.subject = '',
    this.amountUzs,
    this.otherMemberId,
  });

  final String id;
  final ActivityType type;
  final String actorId;
  final DateTime at;
  final String subject;
  final int? amountUzs;
  final String? otherMemberId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'actorId': actorId,
    'at': dateToJson(at),
    'subject': subject,
    'amountUzs': amountUzs,
    'otherMemberId': otherMemberId,
  };

  factory ActivityEntry.fromJson(Map<String, dynamic> json) => ActivityEntry(
    id: readString(json, 'id'),
    type: readEnum(
      ActivityType.values,
      json['type'],
      ActivityType.expenseAdded,
    ),
    actorId: readStringOrNull(json, 'actorId') ?? '',
    at: readDate(json, 'at'),
    subject: readStringOrNull(json, 'subject') ?? '',
    amountUzs: json['amountUzs'] is int ? json['amountUzs'] as int : null,
    otherMemberId: readStringOrNull(json, 'otherMemberId'),
  );
}

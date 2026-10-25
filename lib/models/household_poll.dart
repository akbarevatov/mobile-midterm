import 'json_helpers.dart';

class PollOption {
  PollOption({required this.id, required this.text});

  final String id;
  final String text;

  Map<String, dynamic> toJson() => {'id': id, 'text': text};

  factory PollOption.fromJson(Map<String, dynamic> json) =>
      PollOption(id: readString(json, 'id'), text: readString(json, 'text'));
}

class HouseholdPoll {
  HouseholdPoll({
    required this.id,
    required this.householdId,
    required this.question,
    required this.options,
    required this.createdById,
    required this.createdAt,
    Map<String, String>? votesByMemberId,
    this.deadline,
    this.closedAt,
    this.closedById,
  }) : votesByMemberId = votesByMemberId ?? {};

  final String id;
  final String householdId;
  final String question;
  final List<PollOption> options;
  final Map<String, String> votesByMemberId;
  final String createdById;
  final DateTime createdAt;
  final DateTime? deadline;
  DateTime? closedAt;
  String? closedById;

  bool isOpen(DateTime now) =>
      closedAt == null && (deadline == null || now.isBefore(deadline!));

  int votesFor(String optionId) =>
      votesByMemberId.values.where((id) => id == optionId).length;

  List<PollOption> leadingOptions() {
    if (votesByMemberId.isEmpty) return [];
    var best = 0;
    for (final option in options) {
      final count = votesFor(option.id);
      if (count > best) best = count;
    }
    return options.where((o) => votesFor(o.id) == best).toList();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'householdId': householdId,
    'question': question,
    'options': options.map((o) => o.toJson()).toList(),
    'votesByMemberId': votesByMemberId,
    'createdById': createdById,
    'createdAt': dateToJson(createdAt),
    'deadline': dateToJson(deadline),
    'closedAt': dateToJson(closedAt),
    'closedById': closedById,
  };

  factory HouseholdPoll.fromJson(Map<String, dynamic> json) => HouseholdPoll(
    id: readString(json, 'id'),
    householdId: readString(json, 'householdId'),
    question: readString(json, 'question'),
    options: readList(json['options'], PollOption.fromJson),
    votesByMemberId: readStringMap(json['votesByMemberId']),
    createdById: readStringOrNull(json, 'createdById') ?? '',
    createdAt: readDate(json, 'createdAt'),
    deadline: readDateOrNull(json, 'deadline'),
    closedAt: readDateOrNull(json, 'closedAt'),
    closedById: readStringOrNull(json, 'closedById'),
  );
}

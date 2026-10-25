enum SplitError { noParticipants, missingShare, nonPositiveShare, sumMismatch }

Map<String, int> splitEqually(int totalUzs, List<String> participantIds) {
  if (participantIds.isEmpty) {
    throw ArgumentError('An expense needs at least one participant');
  }
  if (totalUzs <= 0) throw ArgumentError('Amount must be positive');
  final count = participantIds.length;
  final base = totalUzs ~/ count;
  final remainder = totalUzs % count;
  final shares = <String, int>{};
  for (var i = 0; i < count; i++) {
    shares[participantIds[i]] = base + (i < remainder ? 1 : 0);
  }
  return shares;
}

int sumShares(Map<String, int> shares) =>
    shares.values.fold(0, (sum, value) => sum + value);

int unallocatedAmount(int totalUzs, Map<String, int?> shares) =>
    totalUzs - shares.values.fold<int>(0, (sum, value) => sum + (value ?? 0));

SplitError? validateCustomSplit(int totalUzs, Map<String, int?> shares) {
  if (shares.isEmpty) return SplitError.noParticipants;
  for (final value in shares.values) {
    if (value == null) return SplitError.missingShare;
    if (value <= 0) return SplitError.nonPositiveShare;
  }
  if (unallocatedAmount(totalUzs, shares) != 0) return SplitError.sumMismatch;
  return null;
}

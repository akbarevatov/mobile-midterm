import '../../models/expense.dart';
import '../../models/settlement.dart';

class MemberBalance {
  MemberBalance(this.memberId);

  final String memberId;
  int paidForExpenses = 0;
  int shareOfExpenses = 0;
  int paymentsSent = 0;
  int paymentsReceived = 0;

  int get net =>
      paidForExpenses - shareOfExpenses + paymentsSent - paymentsReceived;
}

class Transfer {
  const Transfer({
    required this.fromMemberId,
    required this.toMemberId,
    required this.amountUzs,
  });

  final String fromMemberId;
  final String toMemberId;
  final int amountUzs;

  @override
  String toString() => '$fromMemberId -> $toMemberId: $amountUzs';
}

Map<String, MemberBalance> computeBalances({
  required List<String> memberIds,
  required List<Expense> expenses,
  required List<Settlement> settlements,
}) {
  final balances = {for (final id in memberIds) id: MemberBalance(id)};
  MemberBalance of(String id) =>
      balances.putIfAbsent(id, () => MemberBalance(id));

  for (final expense in expenses) {
    of(expense.payerMemberId).paidForExpenses += expense.amountUzs;
    expense.splitAmountsByMemberId.forEach((memberId, share) {
      of(memberId).shareOfExpenses += share;
    });
  }
  for (final payment in settlements) {
    of(payment.fromMemberId).paymentsSent += payment.amountUzs;
    of(payment.toMemberId).paymentsReceived += payment.amountUzs;
  }
  return balances;
}

List<Transfer> suggestSettlements(
  Map<String, int> netByMember,
  List<String> memberOrder,
) {
  int orderOf(String id) {
    final index = memberOrder.indexOf(id);
    return index == -1 ? memberOrder.length : index;
  }

  final creditors = <_Open>[];
  final debtors = <_Open>[];
  netByMember.forEach((id, net) {
    if (net > 0) creditors.add(_Open(id, net));
    if (net < 0) debtors.add(_Open(id, -net));
  });

  int compare(_Open a, _Open b) {
    final byAmount = b.amount.compareTo(a.amount);
    return byAmount != 0 ? byAmount : orderOf(a.id).compareTo(orderOf(b.id));
  }

  creditors.sort(compare);
  debtors.sort(compare);

  final transfers = <Transfer>[];
  var d = 0;
  var c = 0;
  while (d < debtors.length && c < creditors.length) {
    final debtor = debtors[d];
    final creditor = creditors[c];
    final amount = debtor.amount < creditor.amount
        ? debtor.amount
        : creditor.amount;
    transfers.add(
      Transfer(
        fromMemberId: debtor.id,
        toMemberId: creditor.id,
        amountUzs: amount,
      ),
    );
    debtor.amount -= amount;
    creditor.amount -= amount;
    if (debtor.amount == 0) d++;
    if (creditor.amount == 0) c++;
  }
  return transfers;
}

class _Open {
  _Open(this.id, this.amount);
  final String id;
  int amount;
}

int totalSpending(List<Expense> expenses, {DateTime? from, DateTime? to}) {
  var total = 0;
  for (final expense in expenses) {
    if (from != null && expense.date.isBefore(from)) continue;
    if (to != null && !expense.date.isBefore(to)) continue;
    total += expense.amountUzs;
  }
  return total;
}

int shareSpending(
  List<Expense> expenses,
  String memberId, {
  DateTime? from,
  DateTime? to,
}) {
  var total = 0;
  for (final expense in expenses) {
    if (from != null && expense.date.isBefore(from)) continue;
    if (to != null && !expense.date.isBefore(to)) continue;
    total += expense.shareOf(memberId);
  }
  return total;
}

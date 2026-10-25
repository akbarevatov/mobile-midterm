import 'package:flutter/material.dart';

import '../../models/expense.dart';
import '../../models/settlement.dart';
import '../../widgets/common/app_scope.dart';
import '../../widgets/common/category_icons.dart';
import '../../widgets/common/dialogs.dart';
import 'expense_detail_screen.dart';

class ExpenseTile extends StatelessWidget {
  const ExpenseTile({super.key, required this.expense});

  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    final theme = Theme.of(context);
    final myShare = expense.shareOf(app.data.currentMemberId);
    final subtitle = [
      s.paidBy(app.memberName(expense.payerMemberId)),
      s.splitBetween(expense.participantMemberIds.length),
      s.dates.day(expense.date, now: app.today),
    ].join(' · ');

    return ListTile(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ExpenseDetailScreen(expenseId: expense.id),
        ),
      ),
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.secondaryContainer,
        foregroundColor: theme.colorScheme.onSecondaryContainer,
        child: Icon(
          expense.isBillPayment
              ? Icons.receipt_long_outlined
              : expenseIcon(expense.category),
          size: 20,
        ),
      ),
      title: Text(expense.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(s.money(expense.amountUzs), style: theme.textTheme.titleSmall),
          if (myShare > 0)
            Text(
              s.yourShare(s.money(myShare)),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class SettlementTile extends StatelessWidget {
  const SettlementTile({super.key, required this.settlement});

  final Settlement settlement;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        foregroundColor: theme.colorScheme.onSurfaceVariant,
        child: Icon(
          settlement.method == PaymentMethod.cash
              ? Icons.payments_outlined
              : Icons.credit_card,
          size: 20,
        ),
      ),
      title: Text(
        s.paymentLine(
          app.memberName(settlement.fromMemberId),
          app.memberName(settlement.toMemberId),
        ),
      ),
      subtitle: Text(
        [
          s.paymentMethod(settlement.method),
          s.dates.day(settlement.date, now: app.today),
          if (settlement.note.isNotEmpty) settlement.note,
        ].join(' · '),
      ),
      trailing: Text(
        s.money(settlement.amountUzs),
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      onLongPress: () => _confirmDelete(context),
      onTap: () => _confirmDelete(context),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final app = context.app;
    final s = context.s;
    final ok = await confirmAction(
      context,
      title: s.deletePaymentTitle,
      message: s.deletePaymentBody,
      confirmLabel: s.delete,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    app.deleteSettlement(settlement.id);
    showSnack(context, s.deleted);
  }
}

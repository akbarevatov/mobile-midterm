import 'package:flutter/material.dart';

import '../../services/calculations/bill_schedule.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/app_scope.dart';
import '../../widgets/common/category_icons.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/status_pill.dart';
import 'bill_detail_screen.dart';
import 'bill_form_screen.dart';

class BillsScreen extends StatelessWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    final theme = Theme.of(context);
    final overviews = app.billOverviewList;
    final month = app.today;

    return Scaffold(
      appBar: AppBar(title: Text(s.billsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'bills-fab',
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const BillFormScreen())),
        icon: const Icon(Icons.add),
        label: Text(s.addBill),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.fabClearance),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.page),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.expectedThisMonth,
                            style: theme.textTheme.labelMedium,
                          ),
                          _FitText(
                            s.money(expectedForMonth(app.data.bills, month)),
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.paidThisMonth,
                            style: theme.textTheme.labelMedium,
                          ),
                          _FitText(
                            s.money(
                              paidForMonth(
                                app.data.bills,
                                app.data.expenses,
                                month,
                              ),
                            ),
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (overviews.isEmpty)
            EmptyState(
              icon: Icons.receipt_long_outlined,
              title: s.emptyBills,
              message: s.emptyBillsHint,
              actionLabel: s.addBill,
              onAction: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const BillFormScreen())),
            ),
          for (final o in overviews) BillTile(overview: o),
        ],
      ),
    );
  }
}

class BillTile extends StatelessWidget {
  const BillTile({super.key, required this.overview});

  final BillOverview overview;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    final bill = overview.bill;
    return ListTile(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => BillDetailScreen(billId: bill.id)),
      ),
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
        child: Icon(billIcon(bill.type), size: 20),
      ),
      title: Text(bill.name),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '${s.money(bill.expectedAmountUzs)} · ${s.responsible(app.memberName(bill.responsibleMemberId))}',
            ),
            BillStatusPill(overview: overview),
          ],
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

class BillStatusPill extends StatelessWidget {
  const BillStatusPill({super.key, required this.overview});

  final BillOverview overview;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final due = overview.currentDue;
    final rel = due == null ? '' : s.dates.relativeDay(due, context.app.today);
    return switch (overview.status) {
      BillStatus.overdue => StatusPill(
        label: s.overdueSince(rel),
        icon: Icons.warning_amber_rounded,
        tone: PillTone.overdue,
      ),
      BillStatus.dueSoon => StatusPill(
        label: rel,
        icon: Icons.schedule,
        tone: PillTone.soon,
      ),
      BillStatus.upcoming => StatusPill(label: rel, icon: Icons.event_outlined),
      BillStatus.settled => StatusPill(
        label: s.billStatus(BillStatus.settled),
        icon: Icons.check,
        tone: PillTone.done,
      ),
    };
  }
}

class _FitText extends StatelessWidget {
  const _FitText(this.text, {this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: Alignment.centerLeft,
    child: Text(text, style: style),
  );
}

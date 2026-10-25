import 'package:flutter/material.dart';

import '../../services/calculations/bill_schedule.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/app_scope.dart';
import '../../widgets/common/category_icons.dart';
import '../../widgets/common/dialogs.dart';
import '../../widgets/common/info_banner.dart';
import '../../widgets/common/member_avatar.dart';
import '../../widgets/common/missing_item_screen.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/status_pill.dart';
import '../money/expense_form_screen.dart';
import '../money/money_tiles.dart';
import 'bill_form_screen.dart';
import 'bills_screen.dart';

class BillDetailScreen extends StatelessWidget {
  const BillDetailScreen({super.key, required this.billId});

  final String billId;

  void _markPaid(BuildContext context, DateTime due) {
    final app = context.app;
    final s = context.s;
    final bill = app.billById(billId)!;
    final active = app.activeMemberIds;
    final participants = bill.participantMemberIds
        .where(active.contains)
        .toList();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExpenseFormScreen(
          draft: ExpenseDraft(
            title: '${bill.name} — ${s.dates.monthName(due)}',
            amountUzs: bill.expectedAmountUzs,
            category: bill.expenseCategory,
            payerId: active.contains(bill.responsibleMemberId)
                ? bill.responsibleMemberId
                : app.data.currentMemberId,
            participantIds: participants.isEmpty ? null : participants,
            splitMode: bill.splitMode,
            customShares: bill.customShares,
            billId: bill.id,
            billPeriod: due,
            date: app.now(),
          ),
        ),
      ),
    );
  }

  Future<void> _archive(BuildContext context) async {
    final app = context.app;
    final s = context.s;
    final ok = await confirmAction(
      context,
      title: s.archiveBill,
      message: s.archiveBillBody,
      confirmLabel: s.archive,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    Navigator.of(context).pop();
    app.archiveBill(billId);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    final theme = Theme.of(context);
    final bill = app.billById(billId);
    if (bill == null) return const MissingItemScreen();
    final overview = overviewOf(bill, app.data.expenses, app.today);
    final payments = billPayments(bill, app.data.expenses);
    final due = overview.currentDue;

    return Scaffold(
      appBar: AppBar(
        title: Text(bill.name),
        actions: [
          IconButton(
            tooltip: s.edit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => BillFormScreen(existing: bill)),
            ),
          ),
          if (bill.isActive)
            IconButton(
              tooltip: s.archive,
              icon: const Icon(Icons.archive_outlined),
              onPressed: () => _archive(context),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.sm,
              AppSpacing.page,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    StatusPill(
                      label: s.billTypeLabel(bill.type),
                      icon: billIcon(bill.type),
                    ),
                    StatusPill(
                      label: s.billFrequency(bill.frequency),
                      icon: Icons.event_repeat,
                    ),
                    StatusPill(
                      label: s.shared,
                      icon: Icons.home_outlined,
                      tone: PillTone.shared,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  s.expectedAmount,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  s.money(bill.expectedAmountUzs),
                  style: theme.textTheme.headlineSmall,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      due == null
                          ? s.billStatus(BillStatus.settled)
                          : s.dueOn(
                              s.dates.dayWithWeekday(due, now: app.today),
                            ),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    BillStatusPill(overview: overview),
                    if (due != null && bill.isActive) ...[
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _markPaid(context, due),
                          icon: const Icon(Icons.check),
                          label: Text(s.markPaid),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      InfoBanner(text: s.markPaidNote),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.lg,
              AppSpacing.page,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.responsible(app.memberName(bill.responsibleMemberId))),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(s.whoSplits, style: theme.textTheme.bodySmall),
                    for (final id in bill.participantMemberIds)
                      MemberAvatar(member: app.member(id), radius: 12),
                  ],
                ),
                if (bill.notes.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(bill.notes, style: theme.textTheme.bodyMedium),
                ],
              ],
            ),
          ),
          SectionHeader(title: s.paymentHistory),
          if (payments.isEmpty)
            ListTile(title: Text(s.noPayments))
          else
            for (final e in payments) ExpenseTile(expense: e),
        ],
      ),
    );
  }
}

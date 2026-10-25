import 'package:flutter/material.dart';

import '../../models/expense.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/app_scope.dart';
import '../../widgets/common/category_icons.dart';
import '../../widgets/common/dialogs.dart';
import '../../widgets/common/member_avatar.dart';
import '../../widgets/common/missing_item_screen.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/status_pill.dart';
import '../household/bill_detail_screen.dart';
import 'expense_form_screen.dart';

class ExpenseDetailScreen extends StatelessWidget {
  const ExpenseDetailScreen({super.key, required this.expenseId});

  final String expenseId;

  Future<void> _delete(BuildContext context) async {
    final app = context.app;
    final s = context.s;
    final expense = app.expenseById(expenseId);
    if (expense == null) return;
    final bill = app.billById(expense.billId);
    final ok = await confirmAction(
      context,
      title: s.deleteExpenseTitle,
      message: bill != null
          ? s.deleteBillExpenseBody(bill.name)
          : s.deleteExpenseBody,
      confirmLabel: s.delete,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    Navigator.of(context).pop();
    app.deleteExpense(expenseId);
    showSnack(context, s.deleted);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    final theme = Theme.of(context);
    final expense = app.expenseById(expenseId);
    if (expense == null) return const MissingItemScreen();
    final bill = app.billById(expense.billId);
    final hasItems = expense.shoppingItemIds.any(
      (id) => app.shoppingItemById(id) != null,
    );
    final payer = expense.payerMemberId;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.expenseDetails),
        actions: [
          IconButton(
            tooltip: s.edit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ExpenseFormScreen(existing: expense),
              ),
            ),
          ),
          IconButton(
            tooltip: s.delete,
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _delete(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.page),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusPill(
                  label: s.expenseCategory(expense.category),
                  icon: expenseIcon(expense.category),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(expense.title, style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  s.money(expense.amountUzs),
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${s.paidBy(app.memberName(payer))} · ${s.dates.dayWithWeekday(expense.date, now: app.today)}',
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  '${s.splitHow} ${expense.splitMode == SplitMode.equal ? s.splitEqual : s.splitCustom}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          SectionHeader(
            title: s.whoOwesWhat,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.sm,
              AppSpacing.page,
              0,
            ),
          ),
          for (final entry in expense.splitAmountsByMemberId.entries)
            ListTile(
              leading: MemberAvatar(member: app.member(entry.key), radius: 16),
              title: Text(app.memberName(entry.key)),
              subtitle: Text(
                entry.key == payer
                    ? s.payerOwnShare
                    : s.owesTo(s.money(entry.value), app.memberName(payer)),
              ),
              trailing: Text(
                s.money(entry.value),
                style: theme.textTheme.titleSmall,
              ),
            ),
          if (bill != null) ...[
            SectionHeader(title: s.linkedBill),
            ListTile(
              leading: Icon(billIcon(bill.type)),
              title: Text(bill.name),
              subtitle: expense.billPeriod == null
                  ? null
                  : Text(
                      s.periodOf(
                        s.dates.day(expense.billPeriod!, now: app.today),
                      ),
                    ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BillDetailScreen(billId: bill.id),
                ),
              ),
            ),
          ],
          if (hasItems) ...[
            SectionHeader(title: s.linkedItems),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final id in expense.shoppingItemIds)
                    if (app.shoppingItemById(id) != null)
                      Chip(
                        avatar: const Icon(
                          Icons.shopping_bag_outlined,
                          size: 18,
                        ),
                        label: Text(app.shoppingItemById(id)!.name),
                      ),
                ],
              ),
            ),
          ],
          if (expense.notes.isNotEmpty) ...[
            SectionHeader(title: s.notesOptional),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              child: Text(expense.notes),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.xl,
              AppSpacing.page,
              0,
            ),
            child: Text(
              s.addedBy(
                app.memberName(expense.createdById),
                s.dates.dayAndTime(expense.createdAt, now: app.today),
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

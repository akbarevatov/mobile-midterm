import 'package:flutter/material.dart';

import '../../models/expense.dart';
import '../../models/settlement.dart';
import '../../services/calculations/bill_schedule.dart';
import '../../theme/app_spacing.dart';
import '../../utils/date_math.dart';
import '../../widgets/common/app_scope.dart';
import '../../widgets/common/balance_text.dart';
import '../../widgets/common/category_icons.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/member_avatar.dart';
import '../../widgets/common/section_header.dart';
import '../household/bills_screen.dart';
import 'expense_form_screen.dart';
import 'money_tiles.dart';
import 'record_payment_sheet.dart';

class MoneyScreen extends StatelessWidget {
  const MoneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.moneyTitle),
          actions: [
            IconButton(
              tooltip: s.billsShortcut,
              icon: const Icon(Icons.receipt_long_outlined),
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const BillsScreen())),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: s.tabBalances),
              Tab(text: s.tabHistory),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'money-fab',
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ExpenseFormScreen())),
          icon: const Icon(Icons.add),
          label: Text(s.addExpense),
        ),
        body: const TabBarView(children: [_BalancesTab(), _HistoryTab()]),
      ),
    );
  }
}

class _BalancesTab extends StatelessWidget {
  const _BalancesTab();

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    final theme = Theme.of(context);
    final balances = app.balances;
    final suggestions = app.settlementSuggestions;
    final month = app.today;
    final me = app.data.currentMemberId;
    final myPaidThisMonth = app.data.expenses
        .where(
          (e) =>
              e.payerMemberId == me &&
              !e.date.isBefore(startOfMonth(month)) &&
              e.date.isBefore(addMonths(startOfMonth(month), 1)),
        )
        .fold<int>(0, (sum, e) => sum + e.amountUzs);
    final members = app.members
        .where((m) => m.isActive || (balances[m.id]?.net ?? 0) != 0)
        .toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.fabClearance),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.lg,
            AppSpacing.page,
            0,
          ),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${s.householdSpending} · ${s.dates.monthYear(month)}',
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    s.money(app.spendingInMonth(month)),
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniStat(
                          label: s.myShare,
                          value: s.money(app.myShareInMonth(month)),
                        ),
                      ),
                      Expanded(
                        child: _MiniStat(
                          label: s.iPaid,
                          value: s.money(myPaidThisMonth),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        SectionHeader(title: s.whoOwesWhom),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            0,
            AppSpacing.page,
            AppSpacing.sm,
          ),
          child: Text(s.balanceFormula, style: theme.textTheme.bodySmall),
        ),
        for (final m in members)
          ListTile(
            leading: MemberAvatar(member: m),
            title: Text(
              m.id == me ? '${m.displayName} (${s.you})' : m.displayName,
            ),
            subtitle: Text(
              s.paidAndShare(
                s.money(balances[m.id]?.paidForExpenses ?? 0),
                s.money(balances[m.id]?.shareOfExpenses ?? 0),
              ),
              maxLines: 2,
            ),
            trailing: BalanceText(net: balances[m.id]?.net ?? 0),
          ),
        SectionHeader(title: s.settleUpTitle),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            0,
            AppSpacing.page,
            AppSpacing.sm,
          ),
          child: Text(s.settleUpNote, style: theme.textTheme.bodySmall),
        ),
        if (suggestions.isEmpty)
          ListTile(
            leading: Icon(
              Icons.check_circle_outline,
              color: context.colors.positive,
            ),
            title: Text(s.noDebts),
          )
        else
          for (final t in suggestions)
            ListTile(
              leading: SizedBox(
                width: 64,
                child: Row(
                  children: [
                    MemberAvatar(
                      member: app.member(t.fromMemberId),
                      radius: 14,
                    ),
                    const Icon(Icons.arrow_forward, size: 14),
                    MemberAvatar(member: app.member(t.toMemberId), radius: 14),
                  ],
                ),
              ),
              title: Text(
                '${app.memberName(t.fromMemberId)} → ${app.memberName(t.toMemberId)}',
              ),
              subtitle: Text(
                s.money(t.amountUzs),
                style: theme.textTheme.titleSmall,
              ),
              trailing: TextButton(
                onPressed: () => showRecordPaymentSheet(
                  context,
                  fromId: t.fromMemberId,
                  toId: t.toMemberId,
                  amount: t.amountUzs,
                ),
                child: Text(s.recordShort),
              ),
            ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.sm,
            AppSpacing.page,
            0,
          ),
          child: OutlinedButton.icon(
            onPressed: () => showRecordPaymentSheet(context),
            icon: const Icon(Icons.swap_horiz),
            label: Text(s.recordPayment),
          ),
        ),
        SectionHeader(title: s.billsShortcut),
        ListTile(
          leading: const Icon(Icons.receipt_long_outlined),
          title: Text(
            '${s.expectedThisMonth}: ${s.money(expectedForMonth(app.data.bills, month))}',
          ),
          subtitle: Text(
            '${s.paidThisMonth}: ${s.money(paidForMonth(app.data.bills, app.data.expenses, month))}',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () =>
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const BillsScreen())),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(value, style: theme.textTheme.titleSmall),
      ],
    );
  }
}

enum _Period { all, thisMonth, lastMonth, custom }

class _HistoryTab extends StatefulWidget {
  const _HistoryTab();

  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  _Period _period = _Period.all;
  DateTimeRange? _customRange;
  ExpenseCategory? _category;

  (DateTime?, DateTime?) _range(DateTime today) => switch (_period) {
    _Period.all => (null, null),
    _Period.thisMonth => (
      startOfMonth(today),
      addMonths(startOfMonth(today), 1),
    ),
    _Period.lastMonth => (
      addMonths(startOfMonth(today), -1),
      startOfMonth(today),
    ),
    _Period.custom => (
      _customRange?.start,
      _customRange == null ? null : addDays(_customRange!.end, 1),
    ),
  };

  Future<void> _pickCustomRange() async {
    final today = context.app.today;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(today.year - 2),
      lastDate: addDays(today, 365),
      initialDateRange:
          _customRange ?? DateTimeRange(start: addDays(today, -30), end: today),
    );
    if (picked != null) {
      setState(() {
        _customRange = picked;
        _period = _Period.custom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    final theme = Theme.of(context);
    final (from, to) = _range(app.today);

    bool inRange(DateTime d) =>
        (from == null || !d.isBefore(from)) && (to == null || d.isBefore(to));

    final expenses = app.expensesNewestFirst.where(
      (e) => inRange(e.date) && (_category == null || e.category == _category),
    );
    final settlements = _category == null
        ? app.settlementsNewestFirst.where((p) => inRange(p.date))
        : const <Settlement>[];
    final rows = <Object>[...expenses, ...settlements]
      ..sort((a, b) => _dateOf(b).compareTo(_dateOf(a)));
    final total = expenses.fold<int>(0, (sum, e) => sum + e.amountUzs);
    final hasFilters = _period != _Period.all || _category != null;

    final periodLabels = {
      _Period.all: s.allTime,
      _Period.thisMonth: s.thisMonth,
      _Period.lastMonth: s.lastMonth,
    };

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.page,
                ),
                child: Row(
                  children: [
                    for (final entry in periodLabels.entries)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: ChoiceChip(
                          label: Text(entry.value),
                          selected: _period == entry.key,
                          onSelected: (_) =>
                              setState(() => _period = entry.key),
                        ),
                      ),
                    ChoiceChip(
                      avatar: const Icon(Icons.date_range, size: 18),
                      label: Text(
                        _period == _Period.custom && _customRange != null
                            ? '${s.dates.day(_customRange!.start)} – ${s.dates.day(_customRange!.end)}'
                            : s.customRange,
                      ),
                      selected: _period == _Period.custom,
                      onSelected: (_) => _pickCustomRange(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.page,
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: FilterChip(
                        label: Text(s.allCategories),
                        selected: _category == null,
                        onSelected: (_) => setState(() => _category = null),
                      ),
                    ),
                    for (final c in ExpenseCategory.values)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: FilterChip(
                          avatar: Icon(expenseIcon(c), size: 18),
                          label: Text(s.expenseCategory(c)),
                          selected: _category == c,
                          onSelected: (selected) =>
                              setState(() => _category = selected ? c : null),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  AppSpacing.md,
                  AppSpacing.page,
                  AppSpacing.xs,
                ),
                child: Text(
                  s.filteredTotal(s.money(total)),
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ],
          ),
        ),
        if (rows.isEmpty)
          SliverToBoxAdapter(
            child: app.data.expenses.isEmpty
                ? EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: s.noTransactions,
                    message: s.noTransactionsHint,
                    actionLabel: s.addExpense,
                    onAction: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ExpenseFormScreen(),
                      ),
                    ),
                  )
                : EmptyState(
                    icon: Icons.filter_alt_off_outlined,
                    title: s.noMatches,
                    actionLabel: hasFilters ? s.clearFilters : null,
                    onAction: () => setState(() {
                      _period = _Period.all;
                      _category = null;
                    }),
                  ),
          )
        else
          SliverList.builder(
            itemCount: rows.length,
            itemBuilder: (context, index) {
              final row = rows[index];
              return row is Expense
                  ? ExpenseTile(expense: row)
                  : SettlementTile(settlement: row as Settlement);
            },
          ),
        const SliverToBoxAdapter(
          child: SizedBox(height: AppSpacing.fabClearance),
        ),
      ],
    );
  }

  DateTime _dateOf(Object row) =>
      row is Expense ? row.date : (row as Settlement).date;
}

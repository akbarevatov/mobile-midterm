import 'package:flutter/material.dart';

import '../../models/expense.dart';
import '../../services/calculations/money_split.dart';
import '../../theme/app_spacing.dart';
import '../../utils/date_math.dart';
import '../../utils/id_generator.dart';
import '../../utils/validators.dart';
import '../../widgets/common/app_scope.dart';
import '../../widgets/common/category_icons.dart';
import '../../widgets/common/dialogs.dart';
import '../../widgets/common/info_banner.dart';
import '../../widgets/common/member_avatar.dart';
import '../../widgets/forms/amount_field.dart';
import '../../widgets/forms/member_selectors.dart';
import '../../widgets/forms/picker_fields.dart';

class ExpenseDraft {
  const ExpenseDraft({
    this.title = '',
    this.amountUzs,
    this.category = ExpenseCategory.groceries,
    this.payerId,
    this.participantIds,
    this.splitMode = SplitMode.equal,
    this.customShares = const {},
    this.billId,
    this.billPeriod,
    this.shoppingItemIds = const [],
    this.date,
    this.notes = '',
  });

  final String title;
  final int? amountUzs;
  final ExpenseCategory category;
  final String? payerId;
  final List<String>? participantIds;
  final SplitMode splitMode;
  final Map<String, int> customShares;
  final String? billId;
  final DateTime? billPeriod;
  final List<String> shoppingItemIds;
  final DateTime? date;
  final String notes;

  factory ExpenseDraft.fromExpense(Expense e) => ExpenseDraft(
    title: e.title,
    amountUzs: e.amountUzs,
    category: e.category,
    payerId: e.payerMemberId,
    participantIds: e.participantMemberIds,
    splitMode: e.splitMode,
    customShares: e.splitAmountsByMemberId,
    billId: e.billId,
    billPeriod: e.billPeriod,
    shoppingItemIds: e.shoppingItemIds,
    date: e.date,
    notes: e.notes,
  );
}

class ExpenseFormScreen extends StatefulWidget {
  const ExpenseFormScreen({super.key, this.existing, this.draft});

  final Expense? existing;
  final ExpenseDraft? draft;

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  final Map<String, TextEditingController> _shareControllers = {};

  late ExpenseCategory _category;
  late DateTime _date;
  String? _payerId;
  List<String> _participants = [];
  SplitMode _splitMode = SplitMode.equal;
  bool _submitted = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final app = context.app;
    final draft = widget.existing != null
        ? ExpenseDraft.fromExpense(widget.existing!)
        : (widget.draft ?? const ExpenseDraft());
    _title.text = draft.title;
    if (draft.amountUzs != null) {
      _amount.text = formatAmountInput(draft.amountUzs!);
    }
    _notes.text = draft.notes;
    _category = draft.category;
    _date = draft.date ?? app.now();
    _payerId = draft.payerId ?? app.data.currentMemberId;
    _participants =
        draft.participantIds ?? app.activeMembers.map((m) => m.id).toList();
    _splitMode = draft.splitMode;
    for (final id in _participants) {
      final share = draft.customShares[id];
      _shareControllers[id] = TextEditingController(
        text: share == null ? '' : formatAmountInput(share),
      );
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _notes.dispose();
    for (final c in _shareControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  int? get _amountValue =>
      validateAmount(_amount.text) == null ? parseAmount(_amount.text) : null;

  Map<String, int?> get _customShares => {
    for (final id in _participants)
      id: parseAmount(_shareControllers[id]?.text),
  };

  Map<String, int>? get _computedShares {
    final amount = _amountValue;
    if (amount == null || _participants.isEmpty) return null;
    if (_splitMode == SplitMode.equal) {
      return splitEqually(amount, _participants);
    }
    final shares = _customShares;
    if (validateCustomSplit(amount, shares) != null) return null;
    return shares.map((k, v) => MapEntry(k, v!));
  }

  String? get _payerError => _payerId == null ? context.s.choosePayer : null;

  String? get _splitErrorText {
    if (_participants.isEmpty) return context.s.chooseParticipants;
    final amount = _amountValue;
    if (_splitMode == SplitMode.custom && amount != null) {
      final error = validateCustomSplit(amount, _customShares);
      if (error != null) return context.s.splitError(error);
    }
    return null;
  }

  void _setParticipants(List<String> ids) {
    setState(() {
      _participants = ids;
      for (final id in ids) {
        _shareControllers.putIfAbsent(id, TextEditingController.new);
      }
    });
  }

  void _fillEqually() {
    final amount = _amountValue;
    if (amount == null || _participants.isEmpty) return;
    final shares = splitEqually(amount, _participants);
    setState(() {
      shares.forEach(
        (id, value) => _shareControllers[id]!.text = formatAmountInput(value),
      );
    });
  }

  Future<void> _pickDate() async {
    final picked = await pickDate(context, _date);
    if (picked != null) {
      setState(() => _date = withTime(picked, _date.hour, _date.minute));
    }
  }

  void _save() {
    setState(() => _submitted = true);
    final formOk = _formKey.currentState!.validate();
    final shares = _computedShares;
    if (!formOk ||
        _payerError != null ||
        _splitErrorText != null ||
        shares == null) {
      showSnack(context, context.s.fixErrors);
      return;
    }
    final app = context.app;
    final s = context.s;
    final existing = widget.existing;
    final draft = widget.draft;
    final expense = Expense(
      id: existing?.id ?? newId('exp'),
      householdId: app.data.household.id,
      title: _title.text.trim(),
      amountUzs: _amountValue!,
      payerMemberId: _payerId!,
      splitAmountsByMemberId: shares,
      splitMode: _splitMode,
      category: _category,
      date: _date,
      createdAt: existing?.createdAt ?? app.now(),
      createdById: existing?.createdById ?? app.data.currentMemberId,
      notes: _notes.text.trim(),
      billId: existing?.billId ?? draft?.billId,
      billPeriod: existing?.billPeriod ?? draft?.billPeriod,
      shoppingItemIds: List.of(
        existing?.shoppingItemIds ?? draft?.shoppingItemIds ?? const [],
      ),
    );
    try {
      app.saveExpense(expense);
    } on StateError {
      showSnack(context, s.billAlreadyPaid);
      return;
    }
    Navigator.of(context).pop(true);
    showSnack(context, s.expenseSaved);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    final theme = Theme.of(context);
    final existing = widget.existing;
    final billId = existing?.billId ?? widget.draft?.billId;
    final billPeriod = existing?.billPeriod ?? widget.draft?.billPeriod;
    final linkedItems =
        existing?.shoppingItemIds ?? widget.draft?.shoppingItemIds ?? const [];
    final selectableMembers = app.members
        .where(
          (m) => m.isActive || _participants.contains(m.id) || m.id == _payerId,
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(existing == null ? s.newExpense : s.editExpense),
        actions: [TextButton(onPressed: _save, child: Text(s.save))],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.sm,
            AppSpacing.page,
            AppSpacing.xxl,
          ),
          children: [
            if (billId != null && billPeriod != null) ...[
              InfoBanner(
                icon: Icons.receipt_long_outlined,
                text: s.billLink(
                  app.billById(billId)?.name ?? '',
                  s.periodOf(s.dates.day(billPeriod, now: app.today)),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (linkedItems.isNotEmpty) ...[
              InfoBanner(
                icon: Icons.shopping_cart_outlined,
                text: s.shoppingLink(linkedItems.length),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            TextFormField(
              controller: _title,
              decoration: InputDecoration(
                labelText: s.expenseTitle,
                hintText: s.expenseTitleHint,
              ),
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  s.textError(validateRequiredText(v, maxLength: 80)),
            ),
            const SizedBox(height: AppSpacing.lg),
            AmountField(
              controller: _amount,
              label: s.amount,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.lg),
            PickerField(
              label: s.date,
              value: s.dates.dayWithWeekday(_date, now: app.today),
              icon: Icons.calendar_today_outlined,
              onTap: _pickDate,
            ),
            const SizedBox(height: AppSpacing.xl),
            FieldLabel(s.category),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final c in ExpenseCategory.values)
                  ChoiceChip(
                    avatar: Icon(expenseIcon(c), size: 18),
                    label: Text(s.expenseCategory(c)),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            FieldLabel(s.whoPaid),
            MemberChoiceChips(
              members: selectableMembers,
              selectedId: _payerId,
              onSelected: (id) => setState(() => _payerId = id),
            ),
            if (_submitted) FieldError(_payerError),
            const SizedBox(height: AppSpacing.xl),
            FieldLabel(s.whoShares),
            MemberMultiSelect(
              members: selectableMembers,
              selectedIds: _participants,
              onChanged: _setParticipants,
            ),
            const SizedBox(height: AppSpacing.xl),
            FieldLabel(s.splitHow),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<SplitMode>(
                segments: [
                  ButtonSegment(
                    value: SplitMode.equal,
                    label: Text(s.splitEqual),
                    icon: const Icon(Icons.drag_handle),
                  ),
                  ButtonSegment(
                    value: SplitMode.custom,
                    label: Text(s.splitCustom),
                    icon: const Icon(Icons.tune),
                  ),
                ],
                selected: {_splitMode},
                showSelectedIcon: false,
                onSelectionChanged: (set) {
                  setState(() => _splitMode = set.first);
                  if (_splitMode == SplitMode.custom &&
                      _customShares.values.every((v) => v == null)) {
                    _fillEqually();
                  }
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildSharesCard(theme),
            if (_submitted) FieldError(_splitErrorText),
            const SizedBox(height: AppSpacing.xl),
            TextFormField(
              controller: _notes,
              decoration: InputDecoration(labelText: s.notesOptional),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  (v ?? '').length > 300 ? s.textTooLong(300) : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(onPressed: _save, child: Text(s.save)),
          ],
        ),
      ),
    );
  }

  Widget _buildSharesCard(ThemeData theme) {
    final app = context.app;
    final s = context.s;
    final amount = _amountValue;
    if (_participants.isEmpty) return const SizedBox.shrink();

    final rows = <Widget>[];
    if (_splitMode == SplitMode.equal) {
      final shares = amount == null
          ? null
          : splitEqually(amount, _participants);
      for (final id in _participants) {
        rows.add(
          _ShareRow(
            memberName: app.memberName(id),
            avatar: MemberAvatar(member: app.member(id), radius: 14),
            trailing: Text(
              shares == null ? '—' : s.money(shares[id]!),
              style: theme.textTheme.titleSmall,
            ),
          ),
        );
      }
    } else {
      for (final id in _participants) {
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                MemberAvatar(member: app.member(id), radius: 14),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    app.memberName(id),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: 168,
                  child: TextFormField(
                    controller: _shareControllers[id],
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandsFormatter()],
                    textAlign: TextAlign.end,
                    decoration: InputDecoration(
                      isDense: true,
                      suffixText: s.currency,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    Widget? status;
    if (amount != null && _splitMode == SplitMode.custom) {
      final left = unallocatedAmount(amount, _customShares);
      final (text, color, icon) = left == 0
          ? (s.allocatedOk, context.colors.positive, Icons.check_circle_outline)
          : left > 0
          ? (
              s.unallocated(s.money(left)),
              context.colors.warning,
              Icons.pie_chart_outline,
            )
          : (
              s.overAllocated(s.money(-left)),
              theme.colorScheme.error,
              Icons.error_outline,
            );
      status = Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(onPressed: _fillEqually, child: Text(s.fillEqually)),
        ],
      );
    }

    final shares = _computedShares;
    String? summary;
    if (shares != null && _payerId != null && amount != null) {
      final payerShare = shares[_payerId] ?? 0;
      final others = amount - payerShare;
      summary = others == 0
          ? s.noDebtCreated
          : s.payerGetsBack(app.memberName(_payerId), s.money(others));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.shares, style: theme.textTheme.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            ...rows,
            ?status,
            if (summary != null) ...[
              const Divider(height: AppSpacing.lg),
              Text(
                summary,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (_splitMode == SplitMode.equal &&
                amount != null &&
                amount % _participants.length != 0) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(s.remainderNote, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShareRow extends StatelessWidget {
  const _ShareRow({
    required this.memberName,
    required this.avatar,
    required this.trailing,
  });

  final String memberName;
  final Widget avatar;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          avatar,
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(memberName, overflow: TextOverflow.ellipsis)),
          trailing,
        ],
      ),
    );
  }
}

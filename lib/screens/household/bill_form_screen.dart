import 'package:flutter/material.dart';

import '../../models/expense.dart';
import '../../models/household_bill.dart';
import '../../services/calculations/bill_schedule.dart';
import '../../services/calculations/money_split.dart';
import '../../theme/app_spacing.dart';
import '../../utils/id_generator.dart';
import '../../utils/validators.dart';
import '../../widgets/common/app_scope.dart';
import '../../widgets/common/category_icons.dart';
import '../../widgets/common/dialogs.dart';
import '../../widgets/common/member_avatar.dart';
import '../../widgets/forms/amount_field.dart';
import '../../widgets/forms/member_selectors.dart';
import '../../widgets/forms/picker_fields.dart';

class BillFormScreen extends StatefulWidget {
  const BillFormScreen({super.key, this.existing});

  final HouseholdBill? existing;

  @override
  State<BillFormScreen> createState() => _BillFormScreenState();
}

class _BillFormScreenState extends State<BillFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  final Map<String, TextEditingController> _shares = {};
  BillType _type = BillType.internet;
  BillFrequency _frequency = BillFrequency.monthly;
  late DateTime _firstDue;
  String? _responsible;
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
    final bill = widget.existing;
    if (bill != null) {
      _name.text = bill.name;
      _amount.text = formatAmountInput(bill.expectedAmountUzs);
      _notes.text = bill.notes;
      _type = bill.type;
      _frequency = bill.frequency;
      _firstDue = bill.firstDueDate;
      _responsible = bill.responsibleMemberId;
      _participants = List.of(bill.participantMemberIds);
      _splitMode = bill.splitMode;
      bill.customShares.forEach(
        (id, v) =>
            _shares[id] = TextEditingController(text: formatAmountInput(v)),
      );
    } else {
      _firstDue = app.today;
      _responsible = app.data.currentMemberId;
      _participants = app.activeMembers.map((m) => m.id).toList();
    }
    for (final id in _participants) {
      _shares.putIfAbsent(id, TextEditingController.new);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _notes.dispose();
    for (final c in _shares.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _hasPayments =>
      widget.existing != null &&
      billPayments(widget.existing!, context.app.data.expenses).isNotEmpty;

  Map<String, int?> get _customShares => {
    for (final id in _participants) id: parseAmount(_shares[id]?.text),
  };

  String? get _splitError {
    final s = context.s;
    if (_participants.isEmpty) return s.chooseParticipants;
    if (_splitMode == SplitMode.custom) {
      final amount = parseAmount(_amount.text);
      if (amount == null) return null;
      final error = validateCustomSplit(amount, _customShares);
      if (error != null) return s.splitError(error);
    }
    return null;
  }

  void _save() {
    setState(() => _submitted = true);
    final s = context.s;
    if (!_formKey.currentState!.validate() ||
        _splitError != null ||
        _responsible == null) {
      showSnack(context, s.fixErrors);
      return;
    }
    final app = context.app;
    final existing = widget.existing;
    final bill = HouseholdBill(
      id: existing?.id ?? newId('bill'),
      householdId: app.data.household.id,
      name: _name.text.trim(),
      type: _type,
      expectedAmountUzs: parseAmount(_amount.text)!,
      firstDueDate: _firstDue,
      frequency: _frequency,
      responsibleMemberId: _responsible!,
      participantMemberIds: _participants,
      splitMode: _splitMode,
      customShares: _splitMode == SplitMode.custom
          ? _customShares.map((k, v) => MapEntry(k, v!))
          : {},
      notes: _notes.text.trim(),
      isActive: existing?.isActive ?? true,
      createdAt: existing?.createdAt ?? app.now(),
    );
    app.saveBill(bill);
    Navigator.of(context).pop();
    showSnack(context, s.billSaved);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    final members = app.members
        .where((m) => m.isActive || _participants.contains(m.id))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? s.newBill : s.editBill),
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
            FieldLabel(s.billType),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final t in BillType.values)
                  ChoiceChip(
                    avatar: Icon(billIcon(t), size: 18),
                    label: Text(s.billTypeLabel(t)),
                    selected: _type == t,
                    onSelected: (_) => setState(() {
                      _type = t;
                      if (_name.text.trim().isEmpty) {
                        _name.text = s.billTypeLabel(t);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: s.titleLabel),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) => s.textError(
                validateRequiredText(v, maxLength: 50),
                maxLength: 50,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AmountField(
              controller: _amount,
              label: s.expectedAmount,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.lg),
            PickerField(
              label: s.billDueLabel,
              value: s.dates.dayWithWeekday(_firstDue, now: app.today),
              icon: Icons.calendar_today_outlined,
              helperText: _hasPayments ? s.billAnchorLocked : null,
              onTap: _hasPayments
                  ? null
                  : () async {
                      final picked = await pickDate(context, _firstDue);
                      if (picked != null) setState(() => _firstDue = picked);
                    },
            ),
            const SizedBox(height: AppSpacing.lg),
            DropdownButtonFormField<BillFrequency>(
              initialValue: _frequency,
              decoration: InputDecoration(
                labelText: s.billFrequencyLabel,
                prefixIcon: const Icon(Icons.event_repeat),
              ),
              items: [
                for (final f in BillFrequency.values)
                  DropdownMenuItem(value: f, child: Text(s.billFrequency(f))),
              ],
              onChanged: _hasPayments
                  ? null
                  : (f) => setState(() => _frequency = f ?? _frequency),
            ),
            const SizedBox(height: AppSpacing.xl),
            FieldLabel(s.whoPays),
            MemberChoiceChips(
              members: members,
              selectedId: _responsible,
              onSelected: (id) => setState(() => _responsible = id),
            ),
            const SizedBox(height: AppSpacing.xl),
            FieldLabel(s.whoSplits),
            MemberMultiSelect(
              members: members,
              selectedIds: _participants,
              onChanged: (ids) => setState(() {
                _participants = ids;
                for (final id in ids) {
                  _shares.putIfAbsent(id, TextEditingController.new);
                }
              }),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<SplitMode>(
                segments: [
                  ButtonSegment(
                    value: SplitMode.equal,
                    label: Text(s.splitEqual),
                  ),
                  ButtonSegment(
                    value: SplitMode.custom,
                    label: Text(s.splitCustom),
                  ),
                ],
                selected: {_splitMode},
                showSelectedIcon: false,
                onSelectionChanged: (set) =>
                    setState(() => _splitMode = set.first),
              ),
            ),
            if (_splitMode == SplitMode.custom) ...[
              const SizedBox(height: AppSpacing.md),
              FieldLabel(s.customSharesForBill),
              for (final id in _participants)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      MemberAvatar(member: app.member(id), radius: 14),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: Text(app.memberName(id))),
                      SizedBox(
                        width: 150,
                        child: TextFormField(
                          controller: _shares[id],
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
            ],
            if (_submitted) FieldError(_splitError),
            const SizedBox(height: AppSpacing.xl),
            TextFormField(
              controller: _notes,
              decoration: InputDecoration(labelText: s.notesOptional),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  (v ?? '').length > 200 ? s.textTooLong(200) : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(onPressed: _save, child: Text(s.save)),
          ],
        ),
      ),
    );
  }
}

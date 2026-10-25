import 'package:flutter/material.dart';

import '../../models/settlement.dart';
import '../../theme/app_spacing.dart';
import '../../utils/validators.dart';
import '../../widgets/common/app_scope.dart';
import '../../widgets/common/dialogs.dart';
import '../../widgets/common/info_banner.dart';
import '../../widgets/forms/amount_field.dart';
import '../../widgets/forms/member_selectors.dart';
import '../../widgets/forms/picker_fields.dart';

Future<void> showRecordPaymentSheet(
  BuildContext context, {
  String? fromId,
  String? toId,
  int? amount,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) =>
        _RecordPaymentForm(fromId: fromId, toId: toId, amount: amount),
  );
}

class _RecordPaymentForm extends StatefulWidget {
  const _RecordPaymentForm({this.fromId, this.toId, this.amount});

  final String? fromId;
  final String? toId;
  final int? amount;

  @override
  State<_RecordPaymentForm> createState() => _RecordPaymentFormState();
}

class _RecordPaymentFormState extends State<_RecordPaymentForm> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String? _from;
  String? _to;
  PaymentMethod _method = PaymentMethod.cash;
  DateTime _date = DateTime.now();
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _from = widget.fromId;
    _to = widget.toId;
    if (widget.amount != null) _amount.text = formatAmountInput(widget.amount!);
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  String? get _peopleError {
    final s = context.s;
    if (_from == null || _to == null) return s.fieldRequired;
    if (_from == _to) return s.samePerson;
    return null;
  }

  void _save() {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate() || _peopleError != null) return;
    final app = context.app;
    final s = context.s;
    app.recordSettlement(
      fromMemberId: _from!,
      toMemberId: _to!,
      amountUzs: parseAmount(_amount.text)!,
      method: _method,
      date: _date,
      note: _note.text,
    );
    Navigator.pop(context);
    showSnack(context, s.paymentRecorded);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    final members = app.members
        .where((m) => m.isActive || m.id == _from || m.id == _to)
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            0,
            AppSpacing.page,
            AppSpacing.xl,
          ),
          children: [
            Text(
              s.recordPayment,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            InfoBanner(
              text: s.recordPaymentNote,
              icon: Icons.handshake_outlined,
            ),
            const SizedBox(height: AppSpacing.lg),
            FieldLabel(s.paymentFrom),
            MemberChoiceChips(
              members: members,
              selectedId: _from,
              onSelected: (id) => setState(() => _from = id),
            ),
            const SizedBox(height: AppSpacing.lg),
            FieldLabel(s.paymentTo),
            MemberChoiceChips(
              members: members,
              selectedId: _to,
              onSelected: (id) => setState(() => _to = id),
            ),
            if (_submitted) FieldError(_peopleError),
            const SizedBox(height: AppSpacing.lg),
            AmountField(controller: _amount, label: s.amount),
            const SizedBox(height: AppSpacing.lg),
            FieldLabel(s.paymentMethodLabel),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<PaymentMethod>(
                segments: [
                  for (final m in PaymentMethod.values)
                    ButtonSegment(value: m, label: Text(s.paymentMethod(m))),
                ],
                selected: {_method},
                showSelectedIcon: false,
                onSelectionChanged: (set) =>
                    setState(() => _method = set.first),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PickerField(
              label: s.date,
              value: s.dates.dayWithWeekday(_date, now: app.today),
              icon: Icons.calendar_today_outlined,
              onTap: () async {
                final picked = await pickDate(context, _date, last: app.today);
                if (picked != null) setState(() => _date = picked);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _note,
              decoration: InputDecoration(labelText: s.notesOptional),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  (v ?? '').length > 120 ? s.textTooLong(120) : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(onPressed: _save, child: Text(s.recordPayment)),
          ],
        ),
      ),
    );
  }
}

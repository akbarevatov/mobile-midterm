import 'package:flutter/material.dart';

import '../../models/chore.dart';
import '../../models/priority.dart';
import '../../theme/app_spacing.dart';
import '../../utils/validators.dart';
import '../../widgets/common/app_scope.dart';
import '../../widgets/common/dialogs.dart';
import '../../widgets/common/info_banner.dart';
import '../../widgets/forms/member_selectors.dart';
import '../../widgets/forms/picker_fields.dart';

class ChoreFormScreen extends StatefulWidget {
  const ChoreFormScreen({super.key, this.existing});

  final Chore? existing;

  @override
  State<ChoreFormScreen> createState() => _ChoreFormScreenState();
}

class _ChoreFormScreenState extends State<ChoreFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _notes = TextEditingController();
  ChoreFrequency _frequency = ChoreFrequency.weekly;
  Priority _priority = Priority.medium;
  List<String> _eligible = [];
  DateTime? _firstDue;
  String? _assigneeId;
  bool _submitted = false;
  bool _initialized = false;

  bool get _isEdit => widget.existing != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final app = context.app;
    final chore = widget.existing;
    if (chore != null) {
      _title.text = chore.title;
      _notes.text = chore.notes;
      _frequency = chore.frequency;
      _priority = chore.priority;
      _eligible = List.of(chore.eligibleMemberIds);
    } else {
      _eligible = app.activeMembers.map((m) => m.id).toList();
      _firstDue = app.today;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  String? get _eligibleError =>
      _eligible.isEmpty ? context.s.eligibleError : null;

  String? get _dueError {
    if (_isEdit) return null;
    if (_firstDue == null) return context.s.fieldRequired;
    if (_firstDue!.isBefore(context.app.today)) return context.s.pastDateError;
    return null;
  }

  void _save() {
    setState(() => _submitted = true);
    final app = context.app;
    final s = context.s;
    if (!_formKey.currentState!.validate() ||
        _eligibleError != null ||
        _dueError != null) {
      showSnack(context, s.fixErrors);
      return;
    }
    if (_isEdit) {
      app.updateChore(
        widget.existing!,
        title: _title.text,
        frequency: _frequency,
        eligibleMemberIds: _eligible,
        priority: _priority,
        notes: _notes.text,
      );
    } else {
      final assignee = _assigneeId != null && _eligible.contains(_assigneeId)
          ? _assigneeId
          : null;
      app.createChore(
        title: _title.text,
        frequency: _frequency,
        eligibleMemberIds: _eligible,
        priority: _priority,
        firstDueDate: _firstDue!,
        assigneeId: assignee,
        notes: _notes.text,
      );
    }
    Navigator.of(context).pop();
    showSnack(context, s.choreSaved);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    final members = app.activeMembers;
    final suggested = _eligible.isEmpty
        ? null
        : app.suggestFirstAssignee(_eligible);
    final current = _isEdit
        ? app.currentAssignmentFor(widget.existing!.id)
        : null;
    final assigneeOutside =
        current != null && !_eligible.contains(current.assigneeMemberId);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? s.editChore : s.newChore),
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
            TextFormField(
              controller: _title,
              decoration: InputDecoration(
                labelText: s.choreTitleLabel,
                hintText: s.choreTitleHint,
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) => s.textError(
                validateRequiredText(v, maxLength: 60),
                maxLength: 60,
              ),
            ),
            if (!_isEdit) ...[
              const SizedBox(height: AppSpacing.md),
              FieldLabel(s.quickPick),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final title in s.commonChores)
                    ActionChip(
                      label: Text(title),
                      onPressed: () => setState(() => _title.text = title),
                    ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            DropdownButtonFormField<ChoreFrequency>(
              initialValue: _frequency,
              decoration: InputDecoration(
                labelText: s.frequencyLabel,
                prefixIcon: const Icon(Icons.event_repeat),
              ),
              items: [
                for (final f in ChoreFrequency.values)
                  DropdownMenuItem(value: f, child: Text(s.frequency(f))),
              ],
              onChanged: (f) => setState(() => _frequency = f ?? _frequency),
            ),
            const SizedBox(height: AppSpacing.xl),
            FieldLabel(s.eligibleLabel),
            MemberMultiSelect(
              members: members,
              selectedIds: _eligible,
              onChanged: (ids) => setState(() => _eligible = ids),
            ),
            if (_submitted) FieldError(_eligibleError),
            if (assigneeOutside) ...[
              const SizedBox(height: AppSpacing.md),
              InfoBanner(
                text: s.ineligibleAssigneeNote,
                icon: Icons.warning_amber,
              ),
            ],
            if (!_isEdit) ...[
              const SizedBox(height: AppSpacing.xl),
              PickerField(
                label: s.firstDueLabel,
                value: _firstDue == null
                    ? s.noDate
                    : s.dates.dayWithWeekday(_firstDue!, now: app.today),
                icon: Icons.calendar_today_outlined,
                errorText: _submitted ? _dueError : null,
                onTap: () async {
                  final picked = await pickDate(
                    context,
                    _firstDue ?? app.today,
                    first: app.today,
                  );
                  if (picked != null) setState(() => _firstDue = picked);
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              FieldLabel(s.firstAssigneeLabel),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  ChoiceChip(
                    avatar: const Icon(Icons.autorenew, size: 18),
                    label: Text(
                      s.autoAssign(
                        suggested == null ? '—' : app.memberName(suggested),
                      ),
                    ),
                    selected:
                        _assigneeId == null || !_eligible.contains(_assigneeId),
                    onSelected: (_) => setState(() => _assigneeId = null),
                  ),
                  for (final m in members.where(
                    (m) => _eligible.contains(m.id),
                  ))
                    ChoiceChip(
                      label: Text(m.displayName),
                      selected: _assigneeId == m.id,
                      onSelected: (_) => setState(() => _assigneeId = m.id),
                    ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            FieldLabel(s.priority),
            PriorityPicker(
              value: _priority,
              onChanged: (p) => setState(() => _priority = p),
            ),
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

import 'package:flutter/material.dart';

import '../../models/planner_item.dart';
import '../../models/priority.dart';
import '../../theme/app_spacing.dart';
import '../../utils/date_math.dart';
import '../../utils/id_generator.dart';
import '../../utils/validators.dart';
import '../../widgets/common/app_scope.dart';
import '../../widgets/common/category_icons.dart';
import '../../widgets/common/dialogs.dart';
import '../../widgets/common/info_banner.dart';
import '../../widgets/forms/member_selectors.dart';
import '../../widgets/forms/picker_fields.dart';

class PlannerFormScreen extends StatefulWidget {
  const PlannerFormScreen({
    super.key,
    this.existing,
    this.initialCategory,
    this.initialWeekly = false,
  });

  final PlannerItem? existing;
  final PlannerCategory? initialCategory;
  final bool initialWeekly;

  @override
  State<PlannerFormScreen> createState() => _PlannerFormScreenState();
}

class _PlannerFormScreenState extends State<PlannerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _course = TextEditingController();
  PlannerCategory _category = PlannerCategory.assignment;
  Priority _priority = Priority.medium;
  late DateTime _date;
  TimeOfDay _start = const TimeOfDay(hour: 23, minute: 59);
  TimeOfDay? _end;
  bool _weekly = false;
  bool _submitted = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final item = widget.existing;
    final app = context.app;
    if (item != null) {
      _title.text = item.title;
      _description.text = item.description;
      _course.text = item.course;
      _category = item.category;
      _priority = item.priority;
      _date = dateOnly(item.dueAt);
      _start = TimeOfDay.fromDateTime(item.dueAt);
      _end = item.endAt == null ? null : TimeOfDay.fromDateTime(item.endAt!);
      _weekly = item.isRecurring;
    } else {
      _category = widget.initialCategory ?? PlannerCategory.assignment;
      _weekly = widget.initialWeekly;
      _date = addDays(app.today, 1);
      if (_category.isTimeBlock) _start = const TimeOfDay(hour: 9, minute: 0);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _course.dispose();
    super.dispose();
  }

  DateTime get _startDateTime => withTime(_date, _start.hour, _start.minute);

  DateTime? get _endDateTime =>
      _end == null ? null : withTime(_date, _end!.hour, _end!.minute);

  String? get _endError {
    final end = _endDateTime;
    if (end == null) return null;
    return end.isAfter(_startDateTime) ? null : context.s.endBeforeStart;
  }

  bool get _canRepeat => _category.isTimeBlock;

  void _selectCategory(PlannerCategory c) {
    setState(() {
      final wasBlock = _category.isTimeBlock;
      _category = c;
      if (!c.isTimeBlock) {
        _weekly = false;
        _end = null;
      }
      if (c.isTimeBlock &&
          !wasBlock &&
          _start == const TimeOfDay(hour: 23, minute: 59)) {
        _start = const TimeOfDay(hour: 9, minute: 0);
      }
    });
  }

  void _save() {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate() || _endError != null) {
      showSnack(context, context.s.fixErrors);
      return;
    }
    final app = context.app;
    final existing = widget.existing;
    final item = PlannerItem(
      id: existing?.id ?? newId('plan'),
      ownerMemberId: existing?.ownerMemberId ?? app.data.currentMemberId,
      title: _title.text.trim(),
      description: _description.text.trim(),
      course: _course.text.trim(),
      category: _category,
      dueAt: _startDateTime,
      endAt: _endDateTime,
      priority: _priority,
      recurrence: _weekly && _canRepeat ? Recurrence.weekly : Recurrence.none,
      isCompleted: existing?.isCompleted ?? false,
      completedAt: existing?.completedAt,
      createdAt: existing?.createdAt ?? app.now(),
    );
    app.savePlannerItem(item);
    Navigator.of(context).pop();
    showSnack(context, context.s.saved);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    final isPast =
        !_weekly &&
        _startDateTime.isBefore(app.now()) &&
        !(widget.existing?.isCompleted ?? false);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null ? s.newPlannerItem : s.editPlannerItem,
        ),
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
            InfoBanner(text: s.onlyYouSee, icon: Icons.lock_outline),
            const SizedBox(height: AppSpacing.lg),
            FieldLabel(s.category),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final c in PlannerCategory.values)
                  ChoiceChip(
                    avatar: Icon(plannerIcon(c), size: 18),
                    label: Text(s.plannerCategory(c)),
                    selected: _category == c,
                    onSelected: (_) => _selectCategory(c),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            TextFormField(
              controller: _title,
              decoration: InputDecoration(labelText: s.titleLabel),
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  s.textError(validateRequiredText(v, maxLength: 80)),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _course,
              decoration: InputDecoration(
                labelText: s.courseOptional,
                prefixIcon: const Icon(Icons.school_outlined),
              ),
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v ?? '').length > 60 ? s.textTooLong(60) : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            if (_canRepeat)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s.repeatWeekly),
                subtitle: Text(s.repeatWeeklyHint),
                value: _weekly,
                onChanged: (v) => setState(() => _weekly = v),
              ),
            PickerField(
              label: _weekly ? s.startLabel : s.dueDate,
              value: _weekly
                  ? s.dates.weekdayName(_date.weekday)
                  : s.dates.dayWithWeekday(_date, now: app.today),
              icon: Icons.calendar_today_outlined,
              helperText: isPast ? s.pastDueHint : null,
              onTap: () async {
                final picked = await pickDate(context, _date);
                if (picked != null) setState(() => _date = picked);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: PickerField(
                    label: _canRepeat ? s.startLabel : s.time,
                    value: s.dates.time(_startDateTime),
                    icon: Icons.schedule,
                    onTap: () async {
                      final picked = await pickTime(context, _start);
                      if (picked != null) setState(() => _start = picked);
                    },
                  ),
                ),
                if (_canRepeat) ...[
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: PickerField(
                      label: s.endOptional,
                      value: _endDateTime == null
                          ? '—'
                          : s.dates.time(_endDateTime!),
                      icon: Icons.schedule_outlined,
                      errorText: _submitted ? _endError : null,
                      onClear: _end == null
                          ? null
                          : () => setState(() => _end = null),
                      onTap: () async {
                        final picked = await pickTime(
                          context,
                          _end ??
                              TimeOfDay(
                                hour: (_start.hour + 1) % 24,
                                minute: _start.minute,
                              ),
                        );
                        if (picked != null) setState(() => _end = picked);
                      },
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            FieldLabel(s.priority),
            PriorityPicker(
              value: _priority,
              onChanged: (p) => setState(() => _priority = p),
            ),
            const SizedBox(height: AppSpacing.xl),
            TextFormField(
              controller: _description,
              decoration: InputDecoration(labelText: s.descriptionOptional),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  (v ?? '').length > 400 ? s.textTooLong(400) : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(onPressed: _save, child: Text(s.save)),
          ],
        ),
      ),
    );
  }
}

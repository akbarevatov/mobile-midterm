import 'package:flutter/material.dart';

import '../../models/household_event.dart';
import '../../services/calculations/bill_schedule.dart';
import '../../theme/app_spacing.dart';
import '../../utils/date_math.dart';
import '../../utils/id_generator.dart';
import '../../utils/validators.dart';
import '../../widgets/common/app_scope.dart';
import '../../widgets/common/category_icons.dart';
import '../../widgets/common/dialogs.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/info_banner.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/status_pill.dart';
import '../../widgets/forms/member_selectors.dart';
import '../../widgets/forms/picker_fields.dart';
import '../planner/planner_tiles.dart';
import 'bills_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  bool _events = true;
  bool _bills = true;
  bool _chores = true;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    final today = app.today;
    final horizon = addDays(today, 30);

    final entries = <(DateTime, Widget)>[
      if (_events)
        for (final e in app.eventsChronological.where(
          (e) => !e.startAt.isBefore(today) && e.startAt.isBefore(horizon),
        ))
          (e.startAt, SharedEventTile(event: e)),
      if (_bills)
        for (final o in app.billOverviewList.where(
          (o) => o.currentDue != null && o.currentDue!.isBefore(horizon),
        ))
          (
            o.currentDue!.isBefore(today) ? today : o.currentDue!,
            _BillEntry(overview: o),
          ),
      if (_chores)
        for (final a in app.pendingAssignments.where(
          (a) => a.dueDate.isBefore(horizon),
        ))
          (
            a.dueDate.isBefore(today) ? today : a.dueDate,
            SharedChoreTile(assignment: a),
          ),
    ]..sort((a, b) => a.$1.compareTo(b.$1));

    final children = <Widget>[];
    DateTime? day;
    for (final (date, tile) in entries) {
      if (day == null || !isSameDay(day, date)) {
        day = dateOnly(date);
        children.add(
          SectionHeader(
            title:
                '${s.dates.relativeDayCapitalized(day, today)} · ${s.dates.dayWithWeekday(day, now: today)}',
          ),
        );
      }
      children.add(tile);
    }

    return Scaffold(
      appBar: AppBar(title: Text(s.calendarTitle)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'calendar-fab',
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const EventFormScreen())),
        icon: const Icon(Icons.add),
        label: Text(s.addEvent),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.fabClearance),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.md,
              AppSpacing.page,
              0,
            ),
            child: Wrap(
              spacing: AppSpacing.sm,
              children: [
                FilterChip(
                  label: Text(s.showEvents),
                  selected: _events,
                  onSelected: (v) => setState(() => _events = v),
                ),
                FilterChip(
                  label: Text(s.showBills),
                  selected: _bills,
                  onSelected: (v) => setState(() => _bills = v),
                ),
                FilterChip(
                  label: Text(s.showChores),
                  selected: _chores,
                  onSelected: (v) => setState(() => _chores = v),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.sm,
              AppSpacing.page,
              0,
            ),
            child: Text(
              s.next30Days,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (children.isEmpty)
            EmptyState(
              icon: Icons.event_available_outlined,
              title: s.emptyCalendar,
            )
          else
            ...children,
        ],
      ),
    );
  }
}

class _BillEntry extends StatelessWidget {
  const _BillEntry({required this.overview});

  final BillOverview overview;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return ListTile(
      onTap: () =>
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const BillsScreen())),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: context.colors.sharedContainer,
        foregroundColor: context.colors.shared,
        child: Icon(billIcon(overview.bill.type), size: 20),
      ),
      title: Text(s.billDueEntry(overview.bill.name)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(s.money(overview.bill.expectedAmountUzs)),
            BillStatusPill(overview: overview),
            StatusPill(
              label: s.shared,
              icon: Icons.home_outlined,
              tone: PillTone.shared,
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showEventSheet(BuildContext context, String eventId) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      final app = sheetContext.app;
      final s = sheetContext.s;
      final theme = Theme.of(sheetContext);
      final event = app.data.events.where((e) => e.id == eventId).firstOrNull;
      if (event == null) return const SizedBox.shrink();
      final end = event.endAt;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            0,
            AppSpacing.page,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  StatusPill(
                    label: s.eventType(event.type),
                    icon: eventIcon(event.type),
                  ),
                  StatusPill(
                    label: s.shared,
                    icon: Icons.home_outlined,
                    tone: PillTone.shared,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(event.title, style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${s.dates.dayWithWeekday(event.startAt, now: app.today)}, ${s.dates.time(event.startAt)}${end == null ? '' : '–${s.dates.time(end)}'}',
              ),
              if (event.notes.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(event.notes),
              ],
              const SizedBox(height: AppSpacing.xs),
              Text(
                s.addedBy(
                  app.memberName(event.createdById),
                  s.dates.day(event.createdAt, now: app.today),
                ),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EventFormScreen(existing: event),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(s.edit),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(sheetContext);
                        final ok = await confirmAction(
                          context,
                          title: s.deleteEventTitle,
                          message: event.title,
                          confirmLabel: s.delete,
                          destructive: true,
                        );
                        if (ok) app.deleteEvent(event.id);
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: Text(s.delete),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

class EventFormScreen extends StatefulWidget {
  const EventFormScreen({super.key, this.existing});

  final HouseholdEvent? existing;

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _notes = TextEditingController();
  EventType _type = EventType.meeting;
  late DateTime _date;
  TimeOfDay _start = const TimeOfDay(hour: 19, minute: 0);
  TimeOfDay? _end;
  bool _submitted = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final e = widget.existing;
    if (e != null) {
      _title.text = e.title;
      _notes.text = e.notes;
      _type = e.type;
      _date = dateOnly(e.startAt);
      _start = TimeOfDay.fromDateTime(e.startAt);
      _end = e.endAt == null ? null : TimeOfDay.fromDateTime(e.endAt!);
    } else {
      _date = addDays(context.app.today, 1);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  DateTime get _startAt => withTime(_date, _start.hour, _start.minute);
  DateTime? get _endAt =>
      _end == null ? null : withTime(_date, _end!.hour, _end!.minute);
  String? get _endError => _endAt != null && !_endAt!.isAfter(_startAt)
      ? context.s.endBeforeStart
      : null;

  void _save() {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate() || _endError != null) {
      showSnack(context, context.s.fixErrors);
      return;
    }
    final app = context.app;
    final existing = widget.existing;
    app.saveEvent(
      HouseholdEvent(
        id: existing?.id ?? newId('event'),
        householdId: app.data.household.id,
        title: _title.text.trim(),
        type: _type,
        startAt: _startAt,
        endAt: _endAt,
        notes: _notes.text.trim(),
        createdById: existing?.createdById ?? app.data.currentMemberId,
        createdAt: existing?.createdAt ?? app.now(),
      ),
    );
    Navigator.of(context).pop();
    showSnack(context, context.s.saved);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? s.newEvent : s.editEvent),
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
            InfoBanner(text: s.sharedEventNote, icon: Icons.home_outlined),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _title,
              decoration: InputDecoration(labelText: s.eventTitle),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  s.textError(validateRequiredText(v, maxLength: 80)),
            ),
            const SizedBox(height: AppSpacing.lg),
            FieldLabel(s.eventTypeLabel),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final t in EventType.values)
                  ChoiceChip(
                    avatar: Icon(eventIcon(t), size: 18),
                    label: Text(s.eventType(t)),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            PickerField(
              label: s.date,
              value: s.dates.dayWithWeekday(_date, now: app.today),
              icon: Icons.calendar_today_outlined,
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
                    label: s.startLabel,
                    value: s.dates.time(_startAt),
                    icon: Icons.schedule,
                    onTap: () async {
                      final picked = await pickTime(context, _start);
                      if (picked != null) setState(() => _start = picked);
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: PickerField(
                    label: s.endOptional,
                    value: _endAt == null ? '—' : s.dates.time(_endAt!),
                    icon: Icons.schedule_outlined,
                    errorText: _submitted ? _endError : null,
                    onClear: _end == null
                        ? null
                        : () => setState(() => _end = null),
                    onTap: () async {
                      final picked = await pickTime(
                        context,
                        _end ??
                            TimeOfDay(hour: (_start.hour + 1) % 24, minute: 0),
                      );
                      if (picked != null) setState(() => _end = picked);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
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

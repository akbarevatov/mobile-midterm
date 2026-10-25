import 'package:flutter/material.dart';

import '../../models/priority.dart';
import '../../utils/date_math.dart';
import '../common/app_scope.dart';

class PickerField extends StatelessWidget {
  const PickerField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.errorText,
    this.helperText,
    this.onClear,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
  final String? errorText;
  final String? helperText;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label: $value',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(
            enabled: onTap != null,
            labelText: label,
            prefixIcon: Icon(icon),
            errorText: errorText,
            helperText: helperText,
            helperMaxLines: 3,
            suffixIcon: onClear != null
                ? IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: context.s.cancel,
                    onPressed: onClear,
                  )
                : (onTap == null ? null : const Icon(Icons.arrow_drop_down)),
          ),
          child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }
}

Future<DateTime?> pickDate(
  BuildContext context,
  DateTime initial, {
  DateTime? first,
  DateTime? last,
}) {
  final now = DateTime.now();
  final firstDate = first ?? DateTime(now.year - 2);
  final lastDate = last ?? DateTime(now.year + 3, 12, 31);
  var start = dateOnly(initial);
  if (start.isBefore(firstDate)) start = firstDate;
  if (start.isAfter(lastDate)) start = lastDate;
  return showDatePicker(
    context: context,
    initialDate: start,
    firstDate: firstDate,
    lastDate: lastDate,
    helpText: context.s.pickDate,
  );
}

Future<TimeOfDay?> pickTime(BuildContext context, TimeOfDay initial) {
  return showTimePicker(
    context: context,
    initialTime: initial,
    helpText: context.s.pickTime,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
      child: child!,
    ),
  );
}

class PriorityPicker extends StatelessWidget {
  const PriorityPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final Priority value;
  final ValueChanged<Priority> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<Priority>(
        segments: [
          for (final p in Priority.values)
            ButtonSegment(
              value: p,
              label: Text(s.priorityLabel(p)),
              icon: Icon(priorityIcon(p)),
            ),
        ],
        selected: {value},
        showSelectedIcon: false,
        onSelectionChanged: (set) => onChanged(set.first),
      ),
    );
  }
}

IconData priorityIcon(Priority p) => switch (p) {
  Priority.low => Icons.keyboard_arrow_down,
  Priority.medium => Icons.drag_handle,
  Priority.high => Icons.priority_high,
};

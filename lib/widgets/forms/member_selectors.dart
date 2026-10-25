import 'package:flutter/material.dart';

import '../../models/household_member.dart';
import '../../theme/app_spacing.dart';
import '../common/app_scope.dart';
import '../common/member_avatar.dart';

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(text, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}

class FieldError extends StatelessWidget {
  const FieldError(this.text, {super.key});

  final String? text;

  @override
  Widget build(BuildContext context) {
    if (text == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs, left: AppSpacing.md),
      child: Text(
        text!,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: scheme.error),
      ),
    );
  }
}

class MemberChoiceChips extends StatelessWidget {
  const MemberChoiceChips({
    super.key,
    required this.members,
    required this.selectedId,
    required this.onSelected,
    this.allowNone = false,
    this.noneLabel,
  });

  final List<HouseholdMember> members;
  final String? selectedId;
  final ValueChanged<String?> onSelected;
  final bool allowNone;
  final String? noneLabel;

  @override
  Widget build(BuildContext context) {
    final you = context.app.data.currentMemberId;
    final s = context.s;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        if (allowNone)
          ChoiceChip(
            label: Text(noneLabel ?? s.none),
            selected: selectedId == null,
            onSelected: (_) => onSelected(null),
          ),
        for (final m in members)
          ChoiceChip(
            avatar: MemberAvatar(member: m, radius: 12),
            label: Text(
              m.id == you ? '${m.displayName} (${s.you})' : m.displayName,
            ),
            selected: m.id == selectedId,
            onSelected: (_) => onSelected(m.id),
          ),
      ],
    );
  }
}

class MemberMultiSelect extends StatelessWidget {
  const MemberMultiSelect({
    super.key,
    required this.members,
    required this.selectedIds,
    required this.onChanged,
    this.showSelectAll = true,
  });

  final List<HouseholdMember> members;
  final List<String> selectedIds;
  final ValueChanged<List<String>> onChanged;
  final bool showSelectAll;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final you = context.app.data.currentMemberId;
    final allSelected = members.every((m) => selectedIds.contains(m.id));

    List<String> ordered(Set<String> ids) =>
        members.where((m) => ids.contains(m.id)).map((m) => m.id).toList();

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        if (showSelectAll && members.length > 1)
          FilterChip(
            label: Text(s.all),
            selected: allSelected,
            onSelected: (value) =>
                onChanged(value ? members.map((m) => m.id).toList() : []),
          ),
        for (final m in members)
          FilterChip(
            avatar: selectedIds.contains(m.id)
                ? null
                : MemberAvatar(member: m, radius: 12),
            label: Text(
              m.id == you ? '${m.displayName} (${s.you})' : m.displayName,
            ),
            selected: selectedIds.contains(m.id),
            onSelected: (value) {
              final next = selectedIds.toSet();
              value ? next.add(m.id) : next.remove(m.id);
              onChanged(ordered(next));
            },
          ),
      ],
    );
  }
}

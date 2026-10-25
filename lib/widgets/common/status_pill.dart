import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

enum PillTone { overdue, soon, done, neutral, shared, personal, positive }

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.icon,
    this.tone = PillTone.neutral,
  });

  final String label;
  final IconData icon;
  final PillTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = AppColors.of(context);
    final (Color fg, Color bg) = switch (tone) {
      PillTone.overdue => (scheme.onErrorContainer, scheme.errorContainer),
      PillTone.soon => (colors.warning, colors.warning.withValues(alpha: 0.14)),
      PillTone.done => (colors.muted, scheme.surfaceContainerHighest),
      PillTone.neutral => (
        scheme.onSurfaceVariant,
        scheme.surfaceContainerHighest,
      ),
      PillTone.shared => (colors.shared, colors.sharedContainer),
      PillTone.personal => (colors.personal, colors.personalContainer),
      PillTone.positive => (
        colors.positive,
        colors.positive.withValues(alpha: 0.14),
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: fg, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

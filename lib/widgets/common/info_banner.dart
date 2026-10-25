import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.text,
    this.icon = Icons.info_outline,
    this.title,
    this.isError = false,
  });

  final String text;
  final String? title;
  final IconData icon;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = isError ? scheme.onErrorContainer : scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isError
            ? scheme.errorContainer
            : scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: fg),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      title!,
                      style: theme.textTheme.titleSmall?.copyWith(color: fg),
                    ),
                  ),
                Text(
                  text,
                  style: theme.textTheme.bodySmall?.copyWith(color: fg),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

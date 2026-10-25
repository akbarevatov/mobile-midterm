import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
    this.padding,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          padding ??
          const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.xl,
            AppSpacing.sm,
            AppSpacing.sm,
          ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          if (action != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(action!)),
        ],
      ),
    );
  }
}

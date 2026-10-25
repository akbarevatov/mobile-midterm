import 'package:flutter/material.dart';

import '../../l10n/app_language.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/app_scope.dart';
import '../../widgets/common/info_banner.dart';
import 'create_household_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              shrinkWrap: true,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: SegmentedButton<AppLanguage>(
                    segments: [
                      for (final l in AppLanguage.values)
                        ButtonSegment(
                          value: l,
                          label: Text(l.code.toUpperCase()),
                        ),
                    ],
                    selected: {app.settings.language},
                    showSelectedIcon: false,
                    onSelectionChanged: (set) => app.setLanguage(set.first),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                    child: Icon(
                      Icons.diversity_3,
                      size: 40,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Birga',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  s.tagline,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                if (app.storageUnavailable) ...[
                  InfoBanner(
                    text: s.storageUnavailable,
                    icon: Icons.sd_card_alert_outlined,
                    isError: true,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (app.storedDataWasUnreadable) ...[
                  InfoBanner(
                    text: s.unreadableData,
                    icon: Icons.warning_amber,
                    isError: true,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                FilledButton.icon(
                  onPressed: app.startDemo,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(s.startDemo),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xs,
                    AppSpacing.sm,
                    AppSpacing.xs,
                    AppSpacing.lg,
                  ),
                  child: Text(s.demoHint, style: theme.textTheme.bodySmall),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CreateHouseholdScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.add_home_outlined),
                  label: Text(s.createHousehold),
                ),
                const SizedBox(height: AppSpacing.xxl),
                InfoBanner(text: s.localOnlyNote, icon: Icons.phone_android),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

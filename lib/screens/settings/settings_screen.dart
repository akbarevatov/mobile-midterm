import 'package:flutter/material.dart';

import '../../l10n/app_language.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/app_scope.dart';
import '../../widgets/common/dialogs.dart';
import '../../widgets/common/info_banner.dart';
import '../../widgets/common/member_avatar.dart';
import '../../widgets/common/section_header.dart';
import '../home/profile_switcher.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _resetDemo(BuildContext context) async {
    final app = context.app;
    final s = context.s;
    final ok = await confirmAction(
      context,
      title: s.resetDemo,
      message: s.resetDemoBody,
      confirmLabel: s.reset,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    app.startDemo();
  }

  Future<void> _startOver(BuildContext context) async {
    final app = context.app;
    final s = context.s;
    final ok = await confirmAction(
      context,
      title: s.startOver,
      message: s.startOverBody,
      confirmLabel: s.erase,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    app.leaveHousehold();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.settings)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          SectionHeader(title: s.profile),
          ListTile(
            leading: MemberAvatar(member: app.currentMember),
            title: Text(app.currentMember.displayName),
            subtitle: Text(app.data.household.name),
            trailing: Tooltip(
              message: s.switchProfile,
              child: const Icon(Icons.swap_horiz),
            ),
            onTap: () => showProfileSwitcher(context),
          ),
          SectionHeader(title: s.languageLabel),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<AppLanguage>(
                segments: [
                  for (final l in AppLanguage.values)
                    ButtonSegment(value: l, label: Text(l.nativeName)),
                ],
                selected: {app.settings.language},
                showSelectedIcon: false,
                onSelectionChanged: (set) => app.setLanguage(set.first),
              ),
            ),
          ),
          SectionHeader(title: s.theme),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text(s.themeSystem),
                    icon: const Icon(Icons.brightness_auto),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text(s.themeLight),
                    icon: const Icon(Icons.light_mode_outlined),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text(s.themeDark),
                    icon: const Icon(Icons.dark_mode_outlined),
                  ),
                ],
                selected: {app.settings.themeMode},
                showSelectedIcon: false,
                onSelectionChanged: (set) => app.setThemeMode(set.first),
              ),
            ),
          ),
          SectionHeader(title: s.dataSection),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
            child: InfoBanner(text: s.storageInfo, icon: Icons.phone_android),
          ),
          const SizedBox(height: AppSpacing.sm),
          ListTile(
            leading: const Icon(Icons.restart_alt),
            title: Text(s.resetDemo),
            subtitle: app.data.isDemo ? Text(s.demoDataLabel) : null,
            onTap: () => _resetDemo(context),
          ),
          ListTile(
            leading: Icon(
              Icons.delete_forever_outlined,
              color: theme.colorScheme.error,
            ),
            title: Text(
              s.startOver,
              style: TextStyle(color: theme.colorScheme.error),
            ),
            onTap: () => _startOver(context),
          ),
          SectionHeader(title: s.about),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
            child: Text(s.aboutText, style: theme.textTheme.bodyMedium),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.sm,
              AppSpacing.page,
              0,
            ),
            child: Text('Birga 0.1.0', style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../widgets/common/app_scope.dart';
import '../../widgets/common/dialogs.dart';
import '../../widgets/common/info_banner.dart';
import '../../widgets/common/member_avatar.dart';

Future<void> showProfileSwitcher(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      final app = sheetContext.app;
      final s = sheetContext.s;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            0,
            AppSpacing.page,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.whoIsUsing,
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              InfoBanner(
                text: s.profileSwitcherNote,
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final m in app.activeMembers)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: MemberAvatar(member: m),
                  title: Text(m.displayName),
                  trailing: m.id == app.data.currentMemberId
                      ? Icon(
                          Icons.check_circle,
                          color: Theme.of(sheetContext).colorScheme.primary,
                          semanticLabel: s.currentProfile,
                        )
                      : null,
                  selected: m.id == app.data.currentMemberId,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    if (m.id != app.data.currentMemberId) {
                      app.switchMember(m.id);
                      showSnack(context, s.nowViewingAs(m.displayName));
                    }
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}

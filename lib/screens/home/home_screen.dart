import 'package:flutter/material.dart';

import '../../models/activity_entry.dart';
import '../../services/calculations/attention.dart';
import '../../services/calculations/bill_schedule.dart';
import '../../services/calculations/planner_filters.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/app_scope.dart';
import '../../widgets/common/balance_text.dart';
import '../../widgets/common/category_icons.dart';
import '../../widgets/common/info_banner.dart';
import '../../widgets/common/member_avatar.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/status_pill.dart';
import '../../widgets/navigation/main_shell.dart';
import '../chores/assignment_actions.dart';
import '../chores/chore_form_screen.dart';
import '../household/bill_detail_screen.dart';
import '../household/rules_screen.dart';
import '../household/shopping_item_sheet.dart';
import '../household/shopping_screen.dart';
import '../money/expense_form_screen.dart';
import '../planner/planner_form_screen.dart';
import '../planner/planner_item_sheet.dart';
import '../settings/settings_screen.dart';
import 'activity_screen.dart';
import 'profile_switcher.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenTab});

  final ValueChanged<int> onOpenTab;

  void _openAttention(BuildContext context, AttentionItem item) {
    switch (item.kind) {
      case AttentionKind.choreOverdue:
      case AttentionKind.choreToday:
        showAssignmentActions(context, item.refId);
      case AttentionKind.billOverdue:
      case AttentionKind.billDueSoon:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BillDetailScreen(billId: item.refId),
          ),
        );
      case AttentionKind.taskOverdue:
      case AttentionKind.taskToday:
        showPlannerItemSheet(context, item.refId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    final theme = Theme.of(context);
    final me = app.currentMember;
    final attention = app.attentionItems;
    final pinned = app.pinnedAnnouncements;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.greeting(me.displayName)),
            Row(
              children: [
                Flexible(
                  child: Text(
                    app.data.household.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (app.data.isDemo) ...[
                  const SizedBox(width: AppSpacing.sm),
                  StatusPill(label: s.demo, icon: Icons.science_outlined),
                ],
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: s.switchProfile,
            onPressed: () => showProfileSwitcher(context),
            icon: MemberAvatar(member: me, radius: 16),
          ),
          IconButton(
            tooltip: s.settings,
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: [
          if (app.saveFailed)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.sm,
                AppSpacing.page,
                0,
              ),
              child: InfoBanner(
                text: s.saveFailed,
                icon: Icons.sd_card_alert_outlined,
                isError: true,
              ),
            ),
          if (pinned.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.sm,
                AppSpacing.page,
                0,
              ),
              child: _AnnouncementCard(
                message: pinned.first.message,
                meta: s.postedBy(
                  app.memberName(pinned.first.authorId),
                  s.timeAgo(pinned.first.createdAt, app.now()),
                ),
                onTap: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const RulesScreen())),
              ),
            ),
          SectionHeader(title: s.needsAttention),
          if (attention.isEmpty)
            ListTile(
              leading: Icon(
                Icons.check_circle_outline,
                color: context.colors.positive,
              ),
              title: Text(s.allClear),
            )
          else
            for (final item in attention.take(6))
              _AttentionTile(
                item: item,
                onTap: () => _openAttention(context, item),
              ),
          const SizedBox(height: AppSpacing.sm),
          _SummaryGrid(onOpenTab: onOpenTab),
          SectionHeader(title: s.quickActions),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                _QuickAction(
                  icon: Icons.add_card,
                  label: s.qaExpense,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ExpenseFormScreen(),
                    ),
                  ),
                ),
                _QuickAction(
                  icon: Icons.cleaning_services_outlined,
                  label: s.qaChore,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ChoreFormScreen()),
                  ),
                ),
                _QuickAction(
                  icon: Icons.add_shopping_cart,
                  label: s.qaGrocery,
                  onTap: () => showShoppingItemSheet(context),
                ),
                _QuickAction(
                  icon: Icons.post_add,
                  label: s.qaTask,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PlannerFormScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SectionHeader(
            title: s.recentActivity,
            action: app.recentActivity.length > 5 ? s.seeAll : null,
            onAction: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ActivityScreen())),
          ),
          if (app.recentActivity.isEmpty)
            ListTile(title: Text(s.noActivity))
          else
            for (final entry in app.recentActivity.take(5))
              ActivityTile(entry: entry),
        ],
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({
    required this.message,
    required this.meta,
    required this.onTap,
  });

  final String message;
  final String meta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    return Card(
      color: colors.sharedContainer,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.campaign_outlined, color: colors.shared),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.s.announcement,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.shared,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(message, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      meta,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttentionTile extends StatelessWidget {
  const _AttentionTile({required this.item, required this.onTap});

  final AttentionItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    final scheme = Theme.of(context).colorScheme;

    final (IconData icon, String kindLabel) = switch (item.kind) {
      AttentionKind.choreOverdue ||
      AttentionKind.choreToday => (choreIcon, s.attentionChore),
      AttentionKind.billOverdue || AttentionKind.billDueSoon => (
        Icons.receipt_long_outlined,
        s.attentionBill,
      ),
      AttentionKind.taskOverdue ||
      AttentionKind.taskToday => (Icons.school_outlined, s.attentionTask),
    };

    final String when;
    if (item.isOverdue) {
      when = s.overdueSince(s.dates.relativeDay(item.date, app.today));
    } else if (item.kind == AttentionKind.taskToday) {
      when = s.dueUntil(s.dates.time(item.date));
    } else {
      when = s.dates.relativeDay(item.date, app.today);
    }
    final amount = item.amountUzs == null
        ? ''
        : ' · ${s.money(item.amountUzs!)}';

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: item.isOverdue
            ? scheme.errorContainer
            : scheme.secondaryContainer,
        foregroundColor: item.isOverdue
            ? scheme.onErrorContainer
            : scheme.onSecondaryContainer,
        child: Icon(
          item.isOverdue ? Icons.warning_amber_rounded : icon,
          size: 20,
        ),
      ),
      title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '$kindLabel · $when$amount',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.onOpenTab});

  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    final theme = Theme.of(context);
    final net = app.balanceOf(app.data.currentMemberId);
    final bills = app.billOverviewList
        .where((b) => b.currentDue != null)
        .toList();
    final nextBill = bills.isEmpty ? null : bills.first;
    final deadline = nextAcademicDeadline(app.myPlannerItems, app.now());
    final toBuy = app.itemsToBuy;

    final balanceCard = _SummaryCard(
      icon: Icons.account_balance_wallet_outlined,
      title: s.yourBalance,
      onTap: () => onOpenTab(MainShell.money),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _LeftBalance(net: net),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${s.spentThisMonth}: ${s.money(app.spendingInMonth(app.today))}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );

    final billCard = _SummaryCard(
      icon: Icons.receipt_long_outlined,
      title: s.nextBill,
      onTap: nextBill == null
          ? () => onOpenTab(MainShell.household)
          : () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BillDetailScreen(billId: nextBill.bill.id),
              ),
            ),
      body: nextBill == null
          ? Text(s.noUpcomingBills, style: theme.textTheme.bodyMedium)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nextBill.bill.name,
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  s.money(nextBill.bill.expectedAmountUzs),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                _BillPill(status: nextBill.status, due: nextBill.currentDue!),
              ],
            ),
    );

    final deadlineCard = _SummaryCard(
      icon: Icons.school_outlined,
      title: s.nextDeadline,
      onTap: deadline == null
          ? () => onOpenTab(MainShell.planner)
          : () => showPlannerItemSheet(context, deadline.id),
      body: deadline == null
          ? Text(s.noDeadlines, style: theme.textTheme.bodyMedium)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deadline.title,
                  style: theme.textTheme.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (deadline.course.isNotEmpty)
                  Text(
                    deadline.course,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${s.plannerCategory(deadline.category)} · ${s.dueLabel(deadline.dueAt, app.now(), withTime: true)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );

    final shoppingCard = _SummaryCard(
      icon: Icons.shopping_cart_outlined,
      title: s.shoppingTitle,
      onTap: () =>
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const ShoppingScreen())),
      body: toBuy.isEmpty
          ? Text(s.shoppingAllBought, style: theme.textTheme.bodyMedium)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.itemsToBuy(toBuy.length),
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  toBuy.take(4).map((i) => i.name).join(', '),
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cards = [balanceCard, billCard, deadlineCard, shoppingCard];
          if (constraints.maxWidth < 340) {
            return Column(
              children: [
                for (final card in cards)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: card,
                  ),
              ],
            );
          }
          Widget row(Widget a, Widget b) => IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: a),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: b),
              ],
            ),
          );
          return Column(
            children: [
              row(balanceCard, billCard),
              const SizedBox(height: AppSpacing.sm),
              row(deadlineCard, shoppingCard),
            ],
          );
        },
      ),
    );
  }
}

class _LeftBalance extends StatelessWidget {
  const _LeftBalance({required this.net});

  final int net;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: BalanceText(
        net: net,
        labelForYou: true,
        alignStart: true,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}

class _BillPill extends StatelessWidget {
  const _BillPill({required this.status, required this.due});

  final BillStatus status;
  final DateTime due;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final rel = s.dates.relativeDay(due, context.app.today);
    return switch (status) {
      BillStatus.overdue => StatusPill(
        label: s.overdue,
        icon: Icons.warning_amber_rounded,
        tone: PillTone.overdue,
      ),
      BillStatus.dueSoon => StatusPill(
        label: rel,
        icon: Icons.schedule,
        tone: PillTone.soon,
      ),
      _ => StatusPill(label: rel, icon: Icons.event_outlined),
    };
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final Widget body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              body,
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.xs,
          ),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Icon(icon, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ActivityTile extends StatelessWidget {
  const ActivityTile({super.key, required this.entry});

  final ActivityEntry entry;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    final text = s.activityText(
      entry,
      app.memberName(entry.actorId),
      app.memberName(entry.otherMemberId),
      entry.amountUzs == null ? '' : s.money(entry.amountUzs!),
    );
    return ListTile(
      dense: true,
      leading: MemberAvatar(member: app.member(entry.actorId), radius: 16),
      title: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(s.timeAgo(entry.at, app.now())),
    );
  }
}

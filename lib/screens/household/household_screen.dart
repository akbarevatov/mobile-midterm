import 'package:flutter/material.dart';

import '../../services/calculations/bill_schedule.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/app_scope.dart';
import '../../widgets/common/member_avatar.dart';
import 'bills_screen.dart';
import 'calendar_screen.dart';
import 'issues_screen.dart';
import 'members_screen.dart';
import 'polls_screen.dart';
import 'rules_screen.dart';
import 'shopping_screen.dart';

class HouseholdScreen extends StatelessWidget {
  const HouseholdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = context.s;
    final now = app.now();
    final toBuy = app.itemsToBuy.length;
    final bills = app.billOverviewList
        .where((b) => b.currentDue != null)
        .toList();
    final upcomingEvents = app.eventsChronological
        .where((e) => !e.startAt.isBefore(app.today))
        .toList();
    final openPolls = app.data.polls.where((p) => p.isOpen(now)).length;
    final openIssues = app.data.issues.where((i) => i.isOpen).length;

    void open(Widget screen) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

    return Scaffold(
      appBar: AppBar(title: Text(app.data.household.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.sm,
          AppSpacing.page,
          AppSpacing.xl,
        ),
        children: [
          _HubCard(
            icon: Icons.group_outlined,
            title: s.roommates,
            subtitle: s.membersCount(app.activeMembers.length),
            trailing: SizedBox(
              width: 88,
              height: 28,
              child: Stack(
                children: [
                  for (var i = 0; i < app.activeMembers.length && i < 4; i++)
                    Positioned(
                      left: i * 18.0,
                      child: MemberAvatar(
                        member: app.activeMembers[i],
                        radius: 14,
                      ),
                    ),
                ],
              ),
            ),
            onTap: () => open(const MembersScreen()),
          ),
          _HubCard(
            icon: Icons.shopping_cart_outlined,
            title: s.shoppingTitle,
            subtitle: toBuy == 0 ? s.shoppingAllBought : s.itemsToBuy(toBuy),
            onTap: () => open(const ShoppingScreen()),
          ),
          _HubCard(
            icon: Icons.receipt_long_outlined,
            title: s.billsTitle,
            subtitle: bills.isEmpty
                ? s.allBillsPaid
                : '${bills.first.status == BillStatus.overdue ? s.overdue : s.nextBill}: ${bills.first.bill.name} · ${s.dates.relativeDay(bills.first.currentDue!, app.today)}',
            onTap: () => open(const BillsScreen()),
          ),
          _HubCard(
            icon: Icons.calendar_month_outlined,
            title: s.calendarTitle,
            subtitle: upcomingEvents.isEmpty
                ? s.noUpcomingEvents
                : '${upcomingEvents.first.title} · ${s.dates.relativeDay(upcomingEvents.first.startAt, app.today)}',
            onTap: () => open(const CalendarScreen()),
          ),
          _HubCard(
            icon: Icons.how_to_vote_outlined,
            title: s.pollsTitle,
            subtitle: s.openPolls(openPolls),
            onTap: () => open(const PollsScreen()),
          ),
          _HubCard(
            icon: Icons.build_outlined,
            title: s.issuesTitle,
            subtitle: s.openIssues(openIssues),
            onTap: () => open(const IssuesScreen()),
          ),
          _HubCard(
            icon: Icons.gavel_outlined,
            title: s.rulesTitle,
            subtitle: s.rulesCount(app.data.rules.length),
            onTap: () => open(const RulesScreen()),
          ),
        ],
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  const _HubCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          onTap: onTap,
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: scheme.onSecondaryContainer),
          ),
          title: Text(title, style: Theme.of(context).textTheme.titleMedium),
          subtitle: Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: trailing ?? const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}

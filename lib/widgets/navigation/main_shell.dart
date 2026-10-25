import 'package:flutter/material.dart';

import '../../screens/chores/chores_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/household/household_screen.dart';
import '../../screens/money/money_screen.dart';
import '../../screens/planner/planner_screen.dart';
import '../common/app_scope.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  static const int home = 0;
  static const int money = 1;
  static const int chores = 2;
  static const int planner = 3;
  static const int household = 4;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = MainShell.home;

  void _openTab(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(onOpenTab: _openTab),
          const MoneyScreen(),
          const ChoresScreen(),
          const PlannerScreen(),
          const HouseholdScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _openTab,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: s.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: const Icon(Icons.account_balance_wallet),
            label: s.navMoney,
          ),
          NavigationDestination(
            icon: const Icon(Icons.cleaning_services_outlined),
            selectedIcon: const Icon(Icons.cleaning_services),
            label: s.navChores,
          ),
          NavigationDestination(
            icon: const Icon(Icons.event_note_outlined),
            selectedIcon: const Icon(Icons.event_note),
            label: s.navPlanner,
          ),
          NavigationDestination(
            icon: const Icon(Icons.apartment_outlined),
            selectedIcon: const Icon(Icons.apartment),
            label: s.navHousehold,
          ),
        ],
      ),
    );
  }
}

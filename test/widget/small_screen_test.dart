import 'package:birga/app.dart';
import 'package:birga/l10n/app_language.dart';
import 'package:birga/l10n/app_strings.dart';
import 'package:birga/screens/chores/chore_detail_screen.dart';
import 'package:birga/screens/chores/chore_form_screen.dart';
import 'package:birga/screens/household/bill_detail_screen.dart';
import 'package:birga/screens/household/bill_form_screen.dart';
import 'package:birga/screens/household/bills_screen.dart';
import 'package:birga/screens/household/calendar_screen.dart';
import 'package:birga/screens/household/issues_screen.dart';
import 'package:birga/screens/household/members_screen.dart';
import 'package:birga/screens/household/polls_screen.dart';
import 'package:birga/screens/household/rules_screen.dart';
import 'package:birga/screens/household/shopping_screen.dart';
import 'package:birga/screens/money/expense_detail_screen.dart';
import 'package:birga/screens/money/expense_form_screen.dart';
import 'package:birga/screens/onboarding/create_household_screen.dart';
import 'package:birga/screens/planner/class_schedule_screen.dart';
import 'package:birga/screens/planner/planner_form_screen.dart';
import 'package:birga/screens/settings/settings_screen.dart';
import 'package:birga/services/local_storage/key_value_store.dart';
import 'package:birga/services/repositories/app_repository.dart';
import 'package:birga/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final fixedNow = DateTime(2026, 10, 22, 10, 0);

void main() {
  for (final language in AppLanguage.values) {
    for (final dark in [false, true]) {
      testWidgets(
        'every screen fits a 320×568 phone (${language.code}, ${dark ? 'dark' : 'light'})',
        (tester) async {
          tester.view.physicalSize = const Size(640, 1136);
          tester.view.devicePixelRatio = 2.0;
          addTearDown(tester.view.reset);

          final state = AppState(
            repository: AppRepository(MemoryStore()),
            clock: () => fixedNow,
          );
          await state.load();
          await state.setLanguage(language);
          await state.setThemeMode(dark ? ThemeMode.dark : ThemeMode.light);
          await tester.pumpWidget(BirgaApp(state: state));
          await tester.pumpAndSettle();

          final s = AppStrings(language);
          expect(find.text(s.startDemo), findsOneWidget);
          state.startDemo();
          await tester.pumpAndSettle();

          for (final label in [
            s.navMoney,
            s.navChores,
            s.navPlanner,
            s.navHousehold,
            s.navHome,
          ]) {
            await tester.tap(
              find.descendant(
                of: find.byType(NavigationBar),
                matching: find.text(label),
              ),
            );
            await tester.pumpAndSettle();
          }

          final navigator = tester.state<NavigatorState>(
            find.byType(Navigator),
          );
          final screens = <Widget>[
            const SettingsScreen(),
            const ExpenseFormScreen(),
            ExpenseDetailScreen(expenseId: state.data.expenses.first.id),
            const ChoreFormScreen(),
            ChoreDetailScreen(choreId: state.activeChores.first.id),
            const PlannerFormScreen(),
            const ClassScheduleScreen(),
            const MembersScreen(),
            const ShoppingScreen(),
            const BillsScreen(),
            BillDetailScreen(billId: state.data.bills.first.id),
            const BillFormScreen(),
            const CalendarScreen(),
            const EventFormScreen(),
            const PollsScreen(),
            PollDetailScreen(pollId: state.data.polls.first.id),
            const PollFormScreen(),
            const IssuesScreen(),
            IssueDetailScreen(issueId: state.data.issues.first.id),
            const IssueFormScreen(),
            const RulesScreen(),
            const CreateHouseholdScreen(),
          ];
          for (final screen in screens) {
            navigator.push(MaterialPageRoute<void>(builder: (_) => screen));
            await tester.pumpAndSettle();
            navigator.pop();
            await tester.pumpAndSettle();
          }
        },
      );
    }
  }
}

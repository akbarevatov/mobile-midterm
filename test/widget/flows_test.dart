import 'package:birga/app.dart';
import 'package:birga/l10n/app_language.dart';
import 'package:birga/l10n/app_strings.dart';
import 'package:birga/models/chore.dart';
import 'package:birga/services/local_storage/key_value_store.dart';
import 'package:birga/services/repositories/app_repository.dart';
import 'package:birga/state/app_state.dart';
import 'package:birga/utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final fixedNow = DateTime(2026, 10, 22, 10, 0);
const s = AppStrings(AppLanguage.uz);

Future<AppState> pumpApp(WidgetTester tester, {bool demo = true}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  final state = AppState(
    repository: AppRepository(MemoryStore()),
    clock: () => fixedNow,
  );
  await state.load();
  if (demo) state.startDemo();
  await tester.pumpWidget(BirgaApp(state: state));
  await tester.pumpAndSettle();
  return state;
}

Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

Future<void> enterField(WidgetTester tester, String label, String text) async {
  await tester.enterText(find.widgetWithText(TextFormField, label), text);
  await tester.pump();
}

Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).hitTestable().first,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('first launch shows the welcome screen and the demo opens Home', (
    tester,
  ) async {
    final state = await pumpApp(tester, demo: false);
    expect(find.text(s.startDemo), findsOneWidget);
    expect(find.text(s.localOnlyNote), findsOneWidget);

    await tester.tap(find.text(s.startDemo));
    await tester.pumpAndSettle();
    expect(state.hasHousehold, isTrue);
    expect(find.text(s.greeting('Aziz')), findsOneWidget);
    expect(find.text(s.needsAttention), findsOneWidget);
  });

  testWidgets('Flow A: add an equally split expense and see balances update', (
    tester,
  ) async {
    final state = await pumpApp(tester);
    final before = state.balanceOf('demo-aziz');
    final count = state.data.expenses.length;

    await openTab(tester, s.navMoney);
    await tester.tap(find.text(s.addExpense).hitTestable());
    await tester.pumpAndSettle();

    await enterField(tester, s.expenseTitle, 'Bozorlik');
    await enterField(tester, s.amount, '120000');
    expect(find.text('120 000'), findsOneWidget);
    await scrollTo(tester, find.text(s.payerGetsBack('Aziz', s.money(90000))));
    expect(find.text(s.payerGetsBack('Aziz', s.money(90000))), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, s.save));
    await tester.pumpAndSettle();

    expect(state.data.expenses.length, count + 1);
    final added = state.data.expenses.last;
    expect(added.splitAmountsByMemberId.values, everyElement(30000));
    expect(state.balanceOf('demo-aziz'), before + 90000);
    expect(find.text(s.expenseSaved), findsOneWidget);
  });

  testWidgets('Flow A: invalid input is rejected with clear messages', (
    tester,
  ) async {
    final state = await pumpApp(tester);
    final count = state.data.expenses.length;
    await openTab(tester, s.navMoney);
    await tester.tap(find.text(s.addExpense).hitTestable());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, s.save));
    await tester.pumpAndSettle();
    expect(find.text(s.fieldRequired), findsOneWidget);
    expect(find.text(s.amountError(AmountError.empty)!), findsOneWidget);

    await enterField(tester, s.expenseTitle, 'Taksi');
    await enterField(tester, s.amount, '50000');
    await scrollTo(tester, find.widgetWithText(FilterChip, s.all));
    await tester.tap(find.widgetWithText(FilterChip, s.all));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, s.save));
    await tester.pumpAndSettle();
    expect(find.text(s.chooseParticipants), findsWidgets);
    expect(state.data.expenses.length, count);
  });

  testWidgets(
    'Flow B: completing a chore hands the next turn to the rotation',
    (tester) async {
      final state = await pumpApp(tester);
      final dishes = state.currentAssignmentFor('demo-dishes')!;
      await openTab(tester, s.navChores);

      final tile = find
          .ancestor(
            of: find.text('Idish yuvish'),
            matching: find.byType(ListTile),
          )
          .first;
      await tester.tap(
        find.descendant(of: tile, matching: find.byTooltip(s.markDone)),
      );
      await tester.pumpAndSettle();

      expect(dishes.status, AssignmentStatus.completed);
      final next = state.currentAssignmentFor('demo-dishes')!;
      expect(next.assigneeMemberId, 'demo-madina');
      expect(find.textContaining(s.choreDone('Idish yuvish')), findsOneWidget);

      await tester.tap(find.text(s.undo));
      await tester.pumpAndSettle();
      expect(dishes.isPending, isTrue);
    },
  );

  testWidgets('Flow C: adding an item that is already on the list asks first', (
    tester,
  ) async {
    final state = await pumpApp(tester);
    await openTab(tester, s.navHousehold);
    await tester.tap(find.text(s.shoppingTitle));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ActionChip, 'Non'));
    await tester.pumpAndSettle();
    expect(find.text(s.duplicateTitle), findsOneWidget);

    await tester.tap(find.text(s.addSeparately));
    await tester.pumpAndSettle();
    expect(state.itemsToBuy.where((i) => i.name == 'Non').length, 2);
  });

  testWidgets(
    'Flow D: add a deadline, complete it, and it leaves the active views',
    (tester) async {
      final state = await pumpApp(tester);
      await openTab(tester, s.navPlanner);
      await tester.tap(find.text(s.addTaskLabel).hitTestable());
      await tester.pumpAndSettle();

      await enterField(tester, s.titleLabel, 'Algoritmlar: 3-topshiriq');
      await enterField(tester, s.courseOptional, 'Algoritmlar');
      await tester.tap(find.widgetWithText(TextButton, s.save));
      await tester.pumpAndSettle();

      final item = state.myPlannerItems.firstWhere(
        (p) => p.title == 'Algoritmlar: 3-topshiriq',
      );
      expect(item.dueAt, DateTime(2026, 10, 23, 23, 59));

      await tester.tap(find.text(s.viewUpcoming));
      await tester.pumpAndSettle();
      final tile = find.ancestor(
        of: find.text(item.title),
        matching: find.byType(ListTile),
      );
      expect(tile, findsOneWidget);
      await tester.tap(
        find.descendant(of: tile, matching: find.byType(Checkbox)),
      );
      await tester.pumpAndSettle();

      expect(item.isCompleted, isTrue);
      expect(find.text(item.title), findsNothing);
      await tester.tap(find.text(s.viewCompleted));
      await tester.pumpAndSettle();
      expect(find.text(item.title), findsOneWidget);
    },
  );

  testWidgets('Flow E: pay an overdue bill from Home and the summary updates', (
    tester,
  ) async {
    final state = await pumpApp(tester);
    final before = state.data.expenses.length;
    expect(find.text('Elektr energiyasi'), findsWidgets);

    await tester.tap(
      find.ancestor(
        of: find.text('Elektr energiyasi').first,
        matching: find.byType(ListTile),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(s.markPaid));
    await tester.pumpAndSettle();
    expect(find.text('94 000'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, s.save));
    await tester.pumpAndSettle();
    expect(state.data.expenses.length, before + 1);
    expect(state.data.expenses.last.billId, 'demo-electricity');

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect(
      state.attentionItems.any((a) => a.refId == 'demo-electricity'),
      isFalse,
    );
    expect(
      find.descendant(
        of: find.byType(ListTile),
        matching: find.text('Elektr energiyasi'),
      ),
      findsNothing,
    );
  });

  testWidgets('switching to Russian translates the interface', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip(s.settings));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Русский'));
    await tester.pumpAndSettle();
    const ru = AppStrings(AppLanguage.ru);
    expect(find.text(ru.settings), findsWidgets);
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect(find.text(ru.navMoney), findsOneWidget);
    expect(find.text(ru.needsAttention), findsOneWidget);
  });
}

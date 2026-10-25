# Birga - Project Plan

## 1. Product vision

Birga ("together" in Uzbek) is an app for students who share an apartment or a dorm room. Roommates can split expenses, take turns with chores, keep a shared shopping list and track bills like rent and internet. Every student also has a personal planner for classes, assignments and exams.

Our main goal is that everything a student needs to organize with their roommates, or for their own week, is in one place and not spread over Telegram chats, notebooks and memory.

## 2. Target audience

Main users:
- university students in Tashkent and other cities who rent an apartment or house together
- students who share a dorm room
- students who split groceries, utilities, rent and cleaning

Other users:
- students who live alone and want a planner and a simple expense list
- students who organize study sessions or group projects

## 3. Problem statement

Students who live together usually organize money, chores and groceries in a group chat or just remember it. We think this causes problems like:
- nobody knows exactly who owes whom
- some people do more cleaning than others
- things run out or get bought twice
- bills are paid late
- on top of that, students also have to keep track of their own deadlines

These are our assumptions for now. We have not asked real students yet. The survey we will use is in [PROBLEM_VALIDATION.md](PROBLEM_VALIDATION.md), and we will change the plan depending on the answers.

## 4. Local context

- Prices are in Uzbek so'm and nobody uses tiyin, so we store money as whole numbers.
- People write big numbers with spaces (120 000 so'm), so the amount field adds the spaces while you type.
- Students pay each other in cash or by card transfer, so a payment can be marked as cash or card. The app only records it.
- Rent, electricity, water, gas and internet are usually split every month, so we made a separate Bills section.
- The default language is Uzbek Latin (we use the correct ʻ and ʼ letters), and there is a full Russian translation.
- We don't connect to any bank, university or government system.

## 5. Feature prioritization

### Phase 1 - core MVP (done)

- Household and roommates: create a household, add and edit roommates with colors, mark someone as moved out, switch between demo profiles.
- Shared expenses: equal and custom split, payer and participants, categories, edit and delete, filters, balances, settle up suggestions, payment records.
- Chores: recurring chores with a fair rotation, complete with undo, reassign, swap, skip with a reason, history, weekly workload table, forecast of the next turns.
- Shopping list: quantity, notes, category, who will buy it, mark as bought and restore, warning for duplicates, quick add buttons, record bought items as an expense.
- Student planner: assignments, homework, exams, projects, classes, study sessions, personal tasks and events, priorities, weekly repeat for classes, Today / Upcoming / All / Completed.

### Phase 2 - household features (done)

- Household bills: monthly, every 3 months or one time, a responsible person, equal or custom split. Paying a bill creates an expense that is linked to that bill.
- Shared calendar: events, bill due dates and chore turns for the next 30 days.
- Polls: one vote per person, you can change your vote while the poll is open, optional deadline.
- Maintenance problems: category, priority, who will fix it, status Open / In progress / Resolved, notes about how it was fixed.
- House rules and announcements: announcements can be pinned to the Home screen. We did not make a chat on purpose.

### Phase 3 - later (not started)

| Feature | What it needs | Effort |
|---|---|---|
| Sync between phones and real invitations | a backend (Firebase or our own server), login, solving conflicts | big, it changes every part of the app |
| Login | backend, probably phone number + SMS code | medium to big |
| Notifications | local notifications plugin, or the backend for shared reminders | medium |
| Expense charts | nothing new, we have the data | small |
| Export to CSV/PDF | file sharing plugin | small |
| Meal plan and pantry | new models | medium |
| Receipt scanning | camera + text recognition, hard with local receipts | big |
| Home screen widgets | Android and iOS specific code | medium |

## 6. Technical architecture

- Flutter 3.47.5, Dart 3.13.4, Material 3, null safety.
- Packages: `shared_preferences` for saving data, `flutter_localizations` so date pickers and other Material widgets are in Uzbek and Russian, and `cupertino_icons`. We did not use Riverpod, Bloc or Provider.

**State.** `AppState` extends `ChangeNotifier` and holds all the household data. It also has all the actions like `saveExpense`, `completeAssignment` or `vote`. It is the only class that changes the data, and after every change it calls `notifyListeners()` and saves. `AppScope` is an `InheritedNotifier<AppState>`, so a widget gets the state with `context.app` and is rebuilt when the state changes. Things like form fields, selected tab or filters stay in the screen's own `StatefulWidget` with `setState`.

**Logic.** All calculations are normal Dart functions in `lib/services/calculations/` (`money_split.dart`, `balances.dart`, `chore_rotation.dart`, `bill_schedule.dart`, `planner_filters.dart`, `attention.dart`). They get lists and return results, so we test them without Flutter widgets.

**Saving.** After every change the whole data (`AppData`) is saved as JSON with `schemaVersion: 1` through `AppRepository`. The repository uses a small `KeyValueStore` interface. In the app it is SharedPreferences, in tests it is a memory map. Later this is the only part we need to replace to add a server. Language and theme are saved under a separate key, so resetting the demo does not change them.

**Broken data.** If the saved JSON can't be read (or it is from a newer version), we copy it to a backup key and show the welcome screen with a message. We never delete it automatically. If storage itself fails on launch, the app still opens and shows a warning.

**Navigation.** A `NavigationBar` with 5 tabs, the tabs are in an `IndexedStack` so each one keeps its scroll position. Details and forms open with `Navigator.push` and get their data through the constructor, for example `ExpenseDetailScreen(expenseId: ...)`.

**Texts.** `AppStrings` has every text in both languages, for example `_t('Saqlash', 'Сохранить')`. Russian plurals (1 день, 2 дня, 5 дней) are handled. Dates are formatted by our own `DateFormatter` ("22-oktabr" / "22 октября").

**Design.** `app_colors.dart`, `app_spacing.dart` and `app_theme.dart` have the colors, spacing and the light and dark themes. Statuses always have an icon and text, not only a color.

## 7. Main user flows

A. Add and split an expense: Pul -> Xarajat qo'shish -> title and amount -> category and date -> who paid -> who shares -> equal or exact amounts -> check the shares -> Saqlash. The balances and history update right away.

B. Assign and complete a chore: Uy ishlari -> Navbatchilik qo'shish -> title, how often, who is in the rotation, first date, first person (automatic or chosen), priority -> save. Then press the check button on the turn. A message shows who is next, with an undo button.

C. Buy groceries: Xonadon -> Xarid ro'yxati -> add items (if the item is already on the list the app asks first) -> choose who buys -> tick the bought items -> Xarajat sifatida yozish -> choose items -> the expense form opens filled in -> save.

D. University deadline: Reja -> Yozuv qo'shish -> category, title, subject, date and time, priority -> save. It shows in Kelgusi sorted by date. When you tick it, it moves to Bajarilgan.

E. Check the household: on Asosiy tap an overdue bill -> To'landi deb belgilash -> the expense form is filled in and linked to the bill -> save. Back on Home the bill is gone from the list and the balance is updated.

All five flows are also checked by widget tests in `test/widget/flows_test.dart`.

## 8. Screens

1. **Asosiy (Home):** greeting, household name, profile switch, settings. Pinned announcement. "Bugun e'tibor talab qiladi" list with your overdue and today's chores, overdue bills and bills due in 3 days, and your planner tasks. Cards for balance, next bill, next deadline and shopping list. Quick buttons for expense, chore, grocery item and planner task. Recent activity.
2. **Pul (Money):** "Balans" tab with this month's total, my share, what I paid, every roommate's balance, settle up suggestions and the bills summary. "Tarix" tab with all expenses and payments and filters by period and category.
3. **Uy ishlari (Chores):** "Joriy" tab with overdue, today and upcoming turns and a "only mine" filter. "Jadval" tab with the weekly workload table and all chores. "Tarix" tab with completed and skipped turns.
4. **Reja (Planner):** Bugun, Kelgusi, Hammasi and Bajarilgan tabs, category filter and the weekly class schedule.
5. **Xonadon (Household):** cards for roommates, shopping list, bills, calendar, polls, problems and rules.

Other screens: settings, create household, expense form and details, payment form, chore form and details, planner form, class schedule, roommates, shopping list, bills list, bill details and form, calendar and event form, polls, problems, rules and announcements, activity log.

## 9. Data models

The four main entities:

- `HouseholdMember`: id, householdId, displayName, colorIndex, isActive, createdAt
- `Expense`: id, householdId, title, amountUzs (int), payerMemberId, splitAmountsByMemberId (Map<String, int>, the keys are the participants), splitMode, category, date, createdAt, createdById, notes, billId and billPeriod (if it pays a bill), shoppingItemIds (if it pays for shopping list items)
- `ChoreAssignment`: id, choreId, assigneeMemberId, dueDate, status (pending, completed, skipped), completedAt, skipReason, changes (history of reassigns and swaps), createdAt
- `PlannerItem`: id, ownerMemberId, title, description, category, course, dueAt, endAt, priority, recurrence (none or weekly), isCompleted, completedAt, createdAt

The repeating part of a chore is a separate model, `Chore`: title, frequency, eligibleMemberIds (the rotation order), priority, notes, isActive.

Other models: `Household`, `Settlement` (a payment between two roommates), `ShoppingItem`, `HouseholdBill`, `HouseholdEvent`, `HouseholdPoll`, `HouseholdIssue`, `HouseRule`, `Announcement`, `ActivityEntry` and `AppData` (everything together, this is what gets saved).

## 10. Rules we follow in the logic

### Money

- All amounts are `int` in so'm. The maximum for one entry is 1 000 000 000 so'm, mostly to catch typos.
- Equal split: everyone gets `total ~/ n`, and the remainder `total % n` is given 1 so'm each to the first people. For example 100 000 between 3 people is 33 334, 33 333 and 33 333. The shares always add up to the total.
- Custom split: every selected person must have an amount bigger than 0 and the sum must be exactly the total. The form shows how much is left or how much is too much and does not let you save until it matches.
- Balance of a person = what they paid - their own share + payments they gave - payments they received. The payer's own share is not a debt. If Aziz pays 120 000 for 4 people, Aziz is +90 000 and everyone else is -30 000. All balances together are always 0 (we test this with random data).
- "Total spending" only counts expenses. Payments between roommates change debts but they are not spending.
- Settle up: we take the person who owes the most and the person who should get the most, make a transfer of the smaller amount, and repeat. This gives at most n - 1 transfers and after them everyone is at 0.
- Recording a payment does not mark any expense as paid. It is just a record that changes the balances.
- Bills and expenses: the money of a bill is only in the expense list. When you mark a bill as paid, an expense is created with `billId` and `billPeriod`. The current due date of a bill is calculated as the first period that has no expense. So one period can't be paid twice, and if you delete the expense, that period becomes unpaid again.
- Shopping and expenses: an expense can have `shoppingItemIds`. An item that is already in one expense can't be added to another one. If you put a bought item back on the list, it is removed from the expense, but the amount of the expense doesn't change.

### Chore rotation

When a turn is done or skipped, the app makes the next turn and chooses the person like this:

1. the person who did this chore the fewest times in the last 2 rounds (one round = number of people in the rotation)
2. if equal, the person who did it longest ago (never counts as longest ago)
3. if still equal, the person who has fewer open chores right now (this way new chores don't all go to the first person)
4. if still equal, the order in the list

What this gives us (all covered by unit tests):
- normally it is just a circle: A, M, S, D, A, M, S, D
- if someone did an extra turn (because of a swap), they are skipped until the others catch up
- a skipped turn doesn't count for anyone, so the same person is first next time
- people who moved out are never chosen, and their open chores go to others
- a new roommate catches up in the first two rounds and then goes in the normal circle
- the next date never lands in the past, if a weekly chore was done late, the next one is counted from today
- reassigning or swapping only changes the person and is saved in the history, it is not counted as done

On the chore details screen there is a table with these numbers for every person, so anyone can see why the app chose someone. We don't have points or rankings.

### Planner

- Bugun: today's unfinished items (weekly classes too) and older unfinished items that are overdue. Your chores for today and today's household events are added with the "Umumiy" mark.
- Kelgusi: unfinished items from tomorrow, sorted by date, plus your chores and household events for the next 14 days.
- Hammasi: all your items. Bajarilgan: completed ones, newest first.
- Weekly items repeat on the same weekday and can't be completed.

### Home list

Only your own chores and planner tasks are shown there, so nobody's overdue chores are shown to everyone. Bills are for the whole household. Overdue things are shown first.

## 11. Privacy

- Expenses, payments, balances, chores, shopping list, bills, events, polls, problems, rules and announcements: everyone in the household can see them.
- Planner items: only the owner. `AppState` doesn't let another profile save or complete them.
- The activity list never shows planner actions.

In this version these checks are in the app. If we add a server later, the server must check this too.

## 12. Testing

- `flutter analyze` with flutter_lints and some extra rules: no issues.
- 88 unit tests: money split, balances and settle up (also with random data), chore rotation and forecast, planner filters, bills, validation and formatting, AppState actions, saving and loading, broken data and storage errors.
- 12 widget tests: flows A-E in the real UI, validation messages, switching to Russian, and every screen on a 320x568 screen in uz/ru and light/dark.
- We also tried the web version on a phone-sized window and fixed the problems we found (small titles, things not fitting on small screens, the "mark as paid" button being too low).

Not tested yet: real Android and iOS phones, TalkBack/VoiceOver, real users.

## 13. Known limitations

- Works on one phone only, no login and no sync.
- No notifications.
- Payments are only records.
- No photos.
- Planner only repeats weekly.
- After a bill has payments, its due date and frequency can't be changed (so the payment history stays correct).
- Demo data is in the language that was selected when the demo was created.

## 14. Next steps

1. Do the survey with at least 10 students and change the priorities based on the answers.
2. Let 3 to 5 students try the 5 flows on a real phone and fix confusing texts.
3. Check the app with TalkBack and big font size.
4. Add expense charts and CSV export.
5. Choose a backend and then add login, invitations, sync and notifications.

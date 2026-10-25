# Birga

Birga is our midterm project for the Mobile Programming course. It is a Flutter app for university students in Uzbekistan who live together in a rented apartment or a dorm room.

The idea is simple: roommates usually split money, chores and groceries through a Telegram group and memory, and it gets messy. Birga keeps all of it in one place, and each student also gets a personal planner for classes, assignments and exams.

The app is in Uzbek (Latin) by default and can be switched to Russian in Settings.

## What the app can do

**Home** shows what needs attention today: your overdue chores, bills that are due soon, deadlines, your balance, the next bill, the next exam or assignment, the shopping list and recent changes in the household.

**Money**
- add, edit and delete shared expenses in so'm
- split equally or enter exact amounts for each person
- see who owes whom and how to settle with the least number of transfers
- record cash or card payments between roommates
- filter the history by month, custom dates or category

**Chores**
- recurring chores (daily, every other day, weekly, every two weeks, monthly)
- automatic rotation, the app also shows why it picked the next person
- mark as done (with undo), give to someone else, swap with a roommate, skip with a reason
- weekly table of who has how many chores, and full history

**Planner**
- assignments, homework, exams, projects, classes, study sessions and personal tasks
- Today, Upcoming, All and Completed tabs, filter by category
- weekly class schedule
- personal items are only visible to their owner, shared household things are marked "Umumiy"

**Household**
- roommates (add, edit, mark as moved out)
- shopping list with "who will buy it", warning when an item is already on the list, and recording bought items as one expense
- household bills (rent, electricity, water, gas, internet...), paying a bill creates a linked expense
- shared calendar, polls, maintenance problems, house rules and announcements

## How to run

You need Flutter 3.47 or newer (we used 3.47.5 with Dart 3.13.4).

```bash
flutter pub get
flutter run
```

On the first screen press **Demo xonadonni ochish** to open a demo apartment with four made-up students (Aziz, Madina, Sardor and Dilnoza), or **Yangi xonadon yaratish** to start from an empty household.

## Tests

```bash
flutter analyze
flutter test
```

Right now `flutter analyze` has no issues and all 100 tests pass (88 unit tests and 12 widget tests).

- `test/unit/` checks the logic: splitting money, balances, settling up, chore rotation, bills, planner filters, validation, date and money formatting, and saving/loading data.
- `test/widget/flows_test.dart` goes through the main user flows in the real UI (add expense, complete a chore, shopping list, planner, paying a bill, switching to Russian).
- `test/widget/small_screen_test.dart` opens every screen on a small 320x568 phone in both languages and both themes to make sure nothing overflows.

## Project structure

```
lib/
  main.dart, app.dart
  models/        data classes (HouseholdMember, Expense, Chore, PlannerItem, ...)
  screens/       home, money, chores, planner, household, settings, onboarding
  widgets/       common widgets, form fields, bottom navigation
  services/
    calculations/   splitting, balances, chore rotation, bills, planner filters
    local_storage/  SharedPreferences wrapper
    repositories/   loading and saving app data
    demo_data.dart
  state/         AppState (ChangeNotifier) that holds all household data
  l10n/          Uzbek and Russian texts
  theme/         colors, spacing, light and dark theme
  utils/         date and money formatting, validators
test/
docs/
```

## How it works

All the data lives in one `AppState` class (a `ChangeNotifier`). We pass it down the widget tree with an `InheritedNotifier`, so any screen can read it with `context.app` and rebuilds when something changes. That is why the Home screen updates right after you add an expense or finish a chore. Form fields and filters use normal `StatefulWidget` and `setState`.

The calculations (splitting money, balances, chore rotation, bill due dates) are plain Dart functions in `services/calculations`, so we could test them without the UI.

Money is always stored as whole so'm in `int`, never `double`. If an amount can't be split equally, the extra so'm go one by one to the first people in the list, so the shares always add up to the total.

Data is saved on the phone with `shared_preferences` as JSON. If the saved data is broken, the app keeps a backup copy and does not delete it.

## Limitations

- It only works on one phone. Roommates are profiles on the same device, there is no login and no sync between phones. The profile switcher is only for the demo.
- No notifications.
- Payments are only records, the app does not send money.
- No photos for maintenance problems yet.
- Only weekly repeats in the planner.

## Docs

- [Project plan](docs/PROJECT_PLAN.md)
- [Problem validation survey](docs/PROBLEM_VALIDATION.md)
- [Midterm proposal](docs/MIDTERM_PROPOSAL.md)
- [Presentation outline](docs/PRESENTATION_OUTLINE.md)

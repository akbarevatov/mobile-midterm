# Midterm Proposal: Birga

Course: [fill in]
Team: [fill in]
Date: [fill in]

## 1. Problem

Students in Uzbekistan who share an apartment or a dorm room don't have one clear and fair place to track shared expenses, chores, groceries and bills together with their own study deadlines, so they use group chats and memory.

## 2. Target users

Main users are university students in Tashkent and other cities who rent an apartment together or share a dorm room and split groceries, utilities, rent and cleaning.

Other users are students who live alone and want a simple planner for classes and deadlines and a list of their spending.

## 3. Evidence

We haven't collected evidence yet. We prepared a survey with 21 questions for at least 10 students who live with roommates (see [PROBLEM_VALIDATION.md](PROBLEM_VALIDATION.md)). When we get the answers we will fill this part with real numbers like "x of n students...".

| What we want to show | Question | Result |
|---|---|---|
| How many had an unclear debt last month | Q5 | [fill in] |
| How fair chores feel (median 1-5) | Q9 | [fill in] |
| How often things run out or get bought twice | Q11, Q12 | [fill in] |
| Late or forgotten bills in the last 3 months | Q14 | [fill in] |
| Missed or almost missed deadlines last semester | Q16 | [fill in] |
| Which part students want most | Q18 | [fill in] |
| Would they use it if roommates did | Q19 | [fill in] |
| Some quotes (without names) | Q21 | [fill in] |

Things we know without the survey (this is context, not proof of the problem): prices and bills are in so'm, rent and utilities are usually split every month, students pay each other in cash or by card, and both Uzbek and Russian are used.

## 4. App concept

Birga means "together". The app has three parts:

1. Shared household: expenses in so'm with clear balances and settle up suggestions, a fair chore rotation that explains its choice, a shared shopping list, bills, polls, maintenance problems, rules and announcements.
2. Personal planner: classes, assignments, exams, projects and study sessions. Only the owner sees them.
3. Home screen: shows what needs your attention today (overdue chores, bills, deadlines, your balance, shopping list).

For the midterm the app works offline on one phone, in Uzbek and Russian. Roommates are profiles on the same phone and you can switch between them to see the app as each person. Using it on different phones is planned for later.

## 5. User flow

Example we will show:

1. Aziz buys groceries for 120 000 so'm and adds an expense split equally between 4 roommates.
2. The app shows he should get 90 000 back (his own 30 000 is not counted).
3. He marks his dishes turn as done and the app says it's Madina's turn tomorrow.
4. He ticks bread on the shopping list and records it as an expense.
5. He opens the overdue electricity bill from the Home screen and marks it as paid.
6. He checks his next exam in the planner.

## 6. Main screens

1. Asosiy (Home): what needs attention today, quick buttons.
2. Pul (Money): expenses, balances, settle up, history and filters.
3. Uy ishlari (Chores): current turns, rotation, workload table, history.
4. Reja (Planner): personal study and personal schedule.
5. Xonadon (Household): roommates, shopping list, bills, calendar, polls, problems, rules.

## 7. Wireframes

```
+----------------------------+  +----------------------------+  +----------------------------+
| Salom, Aziz          (A) * |  | Pul                        |  | Navbatchilik               |
| Chilonzordagi kvartira     |  | [Balans]   [Tarix]         |  | [Joriy] [Jadval] [Tarix]   |
| +------------------------+ |  | +------------------------+ |  | done: 5  open: 6  late: 1  |
| | E'lon: santexnik keladi| |  | | Oktabr: 6 425 000      | |  | Muddati o'tgan             |
| +------------------------+ |  | | ulushim | to'laganim   | |  | (S) Hammom - kecha     [v] |
| Bugun e'tibor talab qiladi |  | +------------------------+ |  | Bugun                      |
| ! Elektr - muddati o'tgan  |  | Kim kimga qarzdor          |  | (A) Idish yuvish       [v] |
| ! Fizika hisoboti - kecha  |  | (A) Aziz      +1 544 750   |  | Keyingi kunlar             |
|   Idish yuvish - bugun     |  | (D) Dilnoza   -1 643 250   |  | (M) Axlat - ertaga     [v] |
| +----------+ +-----------+ |  | Hisob-kitob                |  | (D) Pol - 2 kundan keyin   |
| | balans   | | keyingi   | |  | D -> A  1 544 750 [qayd]   |  |                            |
| | +1544750 | | to'lov    | |  |                            |  |                            |
| +----------+ +-----------+ |  |              [+ Xarajat]   |  |        [+ Navbatchilik]    |
| [xarajat][navbat][xarid].. |  |                            |  |                            |
+----------------------------+  +----------------------------+  +----------------------------+
| Asosiy Pul Uy ishlari Reja |  | Asosiy Pul Uy ishlari Reja |  | Asosiy Pul Uy ishlari Reja |
+----------------------------+  +----------------------------+  +----------------------------+
          1. Home                         2. Money                        3. Chores

+----------------------------+  +----------------------------+
| Reja                       |  | Chilonzordagi kvartira     |
| [Bugun][Kelgusi][Hammasi]  |  | +------------------------+ |
| shaxsiy - faqat siz        |  | | Xonadoshlar    4 kishi | |
| Muddati o'tgan             |  | +------------------------+ |
| [ ] Fizika hisoboti        |  | | Xarid ro'yxati  7 ta   | |
| Payshanba, 22-oktabr       |  | +------------------------+ |
|  Mobil dasturlash 09:00    |  | | Uy to'lovlari          | |
| [ ] Kutubxona 17:00        |  | | Umumiy taqvim          | |
| Uy bo'yicha                |  | | So'rovnomalar 1 ochiq  | |
|  Idish yuvish  (Umumiy)    |  | | Nosozliklar 2          | |
|                            |  | | Qoidalar va e'lonlar   | |
|          [+ Yozuv qo'shish]|  | +------------------------+ |
+----------------------------+  +----------------------------+
| Asosiy Pul Uy ishlari Reja |  | Asosiy Pul Uy ishlari Reja |
+----------------------------+  +----------------------------+
          4. Planner                     5. Household
```

In the final slides we will use screenshots of the app instead.

## 8. Flutter plan

- `MaterialApp` with Material 3, light and dark theme.
- `Scaffold` with a `NavigationBar` for the 5 screens. The screens are in an `IndexedStack` so each tab remembers its scroll.
- Details and forms open with `Navigator.push` and get data through the constructor, for example `ExpenseDetailScreen(expenseId: ...)`. Back returns to the same tab.
- Shared data is in `AppState`, a `ChangeNotifier`, which we provide with an `InheritedNotifier`. We don't use any state management package.
- Form fields, filters and tabs use `StatefulWidget` and `setState`.
- Forms use `Form`, `GlobalKey<FormState>`, `TextFormField` with validators, controllers that we dispose, number keyboard for amounts, `SegmentedButton`, `ChoiceChip`, `FilterChip`, date and time pickers.
- Long lists use `ListView.builder` or `SliverList.builder`.
- Layout with `Column`, `Row`, `Wrap`, `Expanded`, `Flexible` and `Padding`. A test checks every screen on a 320x568 phone.
- Data is saved with `shared_preferences` as JSON.
- Uzbek Latin by default, Russian can be chosen in Settings.

## 9. Data classes

```dart
class HouseholdMember {
  final String id;
  final String householdId;
  String displayName;
  int colorIndex;
  bool isActive;
  final DateTime createdAt;
}

class Expense {
  final String id;
  final String householdId;
  final String title;
  final int amountUzs;
  final String payerMemberId;
  final Map<String, int> splitAmountsByMemberId;
  final SplitMode splitMode;
  final ExpenseCategory category;
  final DateTime date;
  final String? billId;
  final DateTime? billPeriod;
  final List<String> shoppingItemIds;
}

class ChoreAssignment {
  final String id;
  final String choreId;
  String assigneeMemberId;
  final DateTime dueDate;
  AssignmentStatus status;
  DateTime? completedAt;
  String? skipReason;
  final List<AssignmentChange> changes;
}

class PlannerItem {
  final String id;
  final String ownerMemberId;
  String title;
  PlannerCategory category;
  String course;
  DateTime dueAt;
  DateTime? endAt;
  Priority priority;
  Recurrence recurrence;
  bool isCompleted;
}
```

Some rules: money is always `int` in so'm and never `double`. The shares of an expense always add up to the total. The payer's own share is not a debt. One bill period can only be paid once. Giving a chore to someone else is not the same as completing it.

## 10. Out of scope

- login, accounts, invitations and sync between phones (needs a server)
- notifications
- real payments or connecting to banks, Click or Payme
- connecting to the university system
- receipt scanning and photos
- chat (on purpose, the app is for organizing, not for more messages)
- AI features

## 11. Team contributions

| Name | Role | What they did |
|---|---|---|
| [fill in] | [fill in] | [fill in] |
| [fill in] | [fill in] | [fill in] |
| [fill in] | [fill in] | [fill in] |

## 12. AI tools

We used Claude Code (by Anthropic) while working on the project. It helped write a large part of the code, the tests and the first versions of these documents based on our requirements. [Fill in what each of us checked, changed and tested, and which parts we can explain.]

We did not use AI to make up survey answers or any numbers. All evidence in part 3 will come from real students.

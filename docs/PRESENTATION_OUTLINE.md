# Presentation Outline

10 slides, about 8 minutes. We don't put any numbers from the survey until we actually have the answers.

**1. Problem and target users (45 sec)**
- Students who share an apartment or dorm room don't have one fair place for shared money, chores, groceries and bills next to their own deadlines.
- Users: students who rent together or share a dorm room in Tashkent and other cities, and students living alone for the planner.
- Picture: a messy Telegram group next to our Home screen.

**2. Evidence (1 min)**
- Our survey: 21 questions, at least 10 students who live with roommates, about the last month.
- Results table for Q5, Q9, Q11-12, Q14, Q16 (counts, not percentages).
- If we don't have the results yet, we say it and show the questions.

**3. Local context (45 sec)**
- Money in whole so'm with spaces (120 000 so'm), cash and card transfers.
- Rent, electricity, water, gas and internet split every month.
- Uzbek Latin by default, Russian too.
- No connection to banks or the university system.

**4. App concept and scope (45 sec)**
- Three parts: shared household, personal planner, and the Home screen that shows what needs attention today.
- What we built: expenses and balances, chore rotation, shopping list, planner, bills, calendar, polls, problems, rules.
- What we didn't build: login and sync, notifications, real payments, university system, chat.

**5. Demo (1.5 min)**
- Aziz adds groceries for 120 000 so'm, equal split, he gets 90 000 back.
- He finishes his dishes turn, the app says it's Madina's turn tomorrow (there is undo).
- He ticks bread on the shopping list and records it as an expense.
- He opens the overdue electricity bill from Home and marks it as paid.
- Screenshots ready in case the demo phone doesn't work.

**6. Screens (45 sec)**
- The 5 main screens side by side.
- Statuses have an icon and text, not only color. Shared things have the "Umumiy" label, personal ones a lock.
- No ranking of who is the worst roommate.
- Light and dark theme, works on small phones.

**7. Flutter part (1 min)**
- `NavigationBar` + `IndexedStack`, `Navigator.push` for details and forms.
- `AppState` (`ChangeNotifier`) with `InheritedNotifier`, `setState` for forms, no extra packages for state.
- `Form` + `GlobalKey<FormState>` validation, `ListView.builder` for long lists.
- `shared_preferences` with JSON, broken data is backed up and not deleted.
- `flutter analyze` with no issues, 100 tests (88 unit, 12 widget).

**8. Data model and rules (1 min)**
- `HouseholdMember`, `Expense`, `ChoreAssignment`, `PlannerItem`.
- Money only in `int`, extra so'm go to the first people, the payer's own share is not a debt, one bill period can be paid only once.
- Chore rotation in 4 rules: fewest turns in the last 2 rounds, then longest ago, then fewest open chores, then list order. Show the table from the chore details screen.

**9. Survey results and limitations (45 sec)**
- Which assumptions were right and which were not, and what we changed because of it.
- Limitations: one phone only, no login or sync, no notifications, payments are only records.

**10. Team and next steps (30 sec)**
- Who did what (fill in).
- We used Claude Code for help with code, tests and documents, the survey answers are from real students.
- Next: do the survey, test with 3-5 students, choose a backend for sync.

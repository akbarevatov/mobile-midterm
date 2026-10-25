import '../l10n/app_language.dart';
import '../models/activity_entry.dart';
import '../models/app_data.dart';
import '../models/chore.dart';
import '../models/expense.dart';
import '../models/house_notes.dart';
import '../models/household.dart';
import '../models/household_bill.dart';
import '../models/household_event.dart';
import '../models/household_issue.dart';
import '../models/household_member.dart';
import '../models/household_poll.dart';
import '../models/planner_item.dart';
import '../models/priority.dart';
import '../models/settlement.dart';
import '../models/shopping_item.dart';
import '../utils/date_formatter.dart';
import '../utils/date_math.dart';
import 'calculations/chore_rotation.dart';
import 'calculations/money_split.dart';

AppData buildDemoData(DateTime now, AppLanguage language) =>
    _DemoBuilder(now, language).build();

class _DemoBuilder {
  _DemoBuilder(this.now, this.language)
    : today = dateOnly(now),
      dates = DateFormatter(language);

  final DateTime now;
  final DateTime today;
  final AppLanguage language;
  final DateFormatter dates;

  static const householdId = 'demo-house';
  static const aziz = 'demo-aziz';
  static const madina = 'demo-madina';
  static const sardor = 'demo-sardor';
  static const dilnoza = 'demo-dilnoza';
  static const everyone = [aziz, madina, sardor, dilnoza];

  String t(String uz, String ru) => language == AppLanguage.uz ? uz : ru;
  DateTime day(int offset, [int hour = 0, int minute = 0]) =>
      withTime(addDays(today, offset), hour, minute);

  AppData build() {
    final data = AppData(
      household: Household(
        id: householdId,
        name: t('Chilonzordagi kvartira', 'Квартира на Чиланзаре'),
        createdAt: day(-60),
      ),
      members: [
        _member(aziz, 'Aziz', 0),
        _member(madina, 'Madina', 1),
        _member(sardor, 'Sardor', 2),
        _member(dilnoza, 'Dilnoza', 3),
      ],
      currentMemberId: aziz,
      isDemo: true,
    );
    _addShopping(data);
    _addBillsAndExpenses(data);
    _addChores(data);
    _addPlanner(data);
    _addEventsPollsIssues(data);
    _addRulesAndActivity(data);
    return data;
  }

  HouseholdMember _member(String id, String name, int color) => HouseholdMember(
    id: id,
    householdId: householdId,
    displayName: name,
    colorIndex: color,
    createdAt: day(-60),
  );

  void _addShopping(AppData data) {
    ShoppingItem item(
      String id,
      String name,
      String qty,
      ShoppingCategory category, {
      String? buyer,
      String notes = '',
      String? purchasedBy,
      DateTime? purchasedAt,
      String addedBy = madina,
    }) => ShoppingItem(
      id: id,
      householdId: householdId,
      name: name,
      quantity: qty,
      notes: notes,
      category: category,
      addedById: addedBy,
      buyerMemberId: buyer,
      isPurchased: purchasedBy != null,
      purchasedById: purchasedBy,
      purchasedAt: purchasedAt,
      createdAt: day(-5, 9),
    );

    data.shoppingItems.addAll([
      item(
        'demo-bread',
        t('Non', 'Хлеб'),
        t('3 ta', '3 шт.'),
        ShoppingCategory.food,
        buyer: sardor,
      ),
      item(
        'demo-eggs',
        t('Tuxum', 'Яйца'),
        t('10 ta', '10 шт.'),
        ShoppingCategory.food,
      ),
      item(
        'demo-milk',
        t('Sut', 'Молоко'),
        t('2 l', '2 л'),
        ShoppingCategory.food,
      ),
      item(
        'demo-rice',
        t('Guruch', 'Рис'),
        t('5 kg', '5 кг'),
        ShoppingCategory.food,
        notes: t('Palov uchun devzira', 'Девзира для плова'),
        addedBy: sardor,
      ),
      item(
        'demo-oil',
        t('Kungaboqar yogʻi', 'Подсолнечное масло'),
        t('1 l', '1 л'),
        ShoppingCategory.food,
      ),
      item(
        'demo-tea',
        t('Koʻk choy', 'Зелёный чай'),
        t('1 quti', '1 пачка'),
        ShoppingCategory.drinks,
        addedBy: aziz,
      ),
      item(
        'demo-detergent',
        t('Kir yuvish kukuni', 'Стиральный порошок'),
        t('1 paket', '1 пачка'),
        ShoppingCategory.cleaning,
        buyer: dilnoza,
      ),
      item(
        'demo-water',
        t('Ichimlik suvi', 'Питьевая вода'),
        t('2 × 19 l', '2 × 19 л'),
        ShoppingCategory.drinks,
        purchasedBy: sardor,
        purchasedAt: day(-3, 17),
      ),
      item(
        'demo-dish-soap',
        t('Idish yuvish vositasi', 'Средство для посуды'),
        t('1 ta', '1 шт.'),
        ShoppingCategory.cleaning,
        purchasedBy: dilnoza,
        purchasedAt: day(-4, 19),
      ),
      item(
        'demo-tissue',
        t('Hojatxona qogʻozi', 'Туалетная бумага'),
        t('1 paket', '1 упаковка'),
        ShoppingCategory.hygiene,
        purchasedBy: madina,
        purchasedAt: day(-1, 17),
      ),
    ]);
  }

  Expense _expense(
    String id,
    String title,
    int amount,
    String payer,
    ExpenseCategory category,
    DateTime date, {
    List<String> participants = everyone,
    Map<String, int>? custom,
    String? billId,
    DateTime? billPeriod,
    List<String>? items,
    String notes = '',
  }) => Expense(
    id: id,
    householdId: householdId,
    title: title,
    amountUzs: amount,
    payerMemberId: payer,
    splitAmountsByMemberId: custom ?? splitEqually(amount, participants),
    splitMode: custom == null ? SplitMode.equal : SplitMode.custom,
    category: category,
    date: date,
    createdAt: date,
    createdById: payer,
    billId: billId,
    billPeriod: billPeriod,
    shoppingItemIds: items,
    notes: notes,
  );

  void _addBillsAndExpenses(AppData data) {
    final rentPeriod = DateTime(today.year, today.month, 1);
    final internetFirst = addMonths(addDays(today, 3), -1);
    final electricityFirst = addMonths(addDays(today, -2), -1);

    HouseholdBill bill(
      String id,
      String name,
      BillType type,
      int amount,
      DateTime first,
      String responsible, {
      String notes = '',
    }) => HouseholdBill(
      id: id,
      householdId: householdId,
      name: name,
      type: type,
      expectedAmountUzs: amount,
      firstDueDate: first,
      frequency: BillFrequency.monthly,
      responsibleMemberId: responsible,
      participantMemberIds: List.of(everyone),
      notes: notes,
      createdAt: day(-60),
    );

    data.bills.addAll([
      bill(
        'demo-rent',
        t('Ijara', 'Аренда'),
        BillType.rent,
        6000000,
        rentPeriod,
        aziz,
        notes: t(
          'Uy egasiga har oyning 1-sanasigacha, karta orqali.',
          'Хозяину квартиры до 1-го числа, на карту.',
        ),
      ),
      bill(
        'demo-internet',
        t('Internet (uy Wi‑Fi)', 'Интернет (домашний Wi‑Fi)'),
        BillType.internet,
        160000,
        internetFirst,
        madina,
      ),
      bill(
        'demo-electricity',
        t('Elektr energiyasi', 'Электроэнергия'),
        BillType.electricity,
        94000,
        electricityFirst,
        sardor,
        notes: t(
          'Summa har oy hisoblagichga qarab oʻzgaradi.',
          'Сумма меняется по счётчику.',
        ),
      ),
      bill('demo-gas', t('Gaz', 'Газ'), BillType.gas, 45000, day(12), dilnoza),
      bill(
        'demo-water-bill',
        t('Suv (sovuq va issiq)', 'Вода (холодная и горячая)'),
        BillType.water,
        38000,
        day(8),
        madina,
      ),
    ]);

    data.expenses.addAll([
      _expense(
        'demo-e1',
        t(
          'Bozorlik: non, tuxum, sut, guruch',
          'Продукты: хлеб, яйца, молоко, рис',
        ),
        120000,
        aziz,
        ExpenseCategory.groceries,
        day(-1, 18, 30),
      ),
      _expense(
        'demo-e2',
        t(
          'Internet — ${dates.monthName(internetFirst)}',
          'Интернет — ${dates.monthName(internetFirst)}',
        ),
        160000,
        madina,
        ExpenseCategory.internet,
        internetFirst,
        billId: 'demo-internet',
        billPeriod: internetFirst,
      ),
      _expense(
        'demo-e3',
        t('Ichimlik suvi, 2 × 19 l', 'Питьевая вода, 2 × 19 л'),
        36000,
        sardor,
        ExpenseCategory.groceries,
        day(-3, 17),
        items: ['demo-water'],
      ),
      _expense(
        'demo-e4',
        t('Idish yuvish vositasi va gubkalar', 'Средство для посуды и губки'),
        27000,
        dilnoza,
        ExpenseCategory.household,
        day(-4, 19),
        items: ['demo-dish-soap'],
      ),
      _expense(
        'demo-e5',
        t(
          'Elektr energiyasi — ${dates.monthName(electricityFirst)}',
          'Электроэнергия — ${dates.monthName(electricityFirst)}',
        ),
        94000,
        aziz,
        ExpenseCategory.utilities,
        electricityFirst,
        billId: 'demo-electricity',
        billPeriod: electricityFirst,
      ),
      _expense(
        'demo-e6',
        t('Palov uchun masalliqlar', 'Продукты для плова'),
        210000,
        sardor,
        ExpenseCategory.groceries,
        day(-6, 12),
        custom: {aziz: 60000, madina: 45000, sardor: 60000, dilnoza: 45000},
        notes: t(
          'Aziz va Sardor koʻproq yedi — oʻzlari shunday kelishdi.',
          'Азиз и Сардор съели больше — так договорились.',
        ),
      ),
      _expense(
        'demo-e7',
        t('Taksi: Chorsu bozoriga', 'Такси: на базар Чорсу'),
        32000,
        madina,
        ExpenseCategory.transport,
        day(-6, 10),
        participants: [madina, dilnoza],
      ),
      _expense(
        'demo-e8',
        t(
          'Ijara — ${dates.monthName(rentPeriod)}',
          'Аренда — ${dates.monthName(rentPeriod)}',
        ),
        6000000,
        aziz,
        ExpenseCategory.rent,
        rentPeriod,
        billId: 'demo-rent',
        billPeriod: rentPeriod,
      ),
    ]);

    Settlement payment(
      String id,
      String from,
      String to,
      int amount,
      PaymentMethod method,
    ) => Settlement(
      id: id,
      householdId: householdId,
      fromMemberId: from,
      toMemberId: to,
      amountUzs: amount,
      method: method,
      date: day(-2, 20),
      createdAt: day(-2, 20),
      recordedById: from,
      note: t('Ijara ulushi', 'Доля аренды'),
    );
    data.settlements.addAll([
      payment('demo-s1', madina, aziz, 1500000, PaymentMethod.card),
      payment('demo-s2', sardor, aziz, 1500000, PaymentMethod.cash),
    ]);
  }

  void _addChores(AppData data) {
    final active = everyone.toSet();

    Chore chore(
      String id,
      String title,
      ChoreFrequency frequency,
      Priority priority, {
      String notes = '',
    }) {
      final c = Chore(
        id: id,
        householdId: householdId,
        title: title,
        frequency: frequency,
        eligibleMemberIds: List.of(everyone),
        priority: priority,
        notes: notes,
        createdAt: day(-60),
        createdById: madina,
      );
      data.chores.add(c);
      return c;
    }

    void history(
      Chore c,
      List<(int, String)> turns, {
      Map<int, String> skipped = const {},
    }) {
      for (final (offset, member) in turns) {
        final due = addDays(today, offset);
        final reason = skipped[offset];
        data.assignments.add(
          ChoreAssignment(
            id: '${c.id}-$offset',
            choreId: c.id,
            assigneeMemberId: member,
            dueDate: due,
            createdAt: addDays(due, -1),
            status: reason == null
                ? AssignmentStatus.completed
                : AssignmentStatus.skipped,
            completedAt: reason == null ? withTime(due, 20, 15) : null,
            skipReason: reason,
          ),
        );
      }
    }

    ChoreAssignment current(Chore c, int dueOffset) {
      final decision = decideNextAssignee(
        chore: c,
        allAssignments: data.assignments,
        activeMemberIds: active,
      );
      final a = ChoreAssignment(
        id: '${c.id}-current',
        choreId: c.id,
        assigneeMemberId: decision.memberId!,
        dueDate: addDays(today, dueOffset),
        createdAt: addDays(today, dueOffset - 1),
      );
      data.assignments.add(a);
      return a;
    }

    final dishes = chore(
      'demo-dishes',
      t('Idish yuvish', 'Мытьё посуды'),
      ChoreFrequency.daily,
      Priority.high,
      notes: t(
        'Kechki ovqatdan keyin, oʻsha kuni.',
        'После ужина, в тот же день.',
      ),
    );
    history(dishes, [
      (-8, aziz),
      (-7, madina),
      (-6, sardor),
      (-5, dilnoza),
      (-4, aziz),
      (-3, madina),
      (-2, sardor),
      (-1, dilnoza),
    ]);
    current(dishes, 0);

    final trash = chore(
      'demo-trash',
      t('Axlatni chiqarish', 'Вынести мусор'),
      ChoreFrequency.everyOtherDay,
      Priority.medium,
    );
    history(
      trash,
      [
        (-15, sardor),
        (-13, dilnoza),
        (-11, aziz),
        (-9, madina),
        (-7, sardor),
        (-5, dilnoza),
        (-3, dilnoza),
        (-1, aziz),
      ],
      skipped: {
        -5: t(
          'Dam olish kunlari viloyatga, uyiga ketgan edi',
          'На выходных уезжала домой в область',
        ),
      },
    );
    current(trash, 1);

    final floor = chore(
      'demo-floor',
      t('Polni supurish va yuvish', 'Подмести и помыть пол'),
      ChoreFrequency.weekly,
      Priority.medium,
    );
    history(floor, [(-26, aziz), (-19, madina), (-12, sardor), (-5, dilnoza)]);
    final floorTurn = current(floor, 2);

    final bathroom = chore(
      'demo-bathroom',
      t('Hammom va hojatxonani tozalash', 'Уборка ванной и туалета'),
      ChoreFrequency.weekly,
      Priority.high,
    );
    history(bathroom, [(-29, dilnoza), (-22, aziz), (-15, madina)]);
    current(bathroom, -1);

    final water = chore(
      'demo-water-run',
      t('Ichimlik suvi olib kelish (19 l)', 'Привезти питьевую воду (19 л)'),
      ChoreFrequency.weekly,
      Priority.medium,
    );
    history(water, [(-24, sardor), (-17, aziz), (-10, madina)]);
    final waterTurn = current(water, 4);

    final fridge = chore(
      'demo-fridge',
      t('Muzlatgichni tozalash', 'Помыть холодильник'),
      ChoreFrequency.monthly,
      Priority.low,
    );
    history(fridge, [(-51, madina), (-21, sardor)]);
    current(fridge, 9);

    final swapAt = day(-2, 21);
    final floorMember = floorTurn.assigneeMemberId;
    final waterMember = waterTurn.assigneeMemberId;
    if (floorMember != waterMember) {
      floorTurn.changes.add(
        AssignmentChange(
          type: AssignmentChangeType.swapped,
          fromMemberId: floorMember,
          toMemberId: waterMember,
          changedById: floorMember,
          at: swapAt,
        ),
      );
      waterTurn.changes.add(
        AssignmentChange(
          type: AssignmentChangeType.swapped,
          fromMemberId: waterMember,
          toMemberId: floorMember,
          changedById: floorMember,
          at: swapAt,
        ),
      );
      floorTurn.assigneeMemberId = waterMember;
      waterTurn.assigneeMemberId = floorMember;
    }
  }

  void _addPlanner(AppData data) {
    var counter = 0;
    PlannerItem item(
      String owner,
      String title,
      PlannerCategory category,
      DateTime due, {
      DateTime? end,
      String course = '',
      String description = '',
      Priority priority = Priority.medium,
      bool weekly = false,
      bool completed = false,
    }) {
      counter++;
      return PlannerItem(
        id: 'demo-plan-$counter',
        ownerMemberId: owner,
        title: title,
        category: category,
        dueAt: due,
        endAt: end,
        course: course,
        description: description,
        priority: priority,
        recurrence: weekly ? Recurrence.weekly : Recurrence.none,
        isCompleted: completed,
        completedAt: completed ? due.subtract(const Duration(hours: 2)) : null,
        createdAt: day(-20),
      );
    }

    DateTime classDay(int offset, int hour, int minute) {
      var d = addDays(today, offset - 42);
      if (d.weekday == DateTime.sunday) d = addDays(d, 1);
      return withTime(d, hour, minute);
    }

    final mobile = t('Mobil dasturlash', 'Мобильная разработка');
    final databases = t('Maʼlumotlar bazasi', 'Базы данных');
    final discrete = t('Diskret matematika', 'Дискретная математика');
    final english = t('Ingliz tili (B2)', 'Английский язык (B2)');

    DateTime end(DateTime start, int minutes) =>
        start.add(Duration(minutes: minutes));
    final c1 = classDay(0, 9, 0);
    final c2 = classDay(0, 13, 30);
    final c3 = classDay(1, 10, 30);
    final c4 = classDay(4, 9, 0);
    final c5 = classDay(5, 11, 0);

    data.plannerItems.addAll([
      item(
        aziz,
        mobile,
        PlannerCategory.classSession,
        c1,
        end: end(c1, 80),
        course: mobile,
        description: t(
          'B-305 xona, maʼruza + amaliyot',
          'Ауд. B-305, лекция + практика',
        ),
        weekly: true,
      ),
      item(
        aziz,
        databases,
        PlannerCategory.classSession,
        c2,
        end: end(c2, 80),
        course: databases,
        description: t('Kompyuter xonasi 2', 'Компьютерный класс 2'),
        weekly: true,
      ),
      item(
        aziz,
        discrete,
        PlannerCategory.classSession,
        c3,
        end: end(c3, 80),
        course: discrete,
        weekly: true,
      ),
      item(
        aziz,
        english,
        PlannerCategory.classSession,
        c4,
        end: end(c4, 80),
        course: english,
        weekly: true,
      ),
      item(
        aziz,
        t('Dasturiy injiniring', 'Программная инженерия'),
        PlannerCategory.classSession,
        c5,
        end: end(c5, 80),
        course: t('Dasturiy injiniring', 'Программная инженерия'),
        weekly: true,
      ),
      item(
        aziz,
        t(
          'Midterm taklifi: Birga loyihasi',
          'Мидтерм: предложение проекта Birga',
        ),
        PlannerCategory.assignment,
        day(2, 23, 59),
        course: mobile,
        priority: Priority.high,
        description: t(
          'Muammo, dalillar, 5 ta ekran, wireframe va maʼlumotlar modeli.',
          'Проблема, доказательства, 5 экранов, вайрфреймы и модель данных.',
        ),
      ),
      item(
        aziz,
        t('4-laboratoriya: SQL soʻrovlar', 'Лабораторная 4: SQL-запросы'),
        PlannerCategory.homework,
        day(1, 18, 0),
        course: databases,
      ),
      item(
        aziz,
        t('Oraliq nazorat', 'Промежуточный контроль'),
        PlannerCategory.exam,
        day(6, 10, 30),
        course: discrete,
        priority: Priority.high,
        description: t(
          '1–6-mavzular: mantiq, toʻplamlar, graflar.',
          'Темы 1–6: логика, множества, графы.',
        ),
      ),
      item(
        aziz,
        t(
          'Guruh loyihasi: prototip taqdimoti',
          'Групповой проект: презентация прототипа',
        ),
        PlannerCategory.project,
        day(10, 14, 0),
        course: t('Dasturiy injiniring', 'Программная инженерия'),
      ),
      item(
        aziz,
        t('Kutubxonaga kitobni qaytarish', 'Вернуть книгу в библиотеку'),
        PlannerCategory.personalTask,
        day(0, 17, 0),
        priority: Priority.low,
      ),
      item(
        aziz,
        t(
          'Nazoratga tayyorgarlik (Sardor bilan)',
          'Подготовка к контрольной (с Сардором)',
        ),
        PlannerCategory.study,
        day(3, 19, 0),
        end: day(3, 21, 0),
        course: discrete,
      ),
      item(
        aziz,
        t('Fizika: laboratoriya hisoboti', 'Физика: отчёт по лабораторной'),
        PlannerCategory.homework,
        day(-1, 23, 59),
        course: t('Fizika', 'Физика'),
      ),
      item(
        aziz,
        t('Ingliz tili: essay (250 soʻz)', 'Английский: эссе (250 слов)'),
        PlannerCategory.assignment,
        day(-1, 12, 0),
        course: english,
        completed: true,
      ),
      item(
        madina,
        t('Iqtisodiyot nazariyasi — referat', 'Экономическая теория — реферат'),
        PlannerCategory.assignment,
        day(4, 23, 59),
        course: t('Iqtisodiyot nazariyasi', 'Экономическая теория'),
        priority: Priority.high,
      ),
      item(
        madina,
        t('Statistika', 'Статистика'),
        PlannerCategory.classSession,
        classDay(2, 10, 30),
        end: end(classDay(2, 10, 30), 80),
        course: t('Statistika', 'Статистика'),
        weekly: true,
      ),
      item(
        sardor,
        t('Fizika — oraliq nazorat', 'Физика — промежуточный контроль'),
        PlannerCategory.exam,
        day(5, 9, 0),
        course: t('Fizika', 'Физика'),
        priority: Priority.high,
      ),
      item(
        dilnoza,
        t('IELTS mock test', 'Пробный IELTS'),
        PlannerCategory.exam,
        day(7, 9, 30),
        course: t('Ingliz tili', 'Английский язык'),
      ),
    ]);
  }

  void _addEventsPollsIssues(AppData data) {
    HouseholdEvent event(
      String id,
      String title,
      EventType type,
      DateTime start,
      String by, {
      DateTime? end,
      String notes = '',
    }) => HouseholdEvent(
      id: id,
      householdId: householdId,
      title: title,
      type: type,
      startAt: start,
      endAt: end,
      notes: notes,
      createdById: by,
      createdAt: day(-3),
    );

    var saturday = addDays(today, 1);
    while (saturday.weekday != DateTime.saturday) {
      saturday = addDays(saturday, 1);
    }

    data.events.addAll([
      event(
        'demo-ev1',
        t(
          'Santexnik keladi (oshxona krani)',
          'Придёт сантехник (кран на кухне)',
        ),
        EventType.maintenance,
        day(1, 10, 0),
        sardor,
        notes: t('Kimdir uyda boʻlishi kerak.', 'Кто-то должен быть дома.'),
      ),
      event(
        'demo-ev2',
        t('Uy yigʻilishi: tozalash jadvali', 'Собрание: график уборки'),
        EventType.meeting,
        day(2, 20, 0),
        madina,
        end: day(2, 20, 30),
      ),
      event(
        'demo-ev3',
        t('Mehmonlar: Sardorning kursdoshlari', 'Гости: одногруппники Сардора'),
        EventType.guests,
        day(4, 19, 0),
        sardor,
        end: day(4, 22, 0),
      ),
      event(
        'demo-ev4',
        t('Haftalik bozorlik — Chorsu', 'Еженедельный базар — Чорсу'),
        EventType.shopping,
        withTime(saturday, 10, 0),
        sardor,
      ),
    ]);

    data.polls.addAll([
      HouseholdPoll(
        id: 'demo-poll1',
        householdId: householdId,
        question: t(
          'Elektr choynakni almashtiramizmi?',
          'Меняем электрочайник?',
        ),
        options: [
          PollOption(
            id: 'demo-poll1-a',
            text: t(
              'Ha, yangisini olamiz (≈180 000 soʻm)',
              'Да, купим новый (≈180 000 сум)',
            ),
          ),
          PollOption(
            id: 'demo-poll1-b',
            text: t(
              'Yoʻq, avval taʼmirlatib koʻramiz',
              'Нет, сначала попробуем починить',
            ),
          ),
          PollOption(
            id: 'demo-poll1-c',
            text: t('Keyingi oyga qoldiramiz', 'Отложим до следующего месяца'),
          ),
        ],
        votesByMemberId: {
          aziz: 'demo-poll1-a',
          madina: 'demo-poll1-a',
          sardor: 'demo-poll1-b',
        },
        createdById: madina,
        createdAt: day(-1, 20, 10),
        deadline: day(2, 21, 0),
      ),
      HouseholdPoll(
        id: 'demo-poll2',
        householdId: householdId,
        question: t(
          'Katta tozalash qaysi kuni boʻlsin?',
          'В какой день делаем генеральную уборку?',
        ),
        options: [
          PollOption(
            id: 'demo-poll2-a',
            text: t('Shanba, ertalab', 'Суббота, утром'),
          ),
          PollOption(
            id: 'demo-poll2-b',
            text: t('Yakshanba, kechqurun', 'Воскресенье, вечером'),
          ),
        ],
        votesByMemberId: {
          aziz: 'demo-poll2-a',
          madina: 'demo-poll2-a',
          sardor: 'demo-poll2-b',
          dilnoza: 'demo-poll2-a',
        },
        createdById: madina,
        createdAt: day(-9, 19),
        deadline: day(-6, 21),
        closedAt: day(-6, 21),
        closedById: madina,
      ),
    ]);

    data.issues.addAll([
      HouseholdIssue(
        id: 'demo-issue1',
        householdId: householdId,
        title: t('Oshxonadagi kran oqyapti', 'Течёт кран на кухне'),
        description: t(
          'Yopiq turganda ham tomchilab turadi.',
          'Капает даже в закрытом положении.',
        ),
        category: IssueCategory.plumbing,
        priority: Priority.high,
        status: IssueStatus.inProgress,
        assigneeMemberId: sardor,
        reportedById: madina,
        createdAt: day(-4, 8),
      ),
      HouseholdIssue(
        id: 'demo-issue2',
        householdId: householdId,
        title: t(
          'Kir yuvish mashinasi siqmayapti',
          'Стиральная машина не отжимает',
        ),
        description: t(
          'Yuvadi, lekin siqish rejimida toʻxtab qoladi.',
          'Стирает, но останавливается на отжиме.',
        ),
        category: IssueCategory.appliance,
        priority: Priority.medium,
        reportedById: dilnoza,
        createdAt: day(-2, 21),
      ),
      HouseholdIssue(
        id: 'demo-issue3',
        householdId: householdId,
        title: t('Wi‑Fi kechqurun uzilib qoladi', 'Wi‑Fi пропадает по вечерам'),
        category: IssueCategory.internet,
        priority: Priority.low,
        status: IssueStatus.resolved,
        assigneeMemberId: aziz,
        reportedById: sardor,
        createdAt: day(-12, 22),
        resolvedAt: day(-8, 18),
        resolutionNotes: t(
          'Router qayta sozlandi, provayder bilan gaplashildi — hozircha muammo yoʻq.',
          'Роутер перенастроили, поговорили с провайдером — пока проблем нет.',
        ),
      ),
    ]);
  }

  void _addRulesAndActivity(AppData data) {
    HouseRule rule(String id, String title, String details) => HouseRule(
      id: id,
      householdId: householdId,
      title: title,
      details: details,
      createdById: madina,
      createdAt: day(-55),
    );

    data.rules.addAll([
      rule(
        'demo-rule1',
        t('Tinchlik soatlari: 23:00–07:00', 'Тихие часы: 23:00–07:00'),
        t(
          'Baland ovozda gaplashmaymiz, musiqani quloqchinda tinglaymiz.',
          'Не шумим, музыку слушаем в наушниках.',
        ),
      ),
      rule(
        'demo-rule2',
        t('Mehmonlar', 'Гости'),
        t(
          'Mehmon kelishini kamida bir kun oldin aytamiz. Mehmonlar 22:00 gacha.',
          'О гостях предупреждаем минимум за день. Гости — до 22:00.',
        ),
      ),
      rule(
        'demo-rule3',
        t('Idishlar', 'Посуда'),
        t(
          'Ishlatilgan idish oʻsha kuni yuviladi, lavaboda qoldirilmaydi.',
          'Посуду моем в тот же день, в раковине не оставляем.',
        ),
      ),
      rule(
        'demo-rule4',
        t('Umumiy mahsulotlar', 'Общие продукты'),
        t(
          'Biror narsa tugasa — darhol xarid roʻyxatiga qoʻshamiz.',
          'Если что-то закончилось — сразу добавляем в список покупок.',
        ),
      ),
    ]);

    data.announcements.add(
      Announcement(
        id: 'demo-note1',
        householdId: householdId,
        message: t(
          'Santexnik ${dates.day(addDays(today, 1))} kuni soat 10:00 da keladi — kim uyda boʻladi? Kran muammosi uchun.',
          'Сантехник придёт ${dates.day(addDays(today, 1))} в 10:00 — кто будет дома? По поводу крана.',
        ),
        authorId: madina,
        createdAt: day(-1, 21),
      ),
    );

    var counter = 0;
    ActivityEntry entry(
      ActivityType type,
      String actor,
      DateTime at, {
      String subject = '',
      int? amount,
      String? other,
    }) {
      counter++;
      return ActivityEntry(
        id: 'demo-act-$counter',
        type: type,
        actorId: actor,
        at: at,
        subject: subject,
        amountUzs: amount,
        otherMemberId: other,
      );
    }

    data.activity.addAll([
      entry(
        ActivityType.announcementPosted,
        madina,
        day(-1, 21),
        subject: data.announcements.first.message,
      ),
      entry(
        ActivityType.pollCreated,
        madina,
        day(-1, 20, 10),
        subject: data.polls.first.question,
      ),
      entry(
        ActivityType.choreCompleted,
        dilnoza,
        day(-1, 20, 15),
        subject: t('Idish yuvish', 'Мытьё посуды'),
      ),
      entry(
        ActivityType.expenseAdded,
        aziz,
        day(-1, 18, 40),
        subject: t(
          'Bozorlik: non, tuxum, sut, guruch',
          'Продукты: хлеб, яйца, молоко, рис',
        ),
        amount: 120000,
      ),
      entry(
        ActivityType.shoppingPurchased,
        madina,
        day(-1, 17),
        subject: t('Hojatxona qogʻozi', 'Туалетная бумага'),
      ),
      entry(
        ActivityType.choreSwapped,
        aziz,
        day(-2, 21),
        subject: 'Aziz',
        other: dilnoza,
      ),
      entry(
        ActivityType.issueReported,
        dilnoza,
        day(-2, 21),
        subject: t(
          'Kir yuvish mashinasi siqmayapti',
          'Стиральная машина не отжимает',
        ),
      ),
      entry(
        ActivityType.settlementRecorded,
        sardor,
        day(-2, 20),
        subject: 'Sardor',
        amount: 1500000,
        other: aziz,
      ),
      entry(
        ActivityType.settlementRecorded,
        madina,
        day(-2, 20),
        subject: 'Madina',
        amount: 1500000,
        other: aziz,
      ),
      entry(
        ActivityType.expenseAdded,
        sardor,
        day(-3, 17),
        subject: t('Ichimlik suvi, 2 × 19 l', 'Питьевая вода, 2 × 19 л'),
        amount: 36000,
      ),
    ]);
  }
}

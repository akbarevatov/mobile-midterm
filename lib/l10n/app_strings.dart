import '../models/activity_entry.dart';
import '../models/chore.dart';
import '../models/expense.dart';
import '../models/household_bill.dart';
import '../models/household_event.dart';
import '../models/household_issue.dart';
import '../models/planner_item.dart';
import '../models/priority.dart';
import '../models/settlement.dart';
import '../models/shopping_item.dart';
import '../services/calculations/bill_schedule.dart';
import '../services/calculations/money_split.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../utils/date_math.dart';
import '../utils/validators.dart';
import 'app_language.dart';

class AppStrings {
  const AppStrings(this.language);

  final AppLanguage language;

  bool get _uz => language == AppLanguage.uz;
  String _t(String uz, String ru) => _uz ? uz : ru;

  DateFormatter get dates => DateFormatter(language);
  String money(int amount, {bool showPlus = false}) =>
      formatUzs(amount, language, showPlus: showPlus);
  String get currency => currencyName(language);

  String get appName => 'Birga';
  String get save => _t('Saqlash', 'Сохранить');
  String get cancel => _t('Bekor qilish', 'Отмена');
  String get delete => _t('Oʻchirish', 'Удалить');
  String get edit => _t('Tahrirlash', 'Изменить');
  String get add => _t('Qoʻshish', 'Добавить');
  String get close => _t('Yopish', 'Закрыть');
  String get undo => _t('Qaytarish', 'Отменить');
  String get all => _t('Hammasi', 'Все');
  String get none => _t('Hech kim', 'Никто');
  String get seeAll => _t('Hammasini koʻrish', 'Смотреть все');
  String get notesOptional =>
      _t('Izoh (ixtiyoriy)', 'Комментарий (необязательно)');
  String get date => _t('Sana', 'Дата');
  String get time => _t('Vaqt', 'Время');
  String get priority => _t('Muhimlik', 'Важность');
  String get deleted => _t('Oʻchirildi', 'Удалено');
  String get saved => _t('Saqlandi', 'Сохранено');
  String get you => _t('siz', 'вы');
  String get demo => 'Demo';
  String get fixErrors =>
      _t('Belgilangan maydonlarni tekshiring', 'Проверьте отмеченные поля');
  String get noDate => _t('Tanlanmagan', 'Не выбрано');
  String get pickDate => _t('Sanani tanlang', 'Выберите дату');
  String get pickTime => _t('Vaqtni tanlang', 'Выберите время');
  String get loading => _t('Yuklanmoqda…', 'Загрузка…');
  String get moreActions => _t('Boshqa amallar', 'Другие действия');

  String priorityLabel(Priority p) => switch (p) {
    Priority.low => _t('Past', 'Низкая'),
    Priority.medium => _t('Oʻrta', 'Средняя'),
    Priority.high => _t('Yuqori', 'Высокая'),
  };

  String get fieldRequired =>
      _t('Bu maydonni toʻldiring', 'Заполните это поле');
  String textTooLong(int max) => _t(
    'Juda uzun (koʻpi bilan $max belgi)',
    'Слишком длинно (не более $max символов)',
  );

  String? textError(TextError? error, {int maxLength = 80}) => switch (error) {
    null => null,
    TextError.empty => fieldRequired,
    TextError.tooLong => textTooLong(maxLength),
  };

  String? amountError(AmountError? error) => switch (error) {
    null => null,
    AmountError.empty => _t('Summani kiriting', 'Введите сумму'),
    AmountError.invalid => _t(
      'Faqat raqamlar, masalan 120 000',
      'Только цифры, например 120 000',
    ),
    AmountError.notPositive => _t(
      'Summa 0 dan katta boʻlishi kerak',
      'Сумма должна быть больше 0',
    ),
    AmountError.tooLarge => _t(
      'Summa juda katta (1 mlrd soʻmgacha)',
      'Слишком большая сумма (до 1 млрд сум)',
    ),
  };

  String splitError(SplitError error) => switch (error) {
    SplitError.noParticipants => chooseParticipants,
    SplitError.missingShare => _t(
      'Har bir ishtirokchi uchun summa kiriting',
      'Введите сумму для каждого участника',
    ),
    SplitError.nonPositiveShare => _t(
      'Ulush 0 dan katta boʻlishi kerak',
      'Доля должна быть больше 0',
    ),
    SplitError.sumMismatch => _t(
      'Ulushlar yigʻindisi umumiy summaga teng boʻlishi kerak',
      'Сумма долей должна совпадать с общей суммой',
    ),
  };

  String timeAgo(DateTime at, DateTime now) {
    final minutes = now.difference(at).inMinutes;
    if (minutes < 1) return _t('hozirgina', 'только что');
    if (minutes < 60) return _t('$minutes daqiqa oldin', '$minutes мин. назад');
    final hours = now.difference(at).inHours;
    if (hours < 24 && isSameDay(at, now)) {
      return _t('$hours soat oldin', '$hours ч. назад');
    }
    return dates.relativeDay(at, dateOnly(now));
  }

  String dueLabel(DateTime due, DateTime now, {bool withTime = false}) {
    final rel = dates.relativeDay(due, dateOnly(now));
    return withTime ? '$rel, ${dates.time(due)}' : rel;
  }

  String get navHome => _t('Asosiy', 'Главная');
  String get navMoney => _t('Pul', 'Деньги');
  String get navChores => _t('Uy ishlari', 'Дежурства');
  String get navPlanner => _t('Reja', 'Планер');
  String get navHousehold => _t('Xonadon', 'Дом');

  String get tagline => _t(
    'Xonadoshlar bilan umumiy roʻzgʻor va oʻqish rejalari — bir joyda.',
    'Общий быт с соседями и учёба — в одном месте.',
  );
  String get startDemo => _t('Demo xonadonni ochish', 'Открыть демо-квартиру');
  String get demoHint => _t(
    'Toʻrt nafar talabaning toʻqima maʼlumotlari bilan ilovani koʻrib chiqing.',
    'Посмотрите приложение на вымышленных данных четырёх студентов.',
  );
  String get createHousehold =>
      _t('Yangi xonadon yaratish', 'Создать свою квартиру');
  String get localOnlyNote => _t(
    'Maʼlumotlar faqat shu qurilmada saqlanadi. Telefonlar oʻrtasida sinxronlash hali yoʻq.',
    'Данные хранятся только на этом устройстве. Синхронизации между телефонами пока нет.',
  );
  String get unreadableData => _t(
    'Avval saqlangan maʼlumotlarni oʻqib boʻlmadi. Ular oʻchirilmadi — zaxira nusxasi qurilmada qoldirildi.',
    'Не удалось прочитать сохранённые данные. Они не удалены — резервная копия осталась на устройстве.',
  );
  String get storageUnavailable => _t(
    'Qurilma xotirasini ochib boʻlmadi. Ilova ishlaydi, lekin oʻzgarishlar saqlanmasligi mumkin.',
    'Не удалось открыть хранилище устройства. Приложение работает, но изменения могут не сохраниться.',
  );
  String get newHouseholdTitle => _t('Yangi xonadon', 'Новая квартира');
  String get householdName => _t('Xonadon nomi', 'Название квартиры');
  String get householdNameHint =>
      _t('Masalan: Yunusoboddagi kvartira', 'Например: квартира на Юнусабаде');
  String get yourName => _t('Ismingiz', 'Ваше имя');
  String get roommates => _t('Xonadoshlar', 'Соседи');
  String get roommateName => _t('Xonadosh ismi', 'Имя соседа');
  String get addRoommate => _t('Xonadosh qoʻshish', 'Добавить соседа');
  String get roommatesOptionalHint => _t(
    'Yolgʻiz yashasangiz, boʻsh qoldiring — reja va xarajatlar baribir ishlaydi.',
    'Если живёте один, оставьте пустым — планер и расходы всё равно работают.',
  );
  String get create => _t('Yaratish', 'Создать');
  String get removeRoommate => _t('Olib tashlash', 'Убрать');

  String greeting(String name) => _t('Salom, $name', 'Привет, $name');
  String get switchProfile => _t('Profilni almashtirish', 'Сменить профиль');
  String get settings => _t('Sozlamalar', 'Настройки');
  String get needsAttention =>
      _t('Bugun eʼtibor talab qiladi', 'Требует внимания сегодня');
  String get allClear => _t(
    'Hammasi joyida — bugun shoshilinch ish yoʻq.',
    'Всё в порядке — срочных дел на сегодня нет.',
  );
  String get attentionChore => _t('Navbatchilik', 'Дежурство');
  String get attentionBill => _t('Toʻlov', 'Платёж');
  String get attentionTask => _t('Reja', 'Задача');
  String overdueSince(String rel) =>
      _t('muddati oʻtgan · $rel', 'просрочено · $rel');
  String dueUntil(String time) => _t('bugun $time gacha', 'сегодня до $time');
  String get dueToday => _t('bugun', 'сегодня');
  String get yourBalance => _t('Sizning balansingiz', 'Ваш баланс');
  String get owedToYou => _t('sizga qaytarishlari kerak', 'вам должны вернуть');
  String get youOwe => _t('siz qaytarishingiz kerak', 'вы должны вернуть');
  String get settledUp => _t('hisob-kitob teng', 'вы в расчёте');
  String get spentThisMonth =>
      _t('Shu oy umumiy xarajat', 'Общие расходы за месяц');
  String get nextBill => _t('Keyingi toʻlov', 'Ближайший платёж');
  String get noUpcomingBills =>
      _t('Yaqin toʻlovlar yoʻq', 'Ближайших платежей нет');
  String get nextDeadline => _t('Oʻqish muddati', 'Учебный дедлайн');
  String get noDeadlines =>
      _t('Yaqin muddatlar yoʻq', 'Ближайших дедлайнов нет');
  String get yourChoresToday =>
      _t('Bugungi navbatchiligingiz', 'Ваши дежурства сегодня');
  String get noChoresToday =>
      _t('Bugun sizda navbatchilik yoʻq', 'Сегодня у вас нет дежурств');
  String itemsToBuy(int n) =>
      _t('$n ta mahsulot olinishi kerak', 'Нужно купить: $n');
  String get shoppingAllBought => _t('Hammasi olingan', 'Всё куплено');
  String get recentActivity =>
      _t('Soʻnggi oʻzgarishlar', 'Последние изменения');
  String get noActivity => _t('Hali oʻzgarishlar yoʻq', 'Изменений пока нет');
  String get quickActions => _t('Tezkor amallar', 'Быстрые действия');
  String get qaExpense => _t('Xarajat', 'Расход');
  String get qaChore => _t('Navbatchilik', 'Дежурство');
  String get qaGrocery => _t('Xarid', 'Покупка');
  String get qaTask => _t('Vazifa', 'Задача');
  String get announcement => _t('Eʼlon', 'Объявление');
  String get whoIsUsing =>
      _t('Kim sifatida koʻryapsiz?', 'Под каким профилем смотрите?');
  String get profileSwitcherNote => _t(
    'Bu demo profil almashtirgich — haqiqiy kirish (login) emas. Har bir xonadosh ilovani oʻz koʻzi bilan koʻrishi uchun.',
    'Это переключатель демо-профилей, а не вход в аккаунт. Можно увидеть приложение глазами каждого соседа.',
  );
  String nowViewingAs(String name) =>
      _t('Endi $name sifatida koʻryapsiz', 'Теперь вы смотрите как $name');

  String activityText(
    ActivityEntry e,
    String actor,
    String other,
    String amount,
  ) => switch (e.type) {
    ActivityType.expenseAdded => _t(
      '$actor xarajat qoʻshdi: ${e.subject} ($amount)',
      '$actor добавил(а) расход: ${e.subject} ($amount)',
    ),
    ActivityType.expenseEdited => _t(
      '$actor xarajatni tahrirladi: ${e.subject}',
      '$actor изменил(а) расход: ${e.subject}',
    ),
    ActivityType.expenseDeleted => _t(
      '$actor xarajatni oʻchirdi: ${e.subject}',
      '$actor удалил(а) расход: ${e.subject}',
    ),
    ActivityType.settlementRecorded => _t(
      '${e.subject} → $other: $amount toʻlov qayd etildi',
      'Записан платёж ${e.subject} → $other: $amount',
    ),
    ActivityType.billPaid => _t(
      '$actor toʻlovni qayd etdi: ${e.subject} ($amount)',
      '$actor отметил(а) оплату: ${e.subject} ($amount)',
    ),
    ActivityType.choreCreated => _t(
      '$actor navbatchilik qoʻshdi: ${e.subject}',
      '$actor добавил(а) дежурство: ${e.subject}',
    ),
    ActivityType.choreCompleted =>
      e.otherMemberId == null
          ? _t(
              '$actor bajardi: ${e.subject}',
              '$actor выполнил(а): ${e.subject}',
            )
          : _t(
              '$actor belgiladi: «${e.subject}» bajarildi ($other)',
              '$actor отметил(а) за $other: ${e.subject}',
            ),
    ActivityType.choreSkipped => _t(
      '«${e.subject}» oʻtkazib yuborildi ($other navbati)',
      'Пропущено: «${e.subject}» (очередь: $other)',
    ),
    ActivityType.choreReassigned => _t(
      '$actor «${e.subject}» navbatini topshirdi → $other',
      '$actor передал(а) «${e.subject}» → $other',
    ),
    ActivityType.choreSwapped => _t(
      '${e.subject} va $other navbatchiliklarini almashdi',
      '${e.subject} и $other поменялись дежурствами',
    ),
    ActivityType.shoppingAdded => _t(
      '$actor roʻyxatga qoʻshdi: ${e.subject}',
      '$actor добавил(а) в список: ${e.subject}',
    ),
    ActivityType.shoppingPurchased => _t(
      '$actor sotib oldi: ${e.subject}',
      '$actor купил(а): ${e.subject}',
    ),
    ActivityType.eventAdded => _t(
      '$actor tadbir qoʻshdi: ${e.subject}',
      '$actor добавил(а) событие: ${e.subject}',
    ),
    ActivityType.pollCreated => _t(
      '$actor soʻrovnoma ochdi: ${e.subject}',
      '$actor создал(а) опрос: ${e.subject}',
    ),
    ActivityType.pollClosed => _t(
      '$actor soʻrovnomani yopdi: ${e.subject}',
      '$actor закрыл(а) опрос: ${e.subject}',
    ),
    ActivityType.issueReported => _t(
      '$actor muammo haqida yozdi: ${e.subject}',
      '$actor сообщил(а) о проблеме: ${e.subject}',
    ),
    ActivityType.issueResolved => _t(
      '$actor muammoni hal qildi: ${e.subject}',
      '$actor решил(а) проблему: ${e.subject}',
    ),
    ActivityType.announcementPosted => _t(
      '$actor eʼlon qoldirdi',
      '$actor оставил(а) объявление',
    ),
    ActivityType.memberAdded => _t(
      '$actor yangi xonadosh qoʻshdi: ${e.subject}',
      '$actor добавил(а) соседа: ${e.subject}',
    ),
  };

  String get moneyTitle => _t('Pul', 'Деньги');
  String get tabBalances => _t('Balans', 'Баланс');
  String get tabHistory => _t('Tarix', 'История');
  String get householdSpending => _t('Xonadon xarajatlari', 'Расходы квартиры');
  String get thisMonth => _t('Shu oy', 'Этот месяц');
  String get lastMonth => _t('Oʻtgan oy', 'Прошлый месяц');
  String get allTime => _t('Butun davr', 'За всё время');
  String get customRange => _t('Oraliq…', 'Период…');
  String get myShare => _t('Mening ulushim', 'Моя доля');
  String get iPaid => _t('Men toʻlaganim', 'Я заплатил(а)');
  String get whoOwesWhom => _t('Kim kimga qarzdor', 'Кто кому должен');
  String get balanceFormula => _t(
    'Balans = toʻlagan summasi − oʻz ulushi ± qayd etilgan toʻlovlar. Toʻlovchining oʻz ulushi qarz hisoblanmaydi.',
    'Баланс = оплачено − своя доля ± записанные платежи. Своя доля плательщика долгом не считается.',
  );
  String get isOwed => _t('qaytarib olishi kerak', 'ему/ей должны');
  String get owes => _t('qaytarishi kerak', 'должен(на) вернуть');
  String get even => _t('hisob teng', 'в расчёте');
  String paidAndShare(String paid, String share) =>
      _t('Toʻladi $paid · ulushi $share', 'Оплатил(а) $paid · доля $share');
  String get settleUpTitle =>
      _t('Qanday hisob-kitob qilish kerak', 'Как рассчитаться');
  String get settleUpNote => _t(
    'Eng kam oʻtkazmalar bilan. Birga pul oʻtkazmaydi — faqat qayd etadi.',
    'Минимум переводов. Birga не переводит деньги — только записывает.',
  );
  String get noDebts =>
      _t('Hamma hisob-kitob teng. Qarz yoʻq.', 'Все в расчёте. Долгов нет.');
  String get recordPayment => _t('Toʻlovni qayd etish', 'Записать платёж');
  String get recordShort => _t('Qayd etish', 'Записать');
  String get addExpense => _t('Xarajat qoʻshish', 'Добавить расход');
  String get billsShortcut => _t('Uy toʻlovlari', 'Платежи по дому');
  String get allCategories => _t('Barcha toifalar', 'Все категории');
  String get noTransactions => _t('Hali xarajatlar yoʻq', 'Расходов пока нет');
  String get noTransactionsHint => _t(
    'Birinchi umumiy xarajatni qoʻshing — masalan, bozorlik yoki internet.',
    'Добавьте первый общий расход — например, продукты или интернет.',
  );
  String get noMatches => _t(
    'Bu filtr boʻyicha hech narsa topilmadi',
    'По этому фильтру ничего не найдено',
  );
  String get clearFilters => _t('Filtrni tozalash', 'Сбросить фильтр');
  String paymentLine(String from, String to) =>
      _t('Toʻlov: $from → $to', 'Платёж: $from → $to');
  String paidBy(String name) => _t('$name toʻladi', 'Оплатил(а) $name');
  String splitBetween(int n) => _t('$n kishiga', 'на $n чел.');
  String yourShare(String amount) =>
      _t('Sizning ulushingiz: $amount', 'Ваша доля: $amount');
  String filteredTotal(String total) =>
      _t('Tanlangan davr: $total', 'За выбранный период: $total');
  String get paymentRecord => _t('toʻlov yozuvi', 'запись о платеже');

  String expenseCategory(ExpenseCategory c) => switch (c) {
    ExpenseCategory.groceries => _t('Oziq-ovqat', 'Продукты'),
    ExpenseCategory.household => _t('Uy-roʻzgʻor', 'Хозтовары'),
    ExpenseCategory.utilities => _t('Kommunal', 'Коммунальные'),
    ExpenseCategory.rent => _t('Ijara', 'Аренда'),
    ExpenseCategory.internet => _t('Internet va aloqa', 'Интернет и связь'),
    ExpenseCategory.transport => _t('Transport', 'Транспорт'),
    ExpenseCategory.eatingOut => _t('Tashqarida ovqat', 'Еда вне дома'),
    ExpenseCategory.other => _t('Boshqa', 'Другое'),
  };

  String paymentMethod(PaymentMethod m) => switch (m) {
    PaymentMethod.cash => _t('Naqd', 'Наличными'),
    PaymentMethod.card => _t('Kartaga oʻtkazma', 'Перевод на карту'),
  };

  String get newExpense => _t('Yangi xarajat', 'Новый расход');
  String get editExpense => _t('Xarajatni tahrirlash', 'Изменить расход');
  String get expenseTitle => _t('Nima uchun?', 'За что?');
  String get expenseTitleHint =>
      _t('Masalan: bozorlik, internet', 'Например: продукты, интернет');
  String get amount => _t('Summa', 'Сумма');
  String get category => _t('Toifa', 'Категория');
  String get whoPaid => _t('Kim toʻladi?', 'Кто заплатил?');
  String get whoShares => _t('Kimlar ulashadi?', 'Кто участвует?');
  String get splitHow => _t('Qanday boʻlinadi?', 'Как делим?');
  String get splitEqual => _t('Teng', 'Поровну');
  String get splitCustom => _t('Aniq summalar', 'Точные суммы');
  String get shares => _t('Ulushlar', 'Доли');
  String get remainderNote => _t(
    'Teng boʻlinmasa, qoldiq soʻmlar roʻyxatdagi birinchi ishtirokchilarga 1 soʻmdan qoʻshiladi.',
    'Если не делится поровну, остаток добавляется по 1 суму первым участникам списка.',
  );
  String unallocated(String amount) =>
      _t('Taqsimlanmagan: $amount', 'Не распределено: $amount');
  String overAllocated(String amount) =>
      _t('Ortiqcha: $amount', 'Лишнее: $amount');
  String get allocatedOk =>
      _t('Ulushlar umumiy summaga teng', 'Доли совпадают с общей суммой');
  String get fillEqually => _t('Teng boʻlib toʻldirish', 'Заполнить поровну');
  String payerGetsBack(String payer, String amount) => _t(
    '$payer qaytarib oladi: $amount (oʻz ulushisiz)',
    '$payer должны вернуть: $amount (без своей доли)',
  );
  String get noDebtCreated => _t(
    'Qarz paydo boʻlmaydi — toʻlovchi yagona ishtirokchi.',
    'Долга не возникает — участвует только плательщик.',
  );
  String get choosePayer =>
      _t('Kim toʻlaganini tanlang', 'Выберите, кто заплатил');
  String get chooseParticipants => _t(
    'Kamida bitta ishtirokchini tanlang',
    'Выберите хотя бы одного участника',
  );
  String billLink(String bill, String period) =>
      _t('«$bill» toʻlovi · $period', 'Оплата «$bill» · $period');
  String shoppingLink(int n) => _t(
    'Xarid roʻyxatidagi $n ta mahsulot bilan bogʻlanadi',
    'Связано с товарами из списка: $n',
  );
  String get expenseSaved => _t('Xarajat saqlandi', 'Расход сохранён');
  String get billAlreadyPaid => _t(
    'Bu davr uchun toʻlov allaqachon qayd etilgan',
    'Оплата за этот период уже записана',
  );
  String get expenseDetails => _t('Xarajat', 'Расход');
  String get whoOwesWhat => _t('Kim qancha', 'Кто сколько');
  String owesTo(String amount, String payer) =>
      _t('$amount qaytaradi → $payer', 'вернёт $amount → $payer');
  String get payerOwnShare => _t('oʻz ulushi', 'своя доля');
  String get deleteExpenseTitle =>
      _t('Xarajatni oʻchirasizmi?', 'Удалить расход?');
  String get deleteExpenseBody =>
      _t('Balanslar qayta hisoblanadi.', 'Балансы будут пересчитаны.');
  String deleteBillExpenseBody(String bill) => _t(
    'Bu «$bill» toʻlovi. Oʻchirilsa, shu davr yana toʻlanmagan boʻlib qoladi.',
    'Это оплата «$bill». После удаления период снова станет неоплаченным.',
  );
  String get linkedBill =>
      _t('Bogʻlangan uy toʻlovi', 'Связанный платёж по дому');
  String get linkedItems => _t('Xarid roʻyxatidan', 'Из списка покупок');
  String addedBy(String name, String when) =>
      _t('$name qoʻshgan · $when', 'Добавил(а) $name · $when');

  String get recordPaymentNote => _t(
    'Bu faqat yozuv: pulni naqd yoki kartaga oʻzingiz berasiz, Birga esa uni balansda hisobga oladi.',
    'Это только запись: деньги вы передаёте сами (наличными или на карту), а Birga учитывает это в балансе.',
  );
  String get paymentFrom => _t('Kim berdi?', 'Кто отдал?');
  String get paymentTo => _t('Kimga?', 'Кому?');
  String get paymentMethodLabel => _t('Usul', 'Способ');
  String get samePerson =>
      _t('Ikki xil odamni tanlang', 'Выберите двух разных людей');
  String get paymentRecorded => _t('Toʻlov qayd etildi', 'Платёж записан');
  String get deletePaymentTitle =>
      _t('Toʻlov yozuvini oʻchirasizmi?', 'Удалить запись о платеже?');
  String get deletePaymentBody =>
      _t('Balanslar qayta hisoblanadi.', 'Балансы будут пересчитаны.');

  String get choresTitle => _t('Navbatchilik', 'Дежурства');
  String get tabCurrent => _t('Joriy', 'Текущие');
  String get tabSchedule => _t('Jadval', 'График');
  String get doneThisWeek => _t('Bu hafta bajarildi', 'Сделано за неделю');
  String get pending => _t('Kutilmoqda', 'Ожидают');
  String get overdue => _t('Muddati oʻtgan', 'Просрочено');
  String get today => _t('Bugun', 'Сегодня');
  String get upcoming => _t('Keyingi kunlar', 'Предстоящие');
  String get onlyMine => _t('Faqat meniki', 'Только мои');
  String get noPendingChores =>
      _t('Ochiq navbatchilik yoʻq', 'Открытых дежурств нет');
  String get noPendingChoresHint => _t(
    'Navbatchilik qoʻshing — Birga uni xonadoshlar oʻrtasida adolatli aylantiradi.',
    'Добавьте дежурство — Birga честно распределит его по очереди.',
  );
  String get addChore => _t('Navbatchilik qoʻshish', 'Добавить дежурство');
  String get markDone => _t('Bajarildi', 'Выполнено');
  String get reassign => _t('Boshqasiga berish', 'Передать другому');
  String get swap => _t('Almashish', 'Поменяться');
  String get skip => _t('Oʻtkazib yuborish', 'Пропустить');
  String get aboutChore => _t('Navbatchilik haqida', 'О дежурстве');
  String choreDone(String title) =>
      _t('«$title» bajarildi', '«$title» — выполнено');
  String nextTurn(String name, String when) =>
      _t('Keyingi navbat: $name, $when', 'Следующий: $name, $when');
  String get skipTitle =>
      _t('Nega oʻtkazib yuborilmoqda?', 'Почему пропускаем?');
  String get skipReason => _t('Sabab', 'Причина');
  String get skipReasonHint =>
      _t('Masalan: uyda yoʻq edi', 'Например: не было дома');
  String get skipNote => _t(
    'Oʻtkazilgan navbat hech kimga hisoblanmaydi — bu odam keyingi safar ham navbatda birinchi boʻladi.',
    'Пропуск никому не засчитывается — этот человек останется первым в очереди.',
  );
  String get reassignTitle => _t('Kimga berasiz?', 'Кому передать?');
  String get reassignNote => _t(
    'Bu bajarish emas: faqat masʼul odam oʻzgaradi. Tarixda saqlanadi.',
    'Это не выполнение: меняется только ответственный. Сохраняется в истории.',
  );
  String get swapTitle => _t(
    'Qaysi navbatchilik bilan almashasiz?',
    'На какое дежурство поменяться?',
  );
  String get swapNote => _t(
    'Ikkala navbatchilikning masʼullari almashadi va tarixda qayd etiladi.',
    'Ответственные за оба дежурства меняются местами, это записывается в историю.',
  );
  String get noSwapCandidates => _t(
    'Boshqa xonadoshlarda almashish uchun ochiq navbatchilik yoʻq',
    'У других соседей нет открытых дежурств для обмена',
  );
  String get swapped =>
      _t('Navbatchiliklar almashtirildi', 'Дежурства поменяны');
  String get reassigned => _t('Navbatchilik topshirildi', 'Дежурство передано');
  String get skipped => _t('Oʻtkazib yuborildi', 'Пропущено');
  String get statusPending => _t('Kutilmoqda', 'Ожидает');
  String get statusDone => _t('Bajarildi', 'Выполнено');
  String get statusSkipped => _t('Oʻtkazildi', 'Пропущено');
  String get swappedBadge => _t('Almashilgan', 'Обмен');
  String get reassignedBadge => _t('Topshirilgan', 'Передано');
  String originally(String name) => _t('Avval: $name', 'Изначально: $name');
  String get workloadTitle =>
      _t('Bu hafta ishlar taqsimoti', 'Распределение дел на неделе');
  String get workloadNote => _t(
    'Bu reyting emas — kim qancha ish olganini koʻrish uchun.',
    'Это не рейтинг — просто видно, как распределены дела.',
  );
  String get colAssigned => _t('Belgilangan', 'Назначено');
  String get colDone => _t('Bajarildi', 'Сделано');
  String get colOpen => _t('Ochiq', 'Открыто');
  String get recurringChores => _t('Barcha navbatchiliklar', 'Все дежурства');
  String nextUp(String name, String when) =>
      _t('Navbatda: $name · $when', 'Очередь: $name · $when');
  String get nobodyEligible =>
      _t('Navbatda hech kim yoʻq', 'В очереди никого нет');
  String get noHistory => _t('Hali tarix yoʻq', 'Истории пока нет');
  String doneOn(String when) => _t('Bajarildi: $when', 'Выполнено: $when');
  String skippedBecause(String reason) =>
      _t('Sabab: $reason', 'Причина: $reason');
  String dueOn(String when) => _t('Muddat: $when', 'Срок: $when');

  String frequency(ChoreFrequency f) => switch (f) {
    ChoreFrequency.once => _t('Bir martalik', 'Разово'),
    ChoreFrequency.daily => _t('Har kuni', 'Каждый день'),
    ChoreFrequency.everyOtherDay => _t('Kunora', 'Через день'),
    ChoreFrequency.weekly => _t('Har hafta', 'Каждую неделю'),
    ChoreFrequency.biweekly => _t('Ikki haftada bir', 'Раз в две недели'),
    ChoreFrequency.monthly => _t('Har oy', 'Каждый месяц'),
  };

  String get currentTurn => _t('Joriy navbat', 'Текущая очередь');
  String get noCurrentTurn =>
      _t('Hozir ochiq navbat yoʻq', 'Сейчас нет открытой очереди');
  String get forecast =>
      _t('Keyingi navbatlar (taxminiy)', 'Следующие очереди (прогноз)');
  String get forecastNote => _t(
    'Hamma oʻz vaqtida bajarsa, shunday boʻladi.',
    'Если все будут выполнять вовремя.',
  );
  String get howChosen =>
      _t('Navbat qanday tanlanadi', 'Как выбирается очередь');
  List<String> get rotationRules => [
    _t(
      '1. Oxirgi 2 aylanmada bu ishni eng kam qilgan odam.',
      '1. Тот, кто реже всех делал это за последние 2 круга.',
    ),
    _t(
      '2. Teng boʻlsa — kim buni eng uzoq vaqt oldin qilgan.',
      '2. При равенстве — кто делал это давнее всех.',
    ),
    _t(
      '3. Yana teng boʻlsa — hozir kimda ochiq ishlar kamroq.',
      '3. Если снова поровну — у кого меньше открытых дел.',
    ),
    _t('4. Oxirida — roʻyxatdagi tartib.', '4. В конце — порядок в списке.'),
  ];
  String get colRecentTurns => _t('2 aylanmada', 'За 2 круга');
  String get colLastTurn => _t('Oxirgi marta', 'Последний раз');
  String get colOpenTasks => _t('Ochiq ishlar', 'Открытых дел');
  String get never => _t('hali yoʻq', 'ещё не было');
  String get rankingNote => _t(
    'Jadvalda joriy navbat bajarilgan deb olingan — shunda keyingi odam koʻrinadi.',
    'В таблице текущая очередь считается выполненной — так видно, кто следующий.',
  );
  String get nextByRules =>
      _t('Qoidaga koʻra keyingi', 'Следующий по правилам');
  String get choreHistory => _t('Tarix', 'История');
  String get archive => _t('Arxivlash', 'В архив');
  String get archiveChoreTitle =>
      _t('Navbatchilikni arxivlaysizmi?', 'Отправить дежурство в архив?');
  String get archiveChoreBody => _t(
    'Ochiq navbat oʻchiriladi, bajarilganlar tarixi saqlanadi.',
    'Открытая очередь удалится, история выполнений сохранится.',
  );
  String get frequencyLabel => _t('Qanchalik tez-tez?', 'Как часто?');
  String get newChore => _t('Yangi navbatchilik', 'Новое дежурство');
  String get editChore => _t('Navbatchilikni tahrirlash', 'Изменить дежурство');
  String get choreTitleLabel => _t('Nima qilish kerak?', 'Что нужно сделать?');
  String get choreTitleHint =>
      _t('Masalan: idish yuvish', 'Например: помыть посуду');
  String get quickPick => _t('Tez tanlash', 'Быстрый выбор');
  List<String> get commonChores => [
    _t('Idish yuvish', 'Мытьё посуды'),
    _t('Axlatni chiqarish', 'Вынести мусор'),
    _t('Polni supurish va yuvish', 'Подмести и помыть пол'),
    _t('Hammomni tozalash', 'Уборка ванной'),
    _t('Oshxonani tozalash', 'Уборка кухни'),
    _t('Ichimlik suvi olib kelish', 'Привезти питьевую воду'),
    _t('Uy anjomlarini toʻldirish', 'Пополнить хозтовары'),
    _t('Muzlatgichni tozalash', 'Помыть холодильник'),
    _t(
      'Oʻqish burchagini tartibga keltirish',
      'Навести порядок в учебном уголке',
    ),
  ];
  String get eligibleLabel =>
      _t('Kimlar navbatda turadi?', 'Кто участвует в очереди?');
  String get eligibleError =>
      _t('Kamida bitta xonadoshni tanlang', 'Выберите хотя бы одного соседа');
  String get firstDueLabel => _t('Birinchi muddat', 'Первый срок');
  String get firstAssigneeLabel => _t('Birinchi navbat kimda?', 'Кто первый?');
  String autoAssign(String name) =>
      _t('Avtomatik: $name', 'Автоматически: $name');
  String get pastDateError => _t(
    'Oʻtib ketgan sanani tanlab boʻlmaydi',
    'Нельзя выбрать прошедшую дату',
  );
  String get choreSaved => _t('Navbatchilik saqlandi', 'Дежурство сохранено');
  String get ineligibleAssigneeNote => _t(
    'Joriy masʼul endi roʻyxatda yoʻq — kerak boʻlsa, navbatni boshqasiga bering.',
    'Текущего ответственного больше нет в списке — при необходимости передайте очередь.',
  );

  String get plannerTitle => _t('Reja', 'Планер');
  String get viewToday => _t('Bugun', 'Сегодня');
  String get viewUpcoming => _t('Kelgusi', 'Скоро');
  String get viewAll => _t('Hammasi', 'Все');
  String get viewCompleted => _t('Bajarilgan', 'Выполнено');
  String get classSchedule => _t('Dars jadvali', 'Расписание');
  String get filterByCategory => _t('Toifa boʻyicha', 'По категориям');
  String get personal => _t('Shaxsiy', 'Личное');
  String get shared => _t('Umumiy', 'Общее');
  String get plannerPrivacyNote => _t(
    'Shaxsiy rejalaringizni faqat siz koʻrasiz. «Umumiy» belgisi borlari butun xonadonga tegishli.',
    'Личные записи видите только вы. Пункты с пометкой «Общее» касаются всей квартиры.',
  );
  String get householdToday => _t('Uy boʻyicha', 'По дому');
  String get emptyToday =>
      _t('Bugun rejada hech narsa yoʻq', 'На сегодня ничего не запланировано');
  String get emptyUpcoming =>
      _t('Kelgusi muddatlar yoʻq', 'Предстоящих дедлайнов нет');
  String get emptyCompleted =>
      _t('Hali bajarilgan vazifalar yoʻq', 'Выполненных задач пока нет');
  String get emptyAll => _t('Reja boʻsh', 'Планер пуст');
  String get emptyPlannerHint => _t(
    'Topshiriq, imtihon yoki dars qoʻshing.',
    'Добавьте задание, экзамен или занятие.',
  );
  String get taskCompleted =>
      _t('Bajarildi deb belgilandi', 'Отмечено как выполненное');
  String get taskReopened => _t('Yana faol', 'Снова активно');
  String get weekly => _t('Har hafta', 'Каждую неделю');
  String get householdEvent => _t('Uy tadbiri', 'Событие дома');
  String get choreItem => _t('Navbatchilik', 'Дежурство');

  String plannerCategory(PlannerCategory c) => switch (c) {
    PlannerCategory.assignment => _t('Topshiriq', 'Задание'),
    PlannerCategory.homework => _t('Uy vazifasi', 'Домашнее задание'),
    PlannerCategory.exam => _t('Imtihon', 'Экзамен'),
    PlannerCategory.project => _t('Loyiha', 'Проект'),
    PlannerCategory.classSession => _t('Dars', 'Занятие'),
    PlannerCategory.study => _t('Mustaqil oʻqish', 'Самоподготовка'),
    PlannerCategory.personalTask => _t('Shaxsiy ish', 'Личное дело'),
    PlannerCategory.event => _t('Tadbir', 'Событие'),
  };

  String get addTaskLabel => _t('Yozuv qoʻshish', 'Добавить запись');
  String get newPlannerItem => _t('Yangi yozuv', 'Новая запись');
  String get editPlannerItem => _t('Yozuvni tahrirlash', 'Изменить запись');
  String get titleLabel => _t('Nomi', 'Название');
  String get descriptionOptional =>
      _t('Tavsif (ixtiyoriy)', 'Описание (необязательно)');
  String get courseOptional => _t('Fan (ixtiyoriy)', 'Предмет (необязательно)');
  String get dueDate => _t('Muddat', 'Срок');
  String get startLabel => _t('Boshlanishi', 'Начало');
  String get endOptional =>
      _t('Tugashi (ixtiyoriy)', 'Окончание (необязательно)');
  String get endBeforeStart => _t(
    'Tugash vaqti boshlanishidan keyin boʻlsin',
    'Окончание должно быть позже начала',
  );
  String get repeatWeekly =>
      _t('Har hafta takrorlanadi', 'Повторять каждую неделю');
  String get repeatWeeklyHint =>
      _t('Dars jadvali uchun qulay', 'Удобно для расписания занятий');
  String get onlyYouSee =>
      _t('Bu yozuvni faqat siz koʻrasiz.', 'Эту запись видите только вы.');
  String get pastDueHint => _t(
    'Bu vaqt oʻtib ketgan — yozuv muddati oʻtgan deb koʻrsatiladi.',
    'Это время уже прошло — запись будет показана как просроченная.',
  );
  String get deletePlannerTitle =>
      _t('Yozuvni oʻchirasizmi?', 'Удалить запись?');
  String get noClassesThisDay =>
      _t('Bu kunda dars yoʻq', 'В этот день занятий нет');
  String get scheduleHint => _t(
    'Dars qoʻshish uchun «Har hafta takrorlanadi»ni yoqing.',
    'Чтобы добавить занятие, включите «Повторять каждую неделю».',
  );
  String get markComplete =>
      _t('Bajarildi deb belgilash', 'Отметить выполненным');
  String get markIncomplete =>
      _t('Bajarilmagan deb belgilash', 'Снять отметку');

  String get householdTitle => _t('Xonadon', 'Дом');
  String get shoppingTitle => _t('Xarid roʻyxati', 'Список покупок');
  String get billsTitle => _t('Uy toʻlovlari', 'Платежи по дому');
  String get calendarTitle => _t('Umumiy taqvim', 'Общий календарь');
  String get pollsTitle => _t('Soʻrovnomalar', 'Опросы');
  String get issuesTitle => _t('Nosozliklar', 'Поломки');
  String get rulesTitle => _t('Qoidalar va eʼlonlar', 'Правила и объявления');
  String membersCount(int n) => _t('$n kishi', '$n чел.');
  String get noUpcomingEvents =>
      _t('Yaqin tadbirlar yoʻq', 'Ближайших событий нет');
  String openPolls(int n) => n == 0
      ? _t('Ochiq soʻrovnoma yoʻq', 'Открытых опросов нет')
      : _t('$n ta ochiq', 'Открытых: $n');
  String openIssues(int n) => n == 0
      ? _t('Hammasi ishlayapti', 'Всё работает')
      : _t('$n ta hal qilinmagan', 'Не решено: $n');
  String rulesCount(int n) => _t('$n ta qoida', 'Правил: $n');

  String get addMember => _t('Xonadosh qoʻshish', 'Добавить соседа');
  String get editMember => _t('Xonadoshni tahrirlash', 'Изменить соседа');
  String get displayName => _t('Ism', 'Имя');
  String get color => _t('Rang', 'Цвет');
  String get joinRotations =>
      _t('Mavjud navbatchiliklarga qoʻshish', 'Добавить в текущие дежурства');
  String get movedOut => _t('Koʻchib ketgan', 'Выехал(а)');
  String get markMovedOut => _t('Koʻchib ketdi', 'Выехал(а)');
  String get moveOutTitle =>
      _t('Koʻchib ketdi deb belgilaysizmi?', 'Отметить, что сосед выехал?');
  String get moveOutBody => _t(
    'Uning ochiq navbatchiliklari boshqalarga taqsimlanadi. Xarajatlar tarixi va balansi saqlanadi.',
    'Открытые дежурства перераспределятся. История расходов и баланс сохранятся.',
  );
  String moveOutBalanceWarning(String amount) => _t(
    'Diqqat: balansi $amount. Avval hisob-kitob qiling.',
    'Внимание: баланс $amount. Сначала рассчитайтесь.',
  );
  String get markBack => _t('Qaytib keldi', 'Вернулся(лась)');
  String get currentProfile => _t('Hozirgi profil', 'Текущий профиль');
  String get syncTitle =>
      _t('Bir nechta telefon — hali yoʻq', 'Несколько телефонов — пока нет');
  String get syncBody => _t(
    'Hozir Birga bitta qurilmada ishlaydi: xonadoshlarni shu yerda qoʻshasiz va profilni almashtirib koʻrasiz. Har kim oʻz telefonidan qoʻshilishi uchun bulutli server va haqiqiy kirish kerak — bu keyingi bosqich.',
    'Сейчас Birga работает на одном устройстве: соседей вы добавляете здесь и переключаете профили. Чтобы каждый подключался со своего телефона, нужны облачный сервер и настоящий вход — это следующий этап.',
  );
  String get renameHousehold => _t('Nomini oʻzgartirish', 'Переименовать');

  String get toBuy => _t('Olinishi kerak', 'Нужно купить');
  String get purchased => _t('Olingan', 'Куплено');
  String get quickAdd => _t('Tez qoʻshish', 'Быстро добавить');
  String get addItem => _t('Mahsulot qoʻshish', 'Добавить товар');
  String get editItem => _t('Mahsulotni tahrirlash', 'Изменить товар');
  String get itemName => _t('Nomi', 'Название');
  String get quantityOptional =>
      _t('Miqdori (ixtiyoriy)', 'Количество (необязательно)');
  String get quantityHint => _t('Masalan: 2 kg, 3 ta', 'Например: 2 кг, 3 шт.');
  String get buyerOptional =>
      _t('Kim oladi? (ixtiyoriy)', 'Кто купит? (необязательно)');
  String willBuy(String name) => _t('$name oladi', 'Купит $name');
  String boughtBy(String name, String when) =>
      _t('$name oldi · $when', 'Купил(а) $name · $when');
  String get duplicateTitle =>
      _t('Roʻyxatda allaqachon bor', 'Уже есть в списке');
  String duplicateBody(String name, String qty) => _t(
    '«$name»${qty.isEmpty ? '' : ' ($qty)'} hali olinmagan. Miqdorini yangilaysizmi yoki alohida qoʻshasizmi?',
    '«$name»${qty.isEmpty ? '' : ' ($qty)'} ещё не куплено. Обновить количество или добавить отдельно?',
  );
  String get updateQuantity => _t('Miqdorni yangilash', 'Обновить количество');
  String get addSeparately => _t('Alohida qoʻshish', 'Добавить отдельно');
  String get recordAsExpense =>
      _t('Xarajat sifatida yozish', 'Записать как расход');
  String unrecordedPurchases(int n) => _t(
    '$n ta olingan mahsulot hali xarajatga yozilmagan',
    'Купленных товаров без записи в расходах: $n',
  );
  String get inExpenses => _t('Xarajatga yozilgan', 'Записано в расходы');
  String get restore => _t('Qaytarish', 'Вернуть');
  String get restoreLinkedNote => _t(
    'Mahsulot xarajatdan ajratiladi, lekin xarajat summasi oʻzgarmaydi.',
    'Товар будет отвязан от расхода, но сумма расхода не изменится.',
  );
  String get clearPurchased =>
      _t('Olinganlarni tozalash', 'Очистить купленное');
  String get clearPurchasedBody => _t(
    'Olingan mahsulotlar roʻyxatdan oʻchiriladi. Xarajatlar oʻzgarmaydi.',
    'Купленные товары удалятся из списка. Расходы не изменятся.',
  );
  String get emptyList => _t('Roʻyxat boʻsh', 'Список пуст');
  String get emptyListHint => _t(
    'Nima tugaganini qoʻshing — doʻkonga kim borsa, koʻradi.',
    'Добавьте, что закончилось, — кто пойдёт в магазин, увидит.',
  );
  String get selectItems => _t('Qaysi mahsulotlar?', 'Какие товары?');
  String groceriesTitle(String names) => _t('Xarid: $names', 'Покупки: $names');
  String addedToList(String name) =>
      _t('«$name» roʻyxatga qoʻshildi', '«$name» добавлено в список');
  String get quantityUpdated => _t('Miqdor yangilandi', 'Количество обновлено');
  String get unassigned => _t('Belgilanmagan', 'Не назначено');

  String shoppingCategory(ShoppingCategory c) => switch (c) {
    ShoppingCategory.food => _t('Oziq-ovqat', 'Продукты'),
    ShoppingCategory.drinks => _t('Ichimliklar', 'Напитки'),
    ShoppingCategory.cleaning => _t('Tozalash vositalari', 'Бытовая химия'),
    ShoppingCategory.hygiene => _t('Gigiyena', 'Гигиена'),
    ShoppingCategory.household => _t('Uy-roʻzgʻor', 'Для дома'),
    ShoppingCategory.other => _t('Boshqa', 'Другое'),
  };

  List<(String, ShoppingCategory)> get commonItems => [
    (_t('Non', 'Хлеб'), ShoppingCategory.food),
    (_t('Tuxum', 'Яйца'), ShoppingCategory.food),
    (_t('Sut', 'Молоко'), ShoppingCategory.food),
    (_t('Guruch', 'Рис'), ShoppingCategory.food),
    (_t('Kungaboqar yogʻi', 'Подсолнечное масло'), ShoppingCategory.food),
    (_t('Shakar', 'Сахар'), ShoppingCategory.food),
    (_t('Choy', 'Чай'), ShoppingCategory.drinks),
    (_t('Ichimlik suvi', 'Питьевая вода'), ShoppingCategory.drinks),
    (
      _t('Idish yuvish vositasi', 'Средство для посуды'),
      ShoppingCategory.cleaning,
    ),
    (_t('Kir yuvish kukuni', 'Стиральный порошок'), ShoppingCategory.cleaning),
    (_t('Hojatxona qogʻozi', 'Туалетная бумага'), ShoppingCategory.hygiene),
    (_t('Axlat paketlari', 'Мусорные пакеты'), ShoppingCategory.household),
  ];

  String get expectedThisMonth =>
      _t('Shu oy kutilmoqda', 'Ожидается в этом месяце');
  String get paidThisMonth => _t('Shu oy toʻlangan', 'Оплачено в этом месяце');
  String billStatus(BillStatus s) => switch (s) {
    BillStatus.overdue => _t('Muddati oʻtgan', 'Просрочено'),
    BillStatus.dueSoon => _t('Yaqinda', 'Скоро'),
    BillStatus.upcoming => _t('Kutilmoqda', 'Ожидается'),
    BillStatus.settled => _t('Toʻlangan', 'Оплачено'),
  };
  String responsible(String name) =>
      _t('Masʼul: $name', 'Ответственный: $name');
  String get markPaid => _t('Toʻlandi deb belgilash', 'Отметить оплату');
  String get markPaidNote => _t(
    'Toʻlov xarajat sifatida yoziladi, shuning uchun ikki marta hisoblanmaydi. Bu bank oʻtkazmasining isboti emas — siz yuritadigan yozuv.',
    'Оплата записывается как расход, поэтому не считается дважды. Это не подтверждение банковского перевода — это ваша запись.',
  );
  String get paymentHistory => _t('Toʻlovlar tarixi', 'История оплат');
  String get noPayments => _t('Hali toʻlovlar yoʻq', 'Оплат пока нет');
  String get addBill => _t('Toʻlov qoʻshish', 'Добавить платёж');
  String get newBill => _t('Yangi uy toʻlovi', 'Новый платёж по дому');
  String get editBill => _t('Toʻlovni tahrirlash', 'Изменить платёж');
  String get billType => _t('Turi', 'Тип');
  String get expectedAmount => _t('Kutilayotgan summa', 'Ожидаемая сумма');
  String get billDueLabel => _t('Toʻlov muddati', 'Срок оплаты');
  String get billFrequencyLabel => _t('Davriylik', 'Периодичность');
  String get whoPays => _t('Kim toʻlaydi?', 'Кто оплачивает?');
  String get whoSplits => _t('Kimlar boʻlishadi?', 'Кто делит?');
  String get archiveBill => _t('Toʻlovni arxivlash', 'Архивировать платёж');
  String get archiveBillBody => _t(
    'Kelgusi muddatlar koʻrsatilmaydi. Avvalgi toʻlovlar xarajatlarda qoladi.',
    'Будущие сроки не будут показываться. Прошлые оплаты останутся в расходах.',
  );
  String periodOf(String when) => _t('$when davri', 'период: $when');
  String get emptyBills =>
      _t('Hali toʻlovlar qoʻshilmagan', 'Платежей пока нет');
  String get emptyBillsHint => _t(
    'Ijara, internet, elektr kabi doimiy toʻlovlarni qoʻshing.',
    'Добавьте регулярные платежи: аренду, интернет, электричество.',
  );
  String get allBillsPaid => _t('Hammasi toʻlangan', 'Всё оплачено');
  String get billSaved => _t('Toʻlov saqlandi', 'Платёж сохранён');
  String get billAnchorLocked => _t(
    'Toʻlovlar qayd etilgan — muddat va davriylikni oʻzgartirib boʻlmaydi.',
    'Оплаты уже записаны — срок и периодичность изменить нельзя.',
  );
  String get customSharesForBill =>
      _t('Har bir kishining ulushi', 'Доля каждого');

  String billFrequency(BillFrequency f) => switch (f) {
    BillFrequency.once => _t('Bir martalik', 'Разовый'),
    BillFrequency.monthly => _t('Har oy', 'Каждый месяц'),
    BillFrequency.quarterly => _t('Har 3 oyda', 'Раз в 3 месяца'),
  };

  String billTypeLabel(BillType t) => switch (t) {
    BillType.rent => _t('Ijara', 'Аренда'),
    BillType.electricity => _t('Elektr', 'Электричество'),
    BillType.water => _t('Suv', 'Вода'),
    BillType.gas => _t('Gaz', 'Газ'),
    BillType.internet => _t('Internet', 'Интернет'),
    BillType.maintenance => _t('Uy xizmati', 'Обслуживание дома'),
    BillType.subscription => _t('Obuna', 'Подписка'),
    BillType.other => _t('Boshqa', 'Другое'),
  };

  String get showEvents => _t('Tadbirlar', 'События');
  String get showBills => _t('Toʻlovlar', 'Платежи');
  String get showChores => _t('Navbatchilik', 'Дежурства');
  String get addEvent => _t('Tadbir qoʻshish', 'Добавить событие');
  String get newEvent => _t('Yangi tadbir', 'Новое событие');
  String get editEvent => _t('Tadbirni tahrirlash', 'Изменить событие');
  String get eventTitle => _t('Nima boʻladi?', 'Что будет?');
  String get eventTypeLabel => _t('Turi', 'Тип');
  String get sharedEventNote =>
      _t('Tadbir butun xonadonga koʻrinadi.', 'Событие видно всей квартире.');
  String get emptyCalendar =>
      _t('Yaqin 30 kunda hech narsa yoʻq', 'В ближайшие 30 дней ничего нет');
  String billDueEntry(String name) =>
      _t('Toʻlov muddati: $name', 'Срок оплаты: $name');
  String get deleteEventTitle =>
      _t('Tadbirni oʻchirasizmi?', 'Удалить событие?');
  String get next30Days => _t('Keyingi 30 kun', 'Ближайшие 30 дней');

  String eventType(EventType t) => switch (t) {
    EventType.guests => _t('Mehmonlar', 'Гости'),
    EventType.maintenance => _t('Usta / taʼmir', 'Мастер / ремонт'),
    EventType.meeting => _t('Uy yigʻilishi', 'Собрание'),
    EventType.shopping => _t('Bozorlik', 'Закупка'),
    EventType.cleaning => _t('Tozalash', 'Уборка'),
    EventType.other => _t('Boshqa', 'Другое'),
  };

  String get openLabel => _t('Ochiq', 'Открытые');
  String get closedLabel => _t('Yopilgan', 'Закрытые');
  String get newPoll => _t('Yangi soʻrovnoma', 'Новый опрос');
  String get question => _t('Savol', 'Вопрос');
  String get pollOptions => _t('Javob variantlari', 'Варианты ответа');
  String optionN(int n) => _t('$n-variant', 'Вариант $n');
  String get addOption => _t('Variant qoʻshish', 'Добавить вариант');
  String get deadlineOptional =>
      _t('Muddat (ixtiyoriy)', 'Срок (необязательно)');
  String get noDeadline => _t('Muddatsiz', 'Без срока');
  String get oneVoteRule => _t(
    'Har bir xonadosh bitta ovoz beradi va soʻrovnoma yopilguncha uni oʻzgartira oladi.',
    'У каждого соседа один голос; его можно изменить, пока опрос открыт.',
  );
  String votes(int n) => _uz
      ? '$n ovoz'
      : '$n ${DateFormatter.ruPlural(n, 'голос', 'голоса', 'голосов')}';
  String votedCount(int count, int total) =>
      _t('$count/$total kishi ovoz berdi', 'Проголосовали: $count из $total');
  String get yourVote => _t('Sizning ovozingiz', 'Ваш голос');
  String get closePoll => _t('Soʻrovnomani yopish', 'Закрыть опрос');
  String get closePollBody => _t(
    'Yopilgandan keyin ovoz berib boʻlmaydi.',
    'После закрытия голосовать нельзя.',
  );
  String closedOn(String when) => _t('Yopilgan: $when', 'Закрыт: $when');
  String endsOn(String when) => _t('Tugaydi: $when', 'До: $when');
  String result(String text) => _t('Natija: $text', 'Итог: $text');
  String get tie => _t('Ovozlar teng', 'Голоса разделились поровну');
  String get noVotesYet => _t('Hali ovoz yoʻq', 'Голосов пока нет');
  String get needTwoOptions =>
      _t('Kamida 2 ta variant kiriting', 'Введите минимум 2 варианта');
  String get emptyPolls => _t('Soʻrovnomalar yoʻq', 'Опросов нет');
  String get emptyPollsHint => _t(
    'Umumiy qaror kerakmi? Soʻrovnoma oching — chatda yoʻqolib ketmaydi.',
    'Нужно общее решение? Создайте опрос — он не потеряется в чате.',
  );
  String get tapToVote => _t(
    'Ovoz berish uchun variantni tanlang',
    'Выберите вариант, чтобы проголосовать',
  );
  String get deletePollTitle =>
      _t('Soʻrovnomani oʻchirasizmi?', 'Удалить опрос?');
  String get voteSaved => _t('Ovozingiz saqlandi', 'Ваш голос учтён');

  String issueStatus(IssueStatus s) => switch (s) {
    IssueStatus.open => _t('Ochiq', 'Открыто'),
    IssueStatus.inProgress => _t('Jarayonda', 'В работе'),
    IssueStatus.resolved => _t('Hal qilindi', 'Решено'),
  };
  String issueCategory(IssueCategory c) => switch (c) {
    IssueCategory.plumbing => _t('Santexnika', 'Сантехника'),
    IssueCategory.electrical => _t('Elektr', 'Электрика'),
    IssueCategory.appliance => _t('Maishiy texnika', 'Бытовая техника'),
    IssueCategory.internet => _t('Internet', 'Интернет'),
    IssueCategory.furniture => _t('Mebel', 'Мебель'),
    IssueCategory.supplies => _t('Anjomlar', 'Расходники'),
    IssueCategory.other => _t('Boshqa', 'Другое'),
  };
  String get reportIssue => _t('Muammo haqida yozish', 'Сообщить о проблеме');
  String get newIssue => _t('Yangi muammo', 'Новая проблема');
  String get editIssue => _t('Muammoni tahrirlash', 'Изменить запись');
  String get issueTitle => _t('Nima boʻldi?', 'Что случилось?');
  String get issueTitleHint =>
      _t('Masalan: kran oqyapti', 'Например: течёт кран');
  String get assigneeOptional =>
      _t('Kim hal qiladi? (ixtiyoriy)', 'Кто займётся? (необязательно)');
  String reportedBy(String name, String when) =>
      _t('$name yozdi · $when', 'Сообщил(а) $name · $when');
  String get resolution => _t('Qanday hal qilindi', 'Как решили');
  String get resolutionHint => _t(
    'Masalan: usta chaqirildi, 80 000 soʻm',
    'Например: вызвали мастера, 80 000 сум',
  );
  String get startWork => _t('Ishga olish', 'Взять в работу');
  String get markResolved => _t('Hal qilindi', 'Решено');
  String get reopen => _t('Qayta ochish', 'Открыть снова');
  String resolvedOn(String when) => _t('Hal qilindi: $when', 'Решено: $when');
  String get photosLater => _t(
    'Rasm biriktirish keyingi versiyada boʻladi.',
    'Фото можно будет прикреплять в следующей версии.',
  );
  String get emptyIssues => _t('Muammo yoʻq', 'Проблем нет');
  String get emptyIssuesHint => _t(
    'Biror narsa buzilsa, shu yerga yozing va kim hal qilishini belgilang.',
    'Если что-то сломалось, запишите здесь и назначьте ответственного.',
  );
  String get deleteIssueTitle => _t('Yozuvni oʻchirasizmi?', 'Удалить запись?');
  String assignedTo(String name) => _t('Masʼul: $name', 'Занимается: $name');

  String get announcements => _t('Eʼlonlar', 'Объявления');
  String get houseRules => _t('Uy qoidalari', 'Правила дома');
  String get newAnnouncement => _t('Eʼlon yozish', 'Написать объявление');
  String get announcementHint => _t(
    'Masalan: shanba kuni katta tozalash',
    'Например: в субботу генеральная уборка',
  );
  String get pin => _t('Asosiy sahifaga qadash', 'Закрепить на главной');
  String get unpin => _t('Qadashni olib tashlash', 'Открепить');
  String get pinned => _t('Qadalgan', 'Закреплено');
  String get addRule => _t('Qoida qoʻshish', 'Добавить правило');
  String get editRule => _t('Qoidani tahrirlash', 'Изменить правило');
  String get ruleTitle => _t('Qoida', 'Правило');
  String get ruleDetails =>
      _t('Batafsil (ixtiyoriy)', 'Подробнее (необязательно)');
  String get emptyRules => _t('Qoidalar yoʻq', 'Правил нет');
  String get emptyRulesHint => _t(
    'Tinchlik soatlari, mehmonlar, tozalik — kelishilgan narsalarni yozib qoʻying.',
    'Тихие часы, гости, чистота — запишите, о чём договорились.',
  );
  String get emptyAnnouncements => _t('Eʼlonlar yoʻq', 'Объявлений нет');
  String get notAChat => _t(
    'Bu chat emas — faqat muhim xabarlar uchun.',
    'Это не чат — только для важного.',
  );
  String postedBy(String name, String when) =>
      _t('$name · $when', '$name · $when');
  String get deleteRuleTitle => _t('Qoidani oʻchirasizmi?', 'Удалить правило?');
  String get deleteAnnouncementTitle =>
      _t('Eʼlonni oʻchirasizmi?', 'Удалить объявление?');

  String get languageLabel => _t('Til', 'Язык');
  String get theme => _t('Mavzu', 'Тема');
  String get themeSystem => _t('Tizim boʻyicha', 'Как в системе');
  String get themeLight => _t('Yorugʻ', 'Светлая');
  String get themeDark => _t('Qorongʻi', 'Тёмная');
  String get profile => _t('Profil', 'Профиль');
  String get dataSection => _t('Maʼlumotlar', 'Данные');
  String get storageInfo => _t(
    'Barcha maʼlumotlar faqat shu qurilmada saqlanadi. Internetga hech narsa yuborilmaydi.',
    'Все данные хранятся только на этом устройстве. Ничего не отправляется в интернет.',
  );
  String get resetDemo =>
      _t('Demo maʼlumotlarni qayta tiklash', 'Сбросить демо-данные');
  String get resetDemoBody => _t(
    'Hozirgi barcha maʼlumotlar oʻchiriladi va demo xonadon qaytadan yaratiladi. Buni qaytarib boʻlmaydi.',
    'Все текущие данные будут удалены, демо-квартира создастся заново. Отменить нельзя.',
  );
  String get startOver =>
      _t('Yangi xonadon boshlash', 'Начать с новой квартиры');
  String get startOverBody => _t(
    'Hozirgi xonadonning barcha maʼlumotlari oʻchiriladi. Buni qaytarib boʻlmaydi.',
    'Все данные текущей квартиры будут удалены. Отменить нельзя.',
  );
  String get reset => _t('Tiklash', 'Сбросить');
  String get erase => _t('Oʻchirish', 'Удалить');
  String get about => _t('Ilova haqida', 'О приложении');
  String get aboutText => _t(
    'Birga — talabalar uchun prototip (kurs loyihasi). Bulutli sinxronlash, haqiqiy kirish, bildirishnomalar va toʻlovlar hali yoʻq.',
    'Birga — прототип для студентов (курсовой проект). Облачной синхронизации, настоящего входа, уведомлений и платежей пока нет.',
  );
  String get saveFailed => _t(
    'Oxirgi oʻzgarishni saqlab boʻlmadi. Qurilma xotirasini tekshiring.',
    'Не удалось сохранить последнее изменение. Проверьте память устройства.',
  );
  String get demoDataLabel => _t('Demo maʼlumotlar', 'Демо-данные');
}

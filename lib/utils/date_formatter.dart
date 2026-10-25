import '../l10n/app_language.dart';
import 'date_math.dart';

class DateFormatter {
  const DateFormatter(this.language);

  final AppLanguage language;

  bool get _uz => language == AppLanguage.uz;

  static const _uzMonths = [
    'yanvar',
    'fevral',
    'mart',
    'aprel',
    'may',
    'iyun',
    'iyul',
    'avgust',
    'sentabr',
    'oktabr',
    'noyabr',
    'dekabr',
  ];
  static const _ruMonthsGenitive = [
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];
  static const _ruMonths = [
    'Январь',
    'Февраль',
    'Март',
    'Апрель',
    'Май',
    'Июнь',
    'Июль',
    'Август',
    'Сентябрь',
    'Октябрь',
    'Ноябрь',
    'Декабрь',
  ];
  static const _uzWeekdays = [
    'dushanba',
    'seshanba',
    'chorshanba',
    'payshanba',
    'juma',
    'shanba',
    'yakshanba',
  ];
  static const _ruWeekdays = [
    'понедельник',
    'вторник',
    'среда',
    'четверг',
    'пятница',
    'суббота',
    'воскресенье',
  ];
  static const _uzWeekdaysShort = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];
  static const _ruWeekdaysShort = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  String day(DateTime d, {DateTime? now}) {
    final showYear = now != null && now.year != d.year;
    if (_uz) {
      final base = '${d.day}-${_uzMonths[d.month - 1]}';
      return showYear ? '$base, ${d.year}' : base;
    }
    final base = '${d.day} ${_ruMonthsGenitive[d.month - 1]}';
    return showYear ? '$base ${d.year}' : base;
  }

  String weekday(DateTime d) => _capitalize(
    _uz ? _uzWeekdays[d.weekday - 1] : _ruWeekdays[d.weekday - 1],
  );

  String weekdayShort(int weekday) =>
      _uz ? _uzWeekdaysShort[weekday - 1] : _ruWeekdaysShort[weekday - 1];

  String weekdayName(int weekday) =>
      _capitalize(_uz ? _uzWeekdays[weekday - 1] : _ruWeekdays[weekday - 1]);

  String dayWithWeekday(DateTime d, {DateTime? now}) =>
      '${weekday(d)}, ${day(d, now: now)}';

  String time(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  String dayAndTime(DateTime d, {DateTime? now}) =>
      '${day(d, now: now)}, ${time(d)}';

  String monthYear(DateTime d) => _uz
      ? '${_capitalize(_uzMonths[d.month - 1])} ${d.year}'
      : '${_ruMonths[d.month - 1]} ${d.year}';

  String monthName(DateTime d) =>
      _uz ? _capitalize(_uzMonths[d.month - 1]) : _ruMonths[d.month - 1];

  String relativeDay(DateTime date, DateTime today) {
    final diff = daysBetween(today, date);
    if (diff == 0) return _uz ? 'bugun' : 'сегодня';
    if (diff == 1) return _uz ? 'ertaga' : 'завтра';
    if (diff == -1) return _uz ? 'kecha' : 'вчера';
    if (diff > 1 && diff <= 14) {
      return _uz ? '$diff kundan keyin' : 'через $diff ${ruDays(diff)}';
    }
    if (diff < -1 && diff >= -14) {
      final n = -diff;
      return _uz ? '$n kun oldin' : '$n ${ruDays(n)} назад';
    }
    return day(date, now: today);
  }

  String relativeDayCapitalized(DateTime date, DateTime today) =>
      _capitalize(relativeDay(date, today));

  static String ruPlural(int n, String one, String few, String many) {
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod10 == 1 && mod100 != 11) return one;
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return few;
    return many;
  }

  static String ruDays(int n) => ruPlural(n, 'день', 'дня', 'дней');

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

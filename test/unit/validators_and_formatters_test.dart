import 'package:birga/l10n/app_language.dart';
import 'package:birga/utils/currency_formatter.dart';
import 'package:birga/utils/date_formatter.dart';
import 'package:birga/utils/date_math.dart';
import 'package:birga/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('amount input', () {
    test('parses grouped and plain digits', () {
      expect(parseAmount('120 000'), 120000);
      expect(parseAmount('120 000'), 120000);
      expect(parseAmount('45000'), 45000);
      expect(parseAmount(' 7 '), 7);
    });

    test('rejects decimals, letters and signs', () {
      expect(parseAmount('12.5'), isNull);
      expect(parseAmount('12,000'), isNull);
      expect(parseAmount('abc'), isNull);
      expect(parseAmount('-500'), isNull);
      expect(parseAmount(''), isNull);
    });

    test('validation explains what is wrong', () {
      expect(validateAmount(''), AmountError.empty);
      expect(validateAmount('   '), AmountError.empty);
      expect(validateAmount('1O0'), AmountError.invalid);
      expect(validateAmount('0'), AmountError.notPositive);
      expect(validateAmount('1 000 000 001'), AmountError.tooLarge);
      expect(validateAmount('120 000'), isNull);
    });
  });

  test('required text validation', () {
    expect(validateRequiredText(null), TextError.empty);
    expect(validateRequiredText('   '), TextError.empty);
    expect(validateRequiredText('x' * 81), TextError.tooLong);
    expect(validateRequiredText('Non'), isNull);
  });

  test('names are normalized for duplicate detection', () {
    expect(normalizeName('  Ichimlik   SUVI '), 'ichimlik suvi');
  });

  group('currency', () {
    test('groups thousands with non-breaking spaces', () {
      expect(groupDigits(0), '0');
      expect(groupDigits(999), '999');
      expect(groupDigits(1000), '1 000');
      expect(groupDigits(6000000), '6 000 000');
      expect(groupDigits(-30000), '−30 000');
    });

    test('adds the currency name per language', () {
      expect(formatUzs(120000, AppLanguage.uz), '120 000 soʻm');
      expect(formatUzs(120000, AppLanguage.ru), '120 000 сум');
      expect(formatUzs(500, AppLanguage.uz, showPlus: true), '+500 soʻm');
    });
  });

  group('dates', () {
    const uz = DateFormatter(AppLanguage.uz);
    const ru = DateFormatter(AppLanguage.ru);
    final today = DateTime(2026, 10, 22);

    test('formats days in Uzbek and Russian', () {
      expect(uz.day(DateTime(2026, 10, 25)), '25-oktabr');
      expect(ru.day(DateTime(2026, 10, 25)), '25 октября');
      expect(uz.day(DateTime(2025, 1, 2), now: today), '2-yanvar, 2025');
      expect(uz.dayWithWeekday(today), 'Payshanba, 22-oktabr');
      expect(ru.time(DateTime(2026, 1, 1, 9, 5)), '09:05');
    });

    test('relative days', () {
      expect(uz.relativeDay(today, today), 'bugun');
      expect(uz.relativeDay(DateTime(2026, 10, 25), today), '3 kundan keyin');
      expect(ru.relativeDay(DateTime(2026, 10, 25), today), 'через 3 дня');
      expect(ru.relativeDay(DateTime(2026, 10, 27), today), 'через 5 дней');
      expect(uz.relativeDay(DateTime(2026, 10, 20), today), '2 kun oldin');
      expect(ru.relativeDay(DateTime(2026, 10, 21), today), 'вчера');
    });

    test('Russian plural rules', () {
      expect(DateFormatter.ruDays(1), 'день');
      expect(DateFormatter.ruDays(4), 'дня');
      expect(DateFormatter.ruDays(11), 'дней');
      expect(DateFormatter.ruDays(21), 'день');
      expect(DateFormatter.ruDays(22), 'дня');
    });

    test('month arithmetic clamps to month end and handles year change', () {
      expect(addMonths(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
      expect(addMonths(DateTime(2026, 11, 15), 3), DateTime(2027, 2, 15));
      expect(addMonths(DateTime(2026, 1, 15), -1), DateTime(2025, 12, 15));
      expect(
        daysBetween(DateTime(2026, 10, 22, 23), DateTime(2026, 10, 23, 1)),
        1,
      );
      expect(startOfWeek(today), DateTime(2026, 10, 19));
    });
  });
}

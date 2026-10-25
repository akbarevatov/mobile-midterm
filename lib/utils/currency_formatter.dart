import '../l10n/app_language.dart';

const String _nbsp = ' ';

String groupDigits(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(_nbsp);
    buffer.write(digits[i]);
  }
  return value < 0 ? '−$buffer' : buffer.toString();
}

String currencyName(AppLanguage language) =>
    language == AppLanguage.uz ? 'soʻm' : 'сум';

String formatUzs(int amount, AppLanguage language, {bool showPlus = false}) {
  final sign = showPlus && amount > 0 ? '+' : '';
  return '$sign${groupDigits(amount)}$_nbsp${currencyName(language)}';
}

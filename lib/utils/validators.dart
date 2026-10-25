const int maxAmountUzs = 1000000000;

enum AmountError { empty, invalid, notPositive, tooLarge }

enum TextError { empty, tooLong }

final RegExp _whitespace = RegExp(r'[\s  ]');
final RegExp _digitsOnly = RegExp(r'^\d+$');

int? parseAmount(String? text) {
  if (text == null) return null;
  final cleaned = text.replaceAll(_whitespace, '');
  if (cleaned.isEmpty || !_digitsOnly.hasMatch(cleaned)) return null;
  if (cleaned.length > 12) return null;
  return int.parse(cleaned);
}

AmountError? validateAmount(String? text) {
  final cleaned = (text ?? '').replaceAll(_whitespace, '');
  if (cleaned.isEmpty) return AmountError.empty;
  final value = parseAmount(cleaned);
  if (value == null) return AmountError.invalid;
  if (value <= 0) return AmountError.notPositive;
  if (value > maxAmountUzs) return AmountError.tooLarge;
  return null;
}

TextError? validateRequiredText(String? text, {int maxLength = 80}) {
  final trimmed = (text ?? '').trim();
  if (trimmed.isEmpty) return TextError.empty;
  if (trimmed.length > maxLength) return TextError.tooLong;
  return null;
}

String normalizeName(String text) =>
    text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

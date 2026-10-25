import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/validators.dart';
import '../common/app_scope.dart';

String formatAmountInput(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

class ThousandsFormatter extends TextInputFormatter {
  static const int maxDigits = 10;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '');
    digits = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (digits.length > maxDigits) return oldValue;

    final cursor = newValue.selection.end.clamp(0, newValue.text.length);
    final digitsBeforeCursor = newValue.text
        .substring(0, cursor)
        .replaceAll(RegExp(r'\D'), '')
        .length;
    final formatted = formatAmountInput(int.parse(digits));

    var seen = 0;
    var offset = 0;
    while (offset < formatted.length && seen < digitsBeforeCursor) {
      if (formatted[offset] != ' ') seen++;
      offset++;
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}

class AmountField extends StatelessWidget {
  const AmountField({
    super.key,
    required this.controller,
    required this.label,
    this.onChanged,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.helperText,
    this.dense = false,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final TextInputAction textInputAction;
  final String? helperText;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      textInputAction: textInputAction,
      inputFormatters: [ThousandsFormatter()],
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        suffixText: s.currency,
        helperText: helperText,
        isDense: dense,
      ),
      validator: validator ?? (value) => s.amountError(validateAmount(value)),
    );
  }
}

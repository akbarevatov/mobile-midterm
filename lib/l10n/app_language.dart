import 'package:flutter/widgets.dart';

enum AppLanguage {
  uz('uz', 'Oʻzbekcha'),
  ru('ru', 'Русский');

  const AppLanguage(this.code, this.nativeName);

  final String code;
  final String nativeName;

  Locale get locale => Locale(code);

  static AppLanguage fromCode(String? code) => AppLanguage.values.firstWhere(
    (l) => l.code == code,
    orElse: () => AppLanguage.uz,
  );
}

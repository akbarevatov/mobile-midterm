import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.positive,
    required this.negative,
    required this.warning,
    required this.shared,
    required this.sharedContainer,
    required this.personal,
    required this.personalContainer,
    required this.muted,
  });

  final Color positive;
  final Color negative;
  final Color warning;
  final Color shared;
  final Color sharedContainer;
  final Color personal;
  final Color personalContainer;
  final Color muted;

  static const seed = Color(0xFF1F6F62);

  static const light = AppColors(
    positive: Color(0xFF1E7A3C),
    negative: Color(0xFFB0451A),
    warning: Color(0xFF8A5A00),
    shared: Color(0xFF5B4BA8),
    sharedContainer: Color(0xFFEAE6FA),
    personal: Color(0xFF1F6F62),
    personalContainer: Color(0xFFDDF0EA),
    muted: Color(0xFF6B7470),
  );

  static const dark = AppColors(
    positive: Color(0xFF7FD69A),
    negative: Color(0xFFFFB590),
    warning: Color(0xFFF2C46B),
    shared: Color(0xFFC7BDFF),
    sharedContainer: Color(0xFF332B5C),
    personal: Color(0xFF8FD5C4),
    personalContainer: Color(0xFF173F37),
    muted: Color(0xFF9AA39F),
  );

  static const memberPalette = [
    Color(0xFF2E7D6B),
    Color(0xFFC2185B),
    Color(0xFF3F51B5),
    Color(0xFFE65100),
    Color(0xFF558B2F),
    Color(0xFF7B1FA2),
    Color(0xFF0277BD),
    Color(0xFF795548),
  ];

  static Color member(int index) => memberPalette[index % memberPalette.length];

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>()!;

  @override
  AppColors copyWith({
    Color? positive,
    Color? negative,
    Color? warning,
    Color? shared,
    Color? sharedContainer,
    Color? personal,
    Color? personalContainer,
    Color? muted,
  }) => AppColors(
    positive: positive ?? this.positive,
    negative: negative ?? this.negative,
    warning: warning ?? this.warning,
    shared: shared ?? this.shared,
    sharedContainer: sharedContainer ?? this.sharedContainer,
    personal: personal ?? this.personal,
    personalContainer: personalContainer ?? this.personalContainer,
    muted: muted ?? this.muted,
  );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      positive: Color.lerp(positive, other.positive, t)!,
      negative: Color.lerp(negative, other.negative, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      shared: Color.lerp(shared, other.shared, t)!,
      sharedContainer: Color.lerp(sharedContainer, other.sharedContainer, t)!,
      personal: Color.lerp(personal, other.personal, t)!,
      personalContainer: Color.lerp(
        personalContainer,
        other.personalContainer,
        t,
      )!,
      muted: Color.lerp(muted, other.muted, t)!,
    );
  }
}

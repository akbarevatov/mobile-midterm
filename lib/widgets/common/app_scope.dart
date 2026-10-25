import 'package:flutter/widgets.dart';

import '../../l10n/app_strings.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope is missing above this widget');
    return scope!.notifier!;
  }
}

extension AppContext on BuildContext {
  AppState get app => AppScope.of(this);
  AppStrings get s => AppScope.of(this).strings;
  AppColors get colors => AppColors.of(this);
}

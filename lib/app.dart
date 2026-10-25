import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_language.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'widgets/common/app_scope.dart';
import 'widgets/navigation/main_shell.dart';

class BirgaApp extends StatelessWidget {
  const BirgaApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: ListenableBuilder(
        listenable: state,
        builder: (context, _) => MaterialApp(
          title: 'Birga',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: state.settings.themeMode,
          locale: state.settings.language.locale,
          supportedLocales: AppLanguage.values.map((l) => l.locale).toList(),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const RootGate(),
        ),
      ),
    );
  }
}

class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    if (app.isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(context.s.loading),
            ],
          ),
        ),
      );
    }
    if (!app.hasHousehold) return const WelcomeScreen();
    return const MainShell();
  }
}

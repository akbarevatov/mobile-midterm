import 'package:flutter/material.dart';

import 'app.dart';
import 'services/local_storage/key_value_store.dart';
import 'services/repositories/app_repository.dart';
import 'state/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState(repository: AppRepository(SharedPreferencesStore()));
  state.load();
  runApp(BirgaApp(state: state));
}

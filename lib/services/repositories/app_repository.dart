import 'dart:convert';

import 'package:flutter/material.dart';

import '../../l10n/app_language.dart';
import '../../models/app_data.dart';
import '../local_storage/key_value_store.dart';

enum LoadStatus { empty, loaded, unreadable }

class LoadResult {
  const LoadResult(this.status, [this.data]);

  final LoadStatus status;
  final AppData? data;
}

class AppSettings {
  const AppSettings({
    this.language = AppLanguage.uz,
    this.themeMode = ThemeMode.system,
  });

  final AppLanguage language;
  final ThemeMode themeMode;

  Map<String, dynamic> toJson() => {
    'language': language.code,
    'themeMode': themeMode.name,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    language: AppLanguage.fromCode(json['language'] as String?),
    themeMode: ThemeMode.values.firstWhere(
      (m) => m.name == json['themeMode'],
      orElse: () => ThemeMode.system,
    ),
  );
}

class AppRepository {
  AppRepository(this.store);

  static const dataKey = 'birga.data';
  static const backupKey = 'birga.data.unreadable_backup';
  static const settingsKey = 'birga.settings';

  final KeyValueStore store;

  Future<LoadResult> load() async {
    final raw = await store.read(dataKey);
    if (raw == null || raw.isEmpty) return const LoadResult(LoadStatus.empty);
    try {
      final json = jsonDecode(raw);
      return LoadResult(
        LoadStatus.loaded,
        AppData.fromJson(Map<String, dynamic>.from(json as Map)),
      );
    } catch (_) {
      await store.write(backupKey, raw);
      return const LoadResult(LoadStatus.unreadable);
    }
  }

  Future<void> save(AppData data) =>
      store.write(dataKey, jsonEncode(data.toJson()));

  Future<void> clear() => store.remove(dataKey);

  Future<bool> hasBackup() async => (await store.read(backupKey)) != null;

  Future<AppSettings> loadSettings() async {
    final raw = await store.read(settingsKey);
    if (raw == null) return const AppSettings();
    try {
      return AppSettings.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> saveSettings(AppSettings settings) =>
      store.write(settingsKey, jsonEncode(settings.toJson()));
}

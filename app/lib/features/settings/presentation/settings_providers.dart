import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventy_app/features/settings/data/http_settings_repository.dart';
import 'package:inventy_app/features/settings/domain/settings.dart';
import 'package:inventy_app/features/settings/domain/settings_repository.dart';
import 'package:inventy_app/shared/api/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden in main() with the loaded instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

/// Settings live in the backend so web and mobile share them.
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => HttpSettingsRepository(ref.watch(dioProvider)),
);

const _kBusinessName = 'businessName';
const _kDefaultThreshold = 'defaultThreshold';

class SettingsController extends Notifier<Settings> {
  @override
  Settings build() {
    // Show the last-known values instantly from the local cache, then refresh
    // from the backend (the source of truth shared across devices).
    final prefs = ref.read(sharedPreferencesProvider);
    final cached = Settings(
      businessName: prefs.getString(_kBusinessName) ?? 'Inventy',
      defaultThreshold: prefs.getInt(_kDefaultThreshold) ?? 0,
    );
    _refresh();
    return cached;
  }

  Future<void> _refresh() async {
    try {
      final remote = await ref.read(settingsRepositoryProvider).fetch();
      await _cache(remote);
      state = remote;
    } on Object {
      // Backend down / offline: keep the cached value.
    }
  }

  Future<void> _cache(Settings s) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_kBusinessName, s.businessName);
    await prefs.setInt(_kDefaultThreshold, s.defaultThreshold);
  }

  Future<void> setBusinessName(String value) async {
    final name = value.trim().isEmpty ? 'Inventy' : value.trim();
    final saved = await ref
        .read(settingsRepositoryProvider)
        .save(state.copyWith(businessName: name));
    await _cache(saved);
    state = saved;
  }

  Future<void> setDefaultThreshold(int value) async {
    final v = value < 0 ? 0 : value;
    final saved = await ref
        .read(settingsRepositoryProvider)
        .save(state.copyWith(defaultThreshold: v));
    await _cache(saved);
    state = saved;
  }
}

final settingsProvider =
    NotifierProvider<SettingsController, Settings>(SettingsController.new);

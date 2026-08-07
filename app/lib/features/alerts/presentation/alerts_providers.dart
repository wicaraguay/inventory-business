import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventy_app/features/settings/presentation/settings_providers.dart';

const _kAlertsEnabled = 'alerts_in_app_enabled';

/// Per-device toggle for the in-app stock alerts bell. Default on.
class AlertsEnabledController extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return prefs.getBool(_kAlertsEnabled) ?? true;
  }

  Future<void> set(bool value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_kAlertsEnabled, value);
    state = value;
  }
}

final alertsEnabledProvider =
    NotifierProvider<AlertsEnabledController, bool>(AlertsEnabledController.new);

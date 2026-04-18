import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final bool pushNotificationsEnabled;
  final bool emailMarketingEnabled;

  SettingsState({
    this.pushNotificationsEnabled = true,
    this.emailMarketingEnabled = false,
  });

  SettingsState copyWith({
    bool? pushNotificationsEnabled,
    bool? emailMarketingEnabled,
  }) {
    return SettingsState(
      pushNotificationsEnabled: pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      emailMarketingEnabled: emailMarketingEnabled ?? this.emailMarketingEnabled,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final push = prefs.getBool('push_notifications') ?? true;
    final email = prefs.getBool('email_marketing') ?? false;
    state = SettingsState(pushNotificationsEnabled: push, emailMarketingEnabled: email);
  }

  Future<void> setPushNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('push_notifications', value);
    state = state.copyWith(pushNotificationsEnabled: value);
  }

  Future<void> setEmailMarketing(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('email_marketing', value);
    state = state.copyWith(emailMarketingEnabled: value);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/notification_prefs.dart';

/// Preferencias de notificación persistidas en `shared_preferences`.
class NotificationPrefsNotifier extends Notifier<NotificationPrefs> {
  static const _key = 'eco_notif_prefs';

  @override
  NotificationPrefs build() {
    _load();
    return const NotificationPrefs();
  }

  Future<void> _load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_key);
    if (raw != null) {
      state = NotificationPrefs.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    }
  }

  Future<void> save(NotificationPrefs prefs) async {
    state = prefs;
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, jsonEncode(prefs.toJson()));
  }

  void update(NotificationPrefs prefs) => state = prefs;
}

final notificationPrefsProvider =
    NotifierProvider<NotificationPrefsNotifier, NotificationPrefs>(
  NotificationPrefsNotifier.new,
);

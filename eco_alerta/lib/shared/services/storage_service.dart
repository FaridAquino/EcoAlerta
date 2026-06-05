import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _usersKey = 'eco_users';
  static const _sessionKey = 'eco_session';

  Future<void> saveUser({
    required String email,
    required String password,
    required String routeId,
    required String address,
  }) async {
    final usersJson = await _storage.read(key: _usersKey);
    final users = usersJson != null
        ? Map<String, dynamic>.from(jsonDecode(usersJson))
        : <String, dynamic>{};

    users[email] = {
      'password': password,
      'routeId': routeId,
      'address': address,
    };
    await _storage.write(key: _usersKey, value: jsonEncode(users));
  }

  Future<Map<String, dynamic>?> getUser(String email) async {
    final usersJson = await _storage.read(key: _usersKey);
    if (usersJson == null) return null;
    final users = Map<String, dynamic>.from(jsonDecode(usersJson));
    final user = users[email];
    if (user == null) return null;
    return Map<String, dynamic>.from(user);
  }

  Future<void> saveSession(String email) async {
    await _storage.write(key: _sessionKey, value: email);
  }

  Future<String?> getSession() async {
    return _storage.read(key: _sessionKey);
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _sessionKey);
  }
}

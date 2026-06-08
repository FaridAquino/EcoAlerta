import '../../../../shared/services/storage_service.dart';

class AuthLocalDatasource {
  final StorageService _storage;

  AuthLocalDatasource(this._storage);

  Future<Map<String, dynamic>> login(String email, String password) async {
    final user = await _storage.getUser(email);
    if (user == null) throw Exception('Usuario no encontrado');
    if (user['password'] != password) throw Exception('Contraseña incorrecta');
    return user;
  }

  Future<void> register({
    required String email,
    required String password,
    required String routeId,
    required String address,
  }) async {
    final existing = await _storage.getUser(email);
    if (existing != null) throw Exception('El correo ya está registrado');
    await _storage.saveUser(
      email: email,
      password: password,
      routeId: routeId,
      address: address,
    );
  }

  Future<bool> isLoggedIn() async {
    final session = await _storage.getSession();
    return session != null;
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final email = await _storage.getSession();
    if (email == null) return null;
    final user = await _storage.getUser(email);
    if (user == null) return null;
    return {'email': email, ...user};
  }

  Future<String?> getSession() => _storage.getSession();

  Future<void> saveSession(String email) => _storage.saveSession(email);

  Future<void> clearSession() => _storage.clearSession();
}

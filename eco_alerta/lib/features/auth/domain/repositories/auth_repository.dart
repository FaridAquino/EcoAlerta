import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> login(String email, String password);
  Future<void> register({
    required String email,
    required String password,
    required String routeId,
    required String address,
  });
  Future<bool> isLoggedIn();
  Future<void> logout();

  /// Usuario de la sesión activa (con sus rutas/dirección), o `null` si no hay.
  Future<User?> getCurrentUser();
}

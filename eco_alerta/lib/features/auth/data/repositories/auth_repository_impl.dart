import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDatasource _datasource;

  AuthRepositoryImpl(this._datasource);

  @override
  Future<User> login(String email, String password) async {
    final data = await _datasource.login(email, password);
    await _datasource.saveSession(email);
    return User.fromMap(email, data);
  }

  @override
  Future<void> register({
    required String email,
    required String password,
    required String routeId,
    required String address,
  }) async {
    await _datasource.register(
      email: email,
      password: password,
      routeId: routeId,
      address: address,
    );
  }

  @override
  Future<bool> isLoggedIn() => _datasource.isLoggedIn();

  @override
  Future<void> logout() => _datasource.clearSession();

  @override
  Future<User?> getCurrentUser() async {
    final data = await _datasource.getCurrentUser();
    if (data == null) return null;
    return User.fromMap(data['email'] as String, data);
  }
}

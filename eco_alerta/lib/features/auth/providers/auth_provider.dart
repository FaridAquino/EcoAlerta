import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/services/storage_service.dart';
import '../data/datasources/auth_local_datasource.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/entities/user.dart';
import '../domain/repositories/auth_repository.dart';

final storageServiceProvider = Provider<StorageService>((_) => StorageService());

final authDatasourceProvider = Provider<AuthLocalDatasource>(
  (ref) => AuthLocalDatasource(ref.read(storageServiceProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.read(authDatasourceProvider)),
);

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final User user;
  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _checkSession();
    return const AuthInitial();
  }

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<void> _checkSession() async {
    final loggedIn = await _repo.isLoggedIn();
    state = loggedIn ? const AuthAuthenticated(User(email: '', routeId: '', address: '')) : const AuthUnauthenticated();
  }

  Future<bool> login(String email, String password) async {
    state = const AuthLoading();
    try {
      final user = await _repo.login(email, password);
      state = AuthAuthenticated(user);
      return true;
    } catch (e) {
      state = AuthError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String routeId,
    required String address,
  }) async {
    state = const AuthLoading();
    try {
      await _repo.register(
        email: email,
        password: password,
        routeId: routeId,
        address: address,
      );
      state = const AuthUnauthenticated();
      return true;
    } catch (e) {
      state = AuthError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthUnauthenticated();
  }

  void clearError() {
    state = const AuthUnauthenticated();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

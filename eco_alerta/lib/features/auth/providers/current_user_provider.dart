import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/user.dart';
import 'auth_provider.dart';
import 'routes_provider.dart';

/// Usuario de la sesión activa (incluye sus rutas elegidas como CSV en `routeId`).
/// Se recalcula cuando cambia el estado de autenticación.
final currentUserProvider = FutureProvider<User?>((ref) async {
  ref.watch(authProvider); // re-leer al iniciar/cerrar sesión
  return ref.read(authRepositoryProvider).getCurrentUser();
});

/// Las rutas de recolección que el usuario eligió en el registro.
final userRoutesProvider = FutureProvider<List<CollectionRoute>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  final all = await ref.watch(routesProvider.future);
  if (user == null || user.routeId.isEmpty) return const [];
  final ids = user.routeId
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toSet();
  return all.where((r) => ids.contains(r.id)).toList();
});

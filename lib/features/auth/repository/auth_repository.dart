// lib/features/auth/repository/auth_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider para el cliente de Supabase
final supabaseClientProvider = Provider((ref) => Supabase.instance.client);

// Provider para el repositorio de autenticación
final authRepositoryProvider = Provider(
  (ref) => AuthRepository(client: ref.watch(supabaseClientProvider)),
);

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository({required SupabaseClient client}) : _client = client;

  // Stream para escuchar cambios en el estado de autenticación
  Stream<AuthState> get authStateChange => _client.auth.onAuthStateChange;

  // Iniciar sesión
  Future<void> signInWithPassword(String email, String password) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      // Puedes manejar errores específicos aquí o relanzarlos
      throw Exception('Error al iniciar sesión: ${e.message}');
    } catch (e) {
      throw Exception('Ocurrió un error inesperado.');
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Obtener la sesión actual
  Session? get currentSession => _client.auth.currentSession;
}

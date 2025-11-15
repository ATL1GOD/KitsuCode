// lib/features/auth/repository/auth_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _supabaseClient;

  AuthRepository(this._supabaseClient);

  Stream<AuthState> get authStateChanges =>
      _supabaseClient.auth.onAuthStateChange;

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    await _supabaseClient.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    await _supabaseClient.auth.signUp(email: email, password: password);
  }

  Future<void> signInWithGoogle() async {
    await _supabaseClient.auth.signInWithOAuth(OAuthProvider.google);
  }

  Future<void> signOut() async {
    await _supabaseClient.auth.signOut();
  }

  // Método para cambiar la contraseña del usuario autenticado
  Future<void> changePassword(String newPassword) async {
    await _supabaseClient.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }
  
  // Verifica la contraseña actual del usuario antes de un cambio sensible.
  Future<void> reauthenticate(String password) async {
    final user = _supabaseClient.auth.currentUser;
    final email = user?.email;
    if (email == null) {
      throw Exception('No authenticated user found to reauthenticate.');
    }

    await _supabaseClient.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // --- ¡FUNCIÓN CORREGIDA! ---
  /// Llama a la Edge Function para eliminar todos los datos del usuario
  Future<void> deleteAccount() async {
    try {
      // 1. Obtiene la sesión actual para enviarla (implícitamente)
      if (_supabaseClient.auth.currentSession == null) {
        throw const AuthException('No hay sesión activa para eliminar la cuenta');
      }

      // 2. Invoca la Edge Function con el método POST
      final response = await _supabaseClient.functions.invoke(
        'Delete-accountI',
        method: HttpMethod.post, // <-- ¡ESTO ES LO QUE FALTABA!
      );

      if (response.status != 200) {
        // Si la función devuelve un error (500, 401, etc.)
        final errorMsg = response.data?['error'] ?? 'Error desconocido desde la función';
        throw AuthException('Error al eliminar la cuenta: $errorMsg');
      }

      // 3. Si todo salió bien en el backend (status 200),
      // el usuario ya no existe, así que lo deslogueamos del cliente.
      await _supabaseClient.auth.signOut();

    } on Exception catch (e) {
      // Captura errores específicos de la invocación de funciones
      print('Error al invocar la función "delete-user-data": ${e.toString()}');
      throw AuthException('Error del servidor: ${e.toString()}');
    } catch (e) {
      // Captura otros errores (como el AuthException que lanzamos arriba)
      print('Error en deleteAccount: $e');
      // Re-lanza el error para que la UI (settings_view) lo atrape
      rethrow;
    }
  }
}
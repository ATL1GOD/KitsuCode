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
  
  // --- ¡AÑADIR ESTE MÉTODO! ---
  /// Verifica la contraseña actual del usuario antes de un cambio sensible.
  Future<void> reauthenticate(String password) async {
    // Supabase no expone un método `reauthenticate` con un parámetro `password`.
    // Para verificar la contraseña del usuario, volvemos a iniciar sesión con
    // el email actual y la contraseña proporcionada.
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
  // Llama a la Edge Function para eliminar todos los datos del usuario
  Future<void> deleteAccount() async {
    final response = await _supabaseClient.functions.invoke('delete-user-data');

    if (response.status != 200) {
      // Si la función falla, lanzamos una excepción
      // que será capturada en la vista (settings_view)
      throw Exception('Error al eliminar la cuenta: ${response.data}');
    }

    // Si la función tiene éxito, deslogueamos al usuario.
    // Esto solo limpia la sesión local y dispara el onAuthStateChange.
    await _supabaseClient.auth.signOut();
  }
}
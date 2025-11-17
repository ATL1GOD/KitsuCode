import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _supabaseClient;

  AuthRepository(this._supabaseClient);

  Stream<AuthState> get authStateChanges =>
      _supabaseClient.auth.onAuthStateChange;

  // --- MEJORA: Validación de email antes del login ---
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    // Validación básica del email
    if (!_isValidEmail(email)) {
      throw AuthException('Formato de email inválido');
    }

    await _supabaseClient.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    // Validación básica del email
    if (!_isValidEmail(email)) {
      throw AuthException('Formato de email inválido');
    }

    await _supabaseClient.auth.signUp(email: email.trim(), password: password);
  }

  Future<void> signInWithGoogle() async {
    await _supabaseClient.auth.signInWithOAuth(
      OAuthProvider.google,
      // --- MEJORA: Parámetros adicionales para mejor UX ---
      redirectTo: 'kitsucode://login-callback',
    );
  }

  Future<void> signOut() async {
    await _supabaseClient.auth.signOut();
  }

  Future<void> changePassword(String newPassword) async {
    await _supabaseClient.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

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

  Future<void> deleteAccount() async {
    try {
      if (_supabaseClient.auth.currentSession == null) {
        throw const AuthException(
          'No hay sesión activa para eliminar la cuenta',
        );
      }

      final response = await _supabaseClient.functions.invoke(
        'Delete-accountI',
        method: HttpMethod.post,
      );

      if (response.status != 200) {
        final errorMsg =
            response.data?['error'] ?? 'Error desconocido desde la función';
        throw AuthException('Error al eliminar la cuenta: $errorMsg');
      }

      await _supabaseClient.auth.signOut();
    } on Exception catch (e) {
      print('Error al invocar la función "delete-user-data": ${e.toString()}');
      throw AuthException('Error del servidor: ${e.toString()}');
    } catch (e) {
      print('Error en deleteAccount: $e');
      rethrow;
    }
  }

  // --- NUEVO: Método de utilidad para validar email ---
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email.trim());
  }

  // --- NUEVO: Verificar si el usuario está autenticado ---
  bool get isAuthenticated => _supabaseClient.auth.currentUser != null;

  // --- NUEVO: Obtener el usuario actual ---
  User? get currentUser => _supabaseClient.auth.currentUser;
}

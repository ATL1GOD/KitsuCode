import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// --- AÑADIDO: Import para manejar las notificaciones ---
import 'package:firebase_messaging/firebase_messaging.dart';

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
      redirectTo: 'kitsucode://auth-done',
    );
  }

  // --- CORREGIDO: Eliminada la función duplicada ---
  Future<void> resetPasswordForEmail(String email) async {
    // Validación básica
    if (!_isValidEmail(email)) {
      throw AuthException('Formato de email inválido');
    }

    // Define a dónde debe redirigir Supabase al usuario DESPUÉS
    // de que haya creado su nueva contraseña en el enlace del correo.
    // Lo mandamos de vuelta a la pantalla de login.
    final String redirectUrl = kIsWeb
        ? 'http://localhost:3000/auth' // Para Web
        : 'kitsucode://auth-done'; // Para Móvil

    await _supabaseClient.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: redirectUrl,
    );
  }

  // --- ¡AQUÍ ESTÁ LA CORRECCIÓN PARA LAS NOTIFICACIONES! ---
  Future<void> signOut() async {
    try {
      // --- LÓGICA CORREGIDA BASADA EN TU ESQUEMA ---
      // 1. Obtenemos el ID del usuario que va a cerrar sesión
      final userId = _supabaseClient.auth.currentUser?.id;

      if (userId != null) {
        // 2. Actualizamos la tabla 'usuarios' para borrar su fcm_token
        //    Esto evita que reciba notificaciones después de cerrar sesión.
        await _supabaseClient
            .from('usuarios')
            .update({'fcm_token': null})
            .match({'id': userId});

        if (kDebugMode) {
          print('Token FCM limpiado para el usuario: $userId');
        }
      }

      // Opcional: invalidar el token de Firebase localmente
      // Esto fuerza a que se genere uno nuevo la próxima vez
      // y es una buena práctica de limpieza.
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      // No debemos detener el signOut si la limpieza del token falla,
      // pero sí debemos registrarlo.
      if (kDebugMode) {
        print('Error al limpiar suscripción de notificaciones: $e');
      }
    }

    // Finalmente, cerramos la sesión de Supabase
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

      // --- IMPORTANTE: Llamamos al nuevo signOut que limpia notificaciones ---
      await signOut();
    } on Exception catch (e) {
      if (kDebugMode) {
        print(
          'Error al invocar la función "delete-user-data": ${e.toString()}',
        );
      }
      throw AuthException('Error del servidor: ${e.toString()}');
    } catch (e) {
      if (kDebugMode) {
        print('Error en deleteAccount: $e');
      }
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

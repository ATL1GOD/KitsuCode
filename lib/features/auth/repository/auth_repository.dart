import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:firebase_messaging/firebase_messaging.dart';

class AuthRepository {
  final SupabaseClient _supabaseClient;

  AuthRepository(this._supabaseClient);

  Stream<AuthState> get authStateChanges =>
      _supabaseClient.auth.onAuthStateChange;

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
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
    if (!_isValidEmail(email)) {
      throw AuthException('Formato de email inválido');
    }

    final String redirectUrl = kIsWeb
        ? 'http://localhost:3000/auth'
        : 'kitsucode://auth-done';

    await _supabaseClient.auth.signUp(
      email: email.trim(),
      password: password,
      emailRedirectTo: redirectUrl,
    );
  }

  Future<void> signInWithGoogle() async {
    await _supabaseClient.auth.signInWithOAuth(
      OAuthProvider.google,

      redirectTo: 'kitsucode://auth-done',
    );
  }

  Future<void> resetPasswordForEmail(String email) async {
    if (!_isValidEmail(email)) {
      throw AuthException('Formato de email inválido');
    }

    final String redirectUrl = kIsWeb
        ? 'http://localhost:3000/auth' // Para Web
        : 'kitsucode://auth-done'; // Para Móvil

    await _supabaseClient.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: redirectUrl,
    );
  }

  Future<void> signOut() async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;

      if (userId != null) {
        await _supabaseClient
            .from('usuarios')
            .update({'fcm_token': null})
            .match({'id': userId});

        if (kDebugMode) {
          print('Token FCM limpiado para el usuario: $userId');
        }
      }

      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      if (kDebugMode) {
        print('Error al limpiar suscripción de notificaciones: $e');
      }
    }

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

  Future<bool> userExists(String email) async {
    try {
      final bool exists = await _supabaseClient.rpc(
        'check_if_user_exists',
        params: {'email_to_check': email.trim()},
      );
      return exists;
    } catch (e) {
      if (kDebugMode) {
        print('Error verificando existencia de usuario: $e');
      }
      return false;
    }
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email.trim());
  }

  bool get isAuthenticated => _supabaseClient.auth.currentUser != null;

  User? get currentUser => _supabaseClient.auth.currentUser;
}

// lib/features/auth/provider/auth_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kitsucode/features/auth/repository/auth_repository.dart';

// 1. Provider que expone el Stream de estado de autenticación
final authStateProvider = StreamProvider<AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChange;
});

// 2. ViewModel (Controller) para el manejo del estado del login
final authControllerProvider = StateNotifierProvider<AuthController, bool>((
  ref,
) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthController(authRepository: authRepository);
});

// 3. (NUEVO) Provider para exponer el mensaje de error de autenticación a la UI
final authErrorProvider = StateProvider<String?>((ref) => null);

class AuthController extends StateNotifier<bool> {
  final AuthRepository _authRepository;

  AuthController({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(false); // false = no estamos cargando nada inicialmente

  // Método para iniciar sesión (ahora acepta WidgetRef para manejar errores)
  Future<bool> login(String email, String password, WidgetRef ref) async {
    state = true; // Inicia el estado de carga
    ref.read(authErrorProvider.notifier).state = null; // Limpia errores previos

    try {
      await _authRepository.signInWithPassword(email, password);
      state = false; // Finaliza el estado de carga
      return true; // Éxito
    } catch (e) {
      // (MEJORA) Asigna el mensaje de error al provider de errores
      ref.read(authErrorProvider.notifier).state = e.toString();
      state = false; // Finaliza el estado de carga
      if (kDebugMode) {
        print(e.toString());
      }
      return false; // Fracaso
    }
  }

  // Método para cerrar sesión
  Future<void> logout() async {
    state = true;
    try {
      await _authRepository.signOut();
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
    }
    state = false;
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/auth/repository/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Provider que maneja el repositorio de autenticación
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});

// Provider que expone los cambios de estado de autenticación
final authStateProvider = StreamProvider<AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});

// Provider de estado para la pantalla de login (maneja la carga y errores)
final loginStateProvider = StateNotifierProvider<LoginState, AsyncValue<void>>((
  ref,
) {
  final authRepository = ref.read(authRepositoryProvider);
  return LoginState(authRepository);
});

// Provider de estado para la pantalla de registro
final registerStateProvider =
    StateNotifierProvider<RegisterState, AsyncValue<void>>((ref) {
      final authRepository = ref.read(authRepositoryProvider);
      return RegisterState(authRepository);
    });

class LoginState extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepository;
  LoginState(this._authRepository) : super(const AsyncValue.data(null));

  Future<void> signInWithEmailPassword(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signInWithPassword(
        email: email,
        password: password,
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow; // Permite que el error se propague si es necesario
    }
  }

  // --- NUEVO MÉTODO PARA INICIAR SESIÓN CON GOOGLE ---
  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signInWithGoogle();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

class RegisterState extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepository;
  RegisterState(this._authRepository) : super(const AsyncValue.data(null));

  Future<void> signUpWithEmailPassword(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signUpWithEmailPassword(
        email: email,
        password: password,
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow; // Permite que el error se propague para ser manejado en la UI
    }
  }
}

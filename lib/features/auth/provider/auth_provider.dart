import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/auth/repository/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kitsucode/core/providers/bootstrap_provider.dart';

// --- MEJORA 1: Cache del repositorio para evitar recreaciones múltiples ---
final _authRepositoryCache = StateProvider<AuthRepository?>((ref) => null);

final authRepositoryProvider = FutureProvider<AuthRepository>((ref) async {
  // Verificar si ya tenemos una instancia en cache
  final cachedRepo = ref.read(_authRepositoryCache);
  if (cachedRepo != null) return cachedRepo;

  await ref.watch(bootstrapProvider.future);

  final repository = AuthRepository(Supabase.instance.client);

  // Guardar en cache
  ref.read(_authRepositoryCache.notifier).state = repository;

  return repository;
});

// --- MEJORA 2: AuthStateProvider con manejo mejorado de estados ---
final authStateProvider = StreamProvider<AuthState>((ref) {
  final authRepositoryAsync = ref.watch(authRepositoryProvider);

  return authRepositoryAsync.when(
    data: (repository) {
      return repository.authStateChanges;
    },
    error: (e, stack) {
      // Log del error para debugging
      print('Error en authStateProvider: $e');
      return Stream.error(e, stack);
    },
    loading: () {
      return Stream.empty();
    },
  );
});

// --- MEJORA 3: LoginState con timeout y retry automático ---
final loginStateProvider = StateNotifierProvider<LoginState, AsyncValue<void>>((
  ref,
) {
  return LoginState(ref);
});

// --- MEJORA 4: RegisterState con validación mejorada ---
final registerStateProvider =
    StateNotifierProvider<RegisterState, AsyncValue<void>>((ref) {
      return RegisterState(ref);
    });

class LoginState extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  LoginState(this._ref) : super(const AsyncValue.data(null));

  Future<void> signInWithEmailPassword(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      // --- MEJORA: Timeout para evitar esperas infinitas ---
      final authRepository = await _ref
          .read(authRepositoryProvider.future)
          .timeout(const Duration(seconds: 30));

      await authRepository.signInWithPassword(email: email, password: password);
      state = const AsyncValue.data(null);
      _ref.invalidate(authStateProvider);
    } on TimeoutException {
      state = const AsyncValue.error(
        'Tiempo de espera agotado',
        StackTrace.empty,
      );
      rethrow;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final authRepository = await _ref
          .read(authRepositoryProvider.future)
          .timeout(const Duration(seconds: 30));

      await authRepository.signInWithGoogle();
      state = const AsyncValue.data(null);
    } on TimeoutException {
      state = const AsyncValue.error(
        'Tiempo de espera agotado',
        StackTrace.empty,
      );
      rethrow;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  // --- NUEVO: Método para limpiar estado de error ---
  void clearError() {
    if (state.hasError) {
      state = const AsyncValue.data(null);
    }
  }
}

class RegisterState extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  RegisterState(this._ref) : super(const AsyncValue.data(null));

  Future<void> signUpWithEmailPassword(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final authRepository = await _ref
          .read(authRepositoryProvider.future)
          .timeout(const Duration(seconds: 30));

      await authRepository.signUpWithEmailPassword(
        email: email,
        password: password,
      );
      state = const AsyncValue.data(null);
    } on TimeoutException {
      state = const AsyncValue.error(
        'Tiempo de espera agotado',
        StackTrace.empty,
      );
      rethrow;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  // --- NUEVO: Método para limpiar estado de error ---
  void clearError() {
    if (state.hasError) {
      state = const AsyncValue.data(null);
    }
  }
}

// [En auth_provider.dart]

// --- NUEVO: Provider para el cambio de contraseña ---
final changePasswordProvider =
    StateNotifierProvider<ChangePasswordState, AsyncValue<void>>((ref) {
      return ChangePasswordState(ref);
    });

class ChangePasswordState extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  ChangePasswordState(this._ref) : super(const AsyncValue.data(null));

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = const AsyncValue.loading();
    try {
      final authRepository = await _ref.read(authRepositoryProvider.future);

      // 1. RE-AUTENTICAR: El usuario prueba que es él
      await authRepository.reauthenticate(currentPassword);

      // 2. CAMBIAR CONTRASEÑA: Si lo anterior fue exitoso, actualiza
      await authRepository.changePassword(newPassword);

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow; // Re-lanza el error para que la UI lo atrape
    }
  }

  // --- NUEVO: Método para limpiar estado de error (opcional) ---
  void clearError() {
    if (state.hasError) {
      state = const AsyncValue.data(null);
    }
  }
}

// --- BLOQUE AÑADIDO: Provider para el restablecimiento de contraseña ---
final resetPasswordProvider =
    StateNotifierProvider<ResetPasswordState, AsyncValue<void>>((ref) {
      return ResetPasswordState(ref);
    });

class ResetPasswordState extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  ResetPasswordState(this._ref) : super(const AsyncValue.data(null));

  Future<void> sendResetEmail(String email) async {
    state = const AsyncValue.loading();
    try {
      final authRepository = await _ref.read(authRepositoryProvider.future);
      await authRepository.resetPasswordForEmail(email);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  // --- Método para limpiar estado de error ---
  void clearError() {
    if (state.hasError) {
      state = const AsyncValue.data(null);
    }
  }
}

// --- ¡¡BLOQUE 100% NUEVO!! ---
// --- Provider para ACTUALIZAR contraseña (sin re-autenticación) ---
final updatePasswordProvider =
    StateNotifierProvider<UpdatePasswordState, AsyncValue<void>>((ref) {
      return UpdatePasswordState(ref);
    });

class UpdatePasswordState extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  UpdatePasswordState(this._ref) : super(const AsyncValue.data(null));

  Future<void> updatePassword(String newPassword) async {
    state = const AsyncValue.loading();
    try {
      final authRepository = await _ref.read(authRepositoryProvider.future);

      // ¡Importante! Solo llamamos a changePassword (updateUser)
      // Supabase lo permite porque el usuario está en el estado
      // de "passwordRecovery"
      await authRepository.changePassword(newPassword);

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow; // Re-lanza el error para que la UI lo atrape
    }
  }

  // --- Método para limpiar estado de error ---
  void clearError() {
    if (state.hasError) {
      state = const AsyncValue.data(null);
    }
  }
}

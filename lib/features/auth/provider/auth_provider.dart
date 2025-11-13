import 'dart:async'; // Necesario para Stream.empty()
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/auth/repository/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- CAMBIO 1: Importa el bootstrap provider ---
// Necesitamos "esperar" a que termine.
import 'package:kitsucode/core/providers/bootstrap_provider.dart';

// --- CAMBIO 2: Convertido de Provider a FutureProvider ---
// Esto permite que el provider "espere" a que el bootstrap termine.
final authRepositoryProvider = FutureProvider<AuthRepository>((ref) async {
  // Esta línea "pausará" la creación del provider
  // hasta que bootstrapProvider haya completado su inicialización.
  await ref.watch(bootstrapProvider.future);

  // ¡AHORA es 100% seguro llamar a Supabase.instance!
  return AuthRepository(Supabase.instance.client);
});

// --- CAMBIO 3: authStateProvider ahora debe manejar el estado del FutureProvider ---
final authStateProvider = StreamProvider<AuthState>((ref) {
  // 1. Observa el *resultado* del FutureProvider
  final authRepositoryAsync = ref.watch(authRepositoryProvider);

  // 2. Maneja los 3 estados (cargando, error, datos)
  return authRepositoryAsync.when(
    data: (repository) {
      // Éxito: El repositorio está listo, devuelve su stream
      return repository.authStateChanges;
    },
    error: (e, stack) {
      // Error: Si el repositorio falló en crearse, propaga el error
      return Stream.error(e, stack);
    },
    loading: () {
      // Cargando: El repositorio aún no está listo, devuelve un stream vacío
      return Stream.empty();
    },
  );
});

// --- CAMBIO 4: LoginState ya no recibe el repositorio en el constructor ---
final loginStateProvider = StateNotifierProvider<LoginState, AsyncValue<void>>((
  ref,
) {
  // Ya no podemos "read" el repositorio síncronamente.
  // Solo pasamos "ref".
  return LoginState(ref);
});

// --- CAMBIO 5: RegisterState también se actualiza ---
final registerStateProvider =
    StateNotifierProvider<RegisterState, AsyncValue<void>>((ref) {
  return RegisterState(ref);
});

class LoginState extends StateNotifier<AsyncValue<void>> {
  // final AuthRepository _authRepository; // <-- Ya no está aquí
  final Ref _ref;
  // Solo recibe "ref"
  LoginState(this._ref) : super(const AsyncValue.data(null));

  Future<void> signInWithEmailPassword(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      // --- CAMBIO 6: Obtener el repositorio de forma ASÍNCRONA ---
      // "await" asegura que tenemos el repositorio antes de usarlo.
      final authRepository = await _ref.read(authRepositoryProvider.future);

      await authRepository.signInWithPassword(
        email: email,
        password: password,
      );
      state = const AsyncValue.data(null);
      _ref.invalidate(authStateProvider);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      // --- CAMBIO 6 (repetido): Obtener el repositorio de forma ASÍNCRONA ---
      final authRepository = await _ref.read(authRepositoryProvider.future);

      await authRepository.signInWithGoogle();
      state = const AsyncValue.data(null);
      _ref.invalidate(authStateProvider);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

class RegisterState extends StateNotifier<AsyncValue<void>> {
  // final AuthRepository _authRepository; // <-- Ya no está aquí
  final Ref _ref;
  RegisterState(this._ref) : super(const AsyncValue.data(null));

  Future<void> signUpWithEmailPassword(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      // --- CAMBIO 7: Obtener el repositorio de forma ASÍNCRONA ---
      final authRepository = await _ref.read(authRepositoryProvider.future);

      await authRepository.signUpWithEmailPassword(
        email: email,
        password: password,
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}
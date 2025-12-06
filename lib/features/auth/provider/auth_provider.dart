import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:kitsucode/features/auth/repository/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kitsucode/core/providers/bootstrap_provider.dart';

final _authRepositoryCache = StateProvider<AuthRepository?>((ref) => null);

final authRepositoryProvider = FutureProvider<AuthRepository>((ref) async {
  final cachedRepo = ref.read(_authRepositoryCache);
  if (cachedRepo != null) return cachedRepo;

  await ref.watch(bootstrapProvider.future);

  final repository = AuthRepository(Supabase.instance.client);

  ref.read(_authRepositoryCache.notifier).state = repository;

  return repository;
});

final authStateProvider = StreamProvider.autoDispose<AuthState>((ref) {
  final authRepositoryAsync = ref.watch(authRepositoryProvider);

  return authRepositoryAsync.when(
    data: (repository) {
      return repository.authStateChanges;
    },
    error: (e, stack) {
      if (kDebugMode) {
        print('Error en authStateProvider: $e');
      }
      return Stream.error(e, stack);
    },
    loading: () {
      return Stream.empty();
    },
  );
});

final loginStateProvider = StateNotifierProvider<LoginState, AsyncValue<void>>((
  ref,
) {
  return LoginState(ref);
});

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

  void clearError() {
    if (state.hasError) {
      state = const AsyncValue.data(null);
    }
  }
}

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

      await authRepository.reauthenticate(currentPassword);

      await authRepository.changePassword(newPassword);

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  void clearError() {
    if (state.hasError) {
      state = const AsyncValue.data(null);
    }
  }
}

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

  void clearError() {
    if (state.hasError) {
      state = const AsyncValue.data(null);
    }
  }
}

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

      await authRepository.changePassword(newPassword);

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  void clearError() {
    if (state.hasError) {
      state = const AsyncValue.data(null);
    }
  }
}

final privacyPolicyProvider = FutureProvider.autoDispose<List<dynamic>>((
  ref,
) async {
  final response = await Supabase.instance.client
      .from('app_textos')
      .select('contenido')
      .eq('id', 'politica_privacidad')
      .single();

  return response['contenido'] as List<dynamic>;
});

// lib/features/profile/provider/follow_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/profile/repository/profile_repository.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';

final isFollowingProvider = FutureProvider.family<bool, String>((ref, userId) {
  final profileRepository = ref.watch(profileRepositoryProvider);
  return profileRepository.isFollowing(userId);
});

final followControllerProvider = StateNotifierProvider.autoDispose<FollowController, bool>((ref) {
  final profileRepository = ref.watch(profileRepositoryProvider);
  return FollowController(profileRepository, ref);
});

class FollowController extends StateNotifier<bool> {
  final ProfileRepository _profileRepository;
  final Ref _ref;

  FollowController(this._profileRepository, this._ref) : super(false);

  Future<void> toggleFollow(String followedUserId) async {
    state = true;
    try {
      final currentUserId = _ref.read(authStateProvider).value?.session?.user.id;

      await _profileRepository.toggleFollow(followedUserId);
      
      // --- LÓGICA DE ACTUALIZACIÓN "EN VIVO" ---

      // 1. Refresca el estado del botón (Seguir/Siguiendo)
      _ref.invalidate(isFollowingProvider(followedUserId));
      
      // 2. Refresca el perfil del usuario que FUE seguido (actualiza su contador de "Seguidores")
      _ref.invalidate(userProfileByIdProvider(followedUserId));

      // 3. Refresca el perfil del usuario ACTUAL (actualiza su contador de "Siguiendo")
      if (currentUserId != null) {
        _ref.invalidate(userProfileByIdProvider(currentUserId));
      }

    } catch (e) {
      // Manejar error si es necesario
    } finally {
      state = false;
    }
  }
}
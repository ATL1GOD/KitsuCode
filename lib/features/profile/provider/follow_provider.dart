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
      
      // --- LÓGICA DE ACTUALIZACIÓN CORRECTA ---
      _ref.invalidate(isFollowingProvider(followedUserId));
      _ref.invalidate(userProfileByIdProvider(followedUserId));

      if (currentUserId != null) {
        // Invalida el perfil del usuario actual usando el provider unificado
        _ref.invalidate(userProfileByIdProvider(currentUserId));
      }

    } catch (e) {
      // Manejar error
    } finally {
      state = false;
    }
  }
}
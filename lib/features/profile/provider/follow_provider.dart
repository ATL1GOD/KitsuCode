// lib/features/profile/provider/follow_provider.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/profile/repository/profile_repository.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/features/profile/model/follow_list_model.dart'; 

// Clase para encapsular los argumentos de la lista (userId y type)
class FollowListArgs {
  final String userId;
  final String type; // 'following' o 'followers'

  FollowListArgs({required this.userId, required this.type});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FollowListArgs &&
        other.userId == userId &&
        other.type == type;
  }

  @override
  int get hashCode => userId.hashCode ^ type.hashCode;
}

// Provider que carga la lista de seguidores/siguiendo.
final followListProvider = FutureProvider.autoDispose.family<List<FollowListModel>, FollowListArgs>((ref, args) {
  final profileRepository = ref.watch(profileRepositoryProvider);

  return profileRepository.getFollowList(
    userId: args.userId,
    type: args.type,
  );
});


final isFollowingProvider = FutureProvider.autoDispose.family<bool, String>((ref, userId) {
  final profileRepository = ref.watch(profileRepositoryProvider);
  return profileRepository.isFollowing(userId);
});

final followControllerProvider = StateNotifierProvider.autoDispose<FollowController, bool>((ref) {
  final profileRepository = ref.watch(profileRepositoryProvider);
  // Mantener el provider vivo mientras hay una operación en curso
  final link = ref.keepAlive();
  // Auto-dispose después de 30 segundos de inactividad
  final timer = Timer(const Duration(seconds: 30), () {
    link.close();
  });
  ref.onDispose(() => timer.cancel());
  
  return FollowController(profileRepository, ref);
});

class FollowController extends StateNotifier<bool> {
  final ProfileRepository _profileRepository;
  final Ref _ref;

  FollowController(this._profileRepository, this._ref) : super(false);

  // Método modificado para devolver Future<bool> y aceptar currentListArgs
  Future<bool> toggleFollow(String followedUserId, {FollowListArgs? currentListArgs}) async {
    state = true;
    try {
      // Acceso al ID del usuario actual. Si el provider no tiene un valor, currentUserId será nulo.
      final currentUserId = _ref.read(authStateProvider).value?.session?.user.id;

      final newFollowState = await _profileRepository.toggleFollow(followedUserId);
      
      // 1. Invalida el estado del botón (Seguir/Siguiendo)
      _ref.invalidate(isFollowingProvider(followedUserId));

      // 2. Invalida los contadores del perfil seguido
      _ref.invalidate(userProfileByIdProvider(followedUserId));

      // 3. Invalida los contadores del usuario actual
      if (currentUserId != null) {
        _ref.invalidate(userProfileByIdProvider(currentUserId));
        
        // 🔥 SIEMPRE invalida las listas del usuario actual (siguiendo/seguidores)
        _ref.invalidate(followListProvider(FollowListArgs(userId: currentUserId, type: 'following')));
        _ref.invalidate(followListProvider(FollowListArgs(userId: currentUserId, type: 'followers')));
      }

      // 4. Invalida la lista de seguimiento si estamos en FollowListView
      if (currentListArgs != null) {
        _ref.invalidate(followListProvider(currentListArgs));
        
        // Opcional: Invalida la lista opuesta para asegurar la coherencia en la vista de perfil (aunque no la estemos viendo)
        final otherType = currentListArgs.type == 'following' ? 'followers' : 'following';
        final otherListArgs = FollowListArgs(userId: currentListArgs.userId, type: otherType);
        _ref.invalidate(followListProvider(otherListArgs));
      }
      
      // 🔥 CRÍTICO: Invalida TODAS las instancias del followListProvider
      // Esto asegura que cualquier lista que tenga a este usuario se actualice
      // sin importar de qué perfil sea la lista
      _ref.invalidate(followListProvider);

      return newFollowState;

    } catch (e) {
      // Re-lanzar el error para que la UI lo maneje (revierta el estado optimista)
      rethrow;
    } finally {
      state = false;
    }
  }
}
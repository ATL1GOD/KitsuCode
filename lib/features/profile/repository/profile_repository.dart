// lib/features/profile/repository/profile_repository.dart

import 'dart:async';
import 'package:kitsucode/features/profile/model/user_profile_model.dart';
import 'package:kitsucode/features/profile/model/user_stats_model.dart';
import 'package:kitsucode/features/profile/model/user_achievement_model.dart';
import 'package:kitsucode/features/profile/model/avatar_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kitsucode/features/profile/model/follow_list_model.dart';

class ProfileRepository {
  final SupabaseClient _supabase;

  ProfileRepository(this._supabase);

  // Este método observa los cambios en el perfil de un usuario en tiempo real.
  Stream<UserProfileModel> watchUserProfileById(String userId) async* {
    // 1. Emitimos el valor inicial inmediatamente para que la UI no espere.
    yield await fetchUserProfileById(userId);

    // 2. Creamos un listener de Supabase que se enfoca SÓLO en la fila de este usuario.
    final stream = _supabase
        .from('usuarios')
        .stream(primaryKey: ['id'])
        .eq('id', userId);

    // 3. Escuchamos el stream. Cada vez que haya un cambio (un UPDATE)...
    await for (final _ in stream) {
      // ...obtenemos el perfil actualizado...
      final updatedProfile = await fetchUserProfileById(userId);
      // ...y lo emitimos.
      yield updatedProfile;
    }
  }

  //  MÉTODO PARA OBTENER LA LISTA DE SEGUIDORES/SIGUIENDO
  /// Llama a la función RPC get_follow_list(p_user_id, p_type).
  /// El tipo puede ser 'following' o 'followers'.
  Future<List<FollowListModel>> getFollowList({
    required String userId,
    required String type,
  }) async {
    try {
      final data = await _supabase.rpc(
        'get_follow_list', // La función RPC definida en el backend
        params: {
          'p_user_id': userId,
          'p_type': type,
        },
      );

      final list = data as List;
      return list.map((json) => FollowListModel.fromJson(json)).toList();
    } catch (e) {
      // ignore: avoid_print
      print('Error al cargar la lista de seguimiento ($type): $e');
      throw Exception('Error al cargar la lista de seguimiento.');
    }
  }


  // Consulta si el usuario actual sigue a otro usuario
  Future<bool> isFollowing(String followedUserId) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return false;

    final response = await _supabase
        .from('seguimiento_usuario')
        .select()
        .eq('id_usuario', currentUser.id)
        .eq('id_usuario_seguido', followedUserId)
        .maybeSingle();

    return response != null;
  }

  Future<bool> toggleFollow(String followedUserId) async {
    final response = await _supabase.rpc(
      'toggle_follow',
      params: {'p_followed_user_id': followedUserId},
    );
    
    final isNowFollowing = response as bool;
    
    // Si ahora está siguiendo (true), enviar notificación
    if (isNowFollowing) {
      _sendFollowerNotification(followedUserId);
    }
    
    return isNowFollowing;
  }
  
  /// Enviar notificación de nuevo seguidor (sin esperar respuesta)
  void _sendFollowerNotification(String followedUserId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return;
      
      // Llamar Edge Function de forma asíncrona
      await _supabase.functions.invoke(
        'new-follower',
        body: {
          'follower_id': currentUserId,
          'followed_id': followedUserId,
        },
      );
    } catch (e) {
      // No fallar si la notificación falla
    }
  }

  Future<UserProfileModel> fetchUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('No hay un usuario autenticado.');
    }
    return fetchUserProfileById(user.id);
  }

  Future<UserProfileModel> fetchUserProfileById(String userId) async {
    try {
      final response = await _supabase.rpc(
        'get_user_profile_with_stats',
        params: {'user_id': userId},
      );
      return UserProfileModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al cargar el perfil del usuario: $e');
    }
  }

  Future<void> updateUserProfile({required String userId, String? newName, int? newAvatarId}) async {
    try {
      final updates = <String, dynamic>{};
      if (newName != null) {
        updates['nombre_perfil'] = newName;
      }
      if (newAvatarId != null) {
        updates['id_avatar_seleccionado'] = newAvatarId;
      }

      if (updates.isNotEmpty) {
        await _supabase
            .from('usuarios')
            .update(updates)
            .eq('id', userId);
      }
    } catch (e) {
      throw Exception('Error al actualizar el perfil: $e');
    }
  }

  Future<UserStatsModel> fetchUserStatsById(String userId) async {
    try {
      final response = await _supabase.rpc(
        'get_user_stats', 
        params: {'p_user_id': userId},
      );

      if (response == null) {
        return UserStatsModel.empty();
      }
      
      return UserStatsModel.fromJson(response);

    } catch (e) {
      // ignore: avoid_print
      print('Error en fetchUserStatsById (RPC): $e');
      return UserStatsModel.empty();
    }
  }
  
  Future<List<UserAchievementModel>> fetchUserAchievementsById(String userId) async {
    try {
      final data = await _supabase.rpc(
        'get_achievements_for_user',
        params: {'p_user_id': userId},
      );

      final list = data as List;
      return list.map((json) => UserAchievementModel.fromJson(json)).toList();

    } catch (e) {
      // ignore: avoid_print
      print('Error fetching achievements: $e');
      throw Exception('Error al cargar los logros');
    }
  }

  Future<UserStatsModel> fetchUserStats() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('No hay un usuario autenticado.');
    }
    return fetchUserStatsById(user.id);
  }

  Future<List<UserAchievementModel>> fetchUserAchievements() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('No hay un usuario autenticado.');
    }
    return fetchUserAchievementsById(user.id);
  }

  // ✅✅✅ ¡MÉTODO MOVIDO AQUÍ DENTRO! ✅✅✅
  // Busca los detalles de un logro específico por su ID
  Future<Map<String, dynamic>> fetchLogroDetails(int logroId) async {
    try {
      // ✅ Y AHORA USA '_supabase' (la variable de la clase)
      final data = await _supabase
          .from('logro')
          .select('nombre, icono, raridad')
          .eq('id_logro', logroId)
          .single();

      return data;
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching logro details: $e');
      throw Exception('Error al cargar detalles del logro');
    }
  }

  // ==================== MÉTODOS PARA AVATARES ====================
  
  /// Obtiene todos los avatares disponibles para un usuario específico
  /// Incluye el campo 'desbloqueado' que indica si el usuario tiene acceso
  Future<List<AvatarModel>> fetchUserAvatars(String userId) async {
    try {
      final data = await _supabase.rpc(
        'get_avatars_for_user',
        params: {'p_user_id': userId},
      );

      final list = data as List;
      return list.map((json) => AvatarModel.fromJson(json)).toList();
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching avatars: $e');
      throw Exception('Error al cargar los avatares');
    }
  }

  /// Desbloquea un avatar específico para un usuario
  /// Retorna true si se desbloqueó correctamente
  Future<bool> unlockAvatar({
    required String userId,
    required int avatarId,
  }) async {
    try {
      final result = await _supabase.rpc(
        'unlock_avatar_for_user',
        params: {
          'p_user_id': userId,
          'p_avatar_id': avatarId,
        },
      );
      return result as bool? ?? false;
    } catch (e) {
      // ignore: avoid_print
      print('Error unlocking avatar: $e');
      return false;
    }
  }
} 
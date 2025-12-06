import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:kitsucode/features/profile/model/user_profile_model.dart';
import 'package:kitsucode/features/profile/model/user_stats_model.dart';
import 'package:kitsucode/features/profile/model/user_achievement_model.dart';
import 'package:kitsucode/features/profile/model/avatar_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kitsucode/features/profile/model/follow_list_model.dart';
import 'package:kitsucode/features/amigos/model/search_model.dart';
import 'package:kitsucode/features/profile/model/challenge_history_model.dart';

class ProfileRepository {
  final SupabaseClient _supabase;

  ProfileRepository(this._supabase);

  Future<List<ChallengeHistoryModel>> getChallengeHistory(
    String userId, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final endOfDay = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
      );
      final startString = startDate.toUtc().toIso8601String();
      final endString = endOfDay.toUtc().toIso8601String();

      final response = await _supabase
          .from('intento_reto')
          .select('''
          fecha_intento,
          experiencia_obtenida,
          resultado,
          reto:id_reto!inner (
            titulo,
            niveles!inner (
              secciones!inner (
                titulo
              )
            ),
            dinamicas:tipo_reto!inner (
              nombre
            )
          )
        ''')
          .eq('id_usuario', userId)
          .gte('fecha_intento', startString)
          .lte('fecha_intento', endString)
          .order('fecha_intento', ascending: false);

      final List<dynamic> data = response;
      return data
          .map(
            (item) =>
                ChallengeHistoryModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error en getChallengeHistory: $e');
      }
      throw Exception('Error al obtener el historial de retos: $e');
    }
  }

  Stream<UserProfileModel> watchUserProfileById(String userId) async* {
    yield await fetchUserProfileById(userId);

    final stream = _supabase
        .from('usuarios')
        .stream(primaryKey: ['id'])
        .eq('id', userId);

    await for (final _ in stream) {
      final updatedProfile = await fetchUserProfileById(userId);

      yield updatedProfile;
    }
  }

  Future<List<FollowListModel>> getFollowList({
    required String userId,
    required String type,
  }) async {
    try {
      final data = await _supabase.rpc(
        'get_follow_list',
        params: {'p_user_id': userId, 'p_type': type},
      );

      final list = data as List;
      return list.map((json) => FollowListModel.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error al cargar la lista de seguimiento ($type): $e');
      }
      throw Exception('Error al cargar la lista de seguimiento.');
    }
  }

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

    if (isNowFollowing) {
      _sendFollowerNotification(followedUserId);
    }

    return isNowFollowing;
  }

  void _sendFollowerNotification(String followedUserId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return;

      final res = await _supabase.functions.invoke(
        'new-follower',
        body: {'follower_id': currentUserId, 'followed_id': followedUserId},
      );

      if (kDebugMode) {
        print('[new-follower] invoke result: $res');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[new-follower] error invoking function: $e');
      }
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

  Future<void> updateUserProfile({
    required String userId,
    String? newName,
    int? newAvatarId,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (newName != null) {
        updates['nombre_perfil'] = newName;
      }
      if (newAvatarId != null) {
        updates['id_avatar_seleccionado'] = newAvatarId;
      }

      if (updates.isNotEmpty) {
        await _supabase.from('usuarios').update(updates).eq('id', userId);
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
      if (kDebugMode) {
        print('Error en fetchUserStatsById (RPC): $e');
      }
      return UserStatsModel.empty();
    }
  }

  Future<List<UserAchievementModel>> fetchUserAchievementsById(
    String userId,
  ) async {
    try {
      final data = await _supabase.rpc(
        'get_achievements_for_user',
        params: {'p_user_id': userId},
      );

      final list = data as List;
      return list.map((json) => UserAchievementModel.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching achievements: $e');
      }
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

  Future<Map<String, dynamic>> fetchLogroDetails(int logroId) async {
    try {
      final data = await _supabase
          .from('logro')
          .select('nombre, icono, raridad')
          .eq('id_logro', logroId)
          .single();

      return data;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching logro details: $e');
      }
      throw Exception('Error al cargar detalles del logro');
    }
  }

  Future<Map<String, dynamic>> fetchAvatarDetails(int avatarId) async {
    try {
      final data = await _supabase
          .from('avatar')
          .select('nombre, asset_path, tipo, color_primario')
          .eq('id_avatar', avatarId)
          .single();

      return data;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching avatar details: $e');
      }
      throw Exception('Error al cargar detalles del avatar');
    }
  }

  Future<List<AvatarModel>> fetchUserAvatars(String userId) async {
    try {
      final data = await _supabase.rpc(
        'get_avatars_for_user',
        params: {'p_user_id': userId},
      );

      final list = data as List;
      return list.map((json) => AvatarModel.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching avatars: $e');
      }
      throw Exception('Error al cargar los avatares');
    }
  }

  Future<bool> unlockAvatar({
    required String userId,
    required int avatarId,
  }) async {
    try {
      final result = await _supabase.rpc(
        'unlock_avatar_for_user',
        params: {'p_user_id': userId, 'p_avatar_id': avatarId},
      );
      return result as bool? ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('Error unlocking avatar: $e');
      }
      return false;
    }
  }

  Future<List<UserSearchPreviewModel>> searchUsers(String query) async {
    final currentUserId = _supabase.auth.currentUser?.id;

    if (query.trim().isEmpty || currentUserId == null) {
      return [];
    }

    try {
      final data = await _supabase.rpc(
        'busqueda_amigos',
        params: {'p_query': query.trim(), 'p_user_id': currentUserId},
      );

      final list = data as List;
      return list.map((json) => UserSearchPreviewModel.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error al buscar usuarios: $e');
      }
      throw Exception('Error al buscar usuarios.');
    }
  }

  Future<List<Map<String, dynamic>>> getAvailableLanguages() async {
    final response = await _supabase
        .from('lenguaje')
        .select('id_lenguaje, nombre')
        .order('nombre');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> completeOnboarding({
    required String userId,
    required String username,
    required int languageId,
  }) async {
    await _supabase.rpc(
      'completar_onboarding',
      params: {
        'p_user_id': userId,
        'p_nombre_perfil': username,
        'p_id_lenguaje': languageId,
      },
    );
  }
}

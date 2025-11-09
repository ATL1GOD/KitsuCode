import 'dart:async'; 
import 'package:kitsucode/features/profile/model/user_profile_model.dart';
import 'package:kitsucode/features/profile/model/user_stats_model.dart';
import 'package:kitsucode/features/profile/model/user_achievement_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    await for (final data in stream) {
      // ...obtenemos el perfil actualizado...
      final updatedProfile = await fetchUserProfileById(userId);
      // ...y lo emitimos.
      yield updatedProfile;
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
    return response as bool;
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

  Future<void> updateUserProfile({required String userId, String? newName, String? newAvatar}) async {
    try {
      final updates = <String, dynamic>{};
      if (newName != null) {
        updates['nombre_perfil'] = newName;
      }
      if (newAvatar != null) {
        updates['avatar_url'] = newAvatar;
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
      // Cambiamos el .select() directo por una llamada a la RPC
      final response = await _supabase.rpc(
        'get_user_stats', // <-- Llamamos a la nueva RPC
        params: {'p_user_id': userId},
      );

      // Si la RPC no encuentra nada, puede devolver null
      if (response == null) {
        return UserStatsModel.empty();
      }
      
      // El JSON ya tiene los COALESCE(..., 0), así que es seguro.
      return UserStatsModel.fromJson(response);

    } catch (e) {
      // Manejo de error si la RPC falla
      print('Error en fetchUserStatsById (RPC): $e');
      return UserStatsModel.empty();
    }
  }
  
  Future<List<UserAchievementModel>> fetchUserAchievementsById(String userId) async {
    try {
      // ESTA ES LA LÓGICA ANTIGUA QUE VAMOS A CAMBIAR:
      // final data = await supabaseClient
      //     .from('logro')
      //     .select('*, usuario_logro!inner(id_usuario)')
      //     .eq('usuario_logro.id_usuario', userId);
      
      // ✅✅✅ ESTA ES LA LÓGICA NUEVA:
      // Llamamos a la función RPC que creamos en Supabase
      final data = await _supabase.rpc(
        'get_achievements_for_user',
        params: {'p_user_id': userId},
      );

      // La RPC devuelve una lista, la convertimos
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
}

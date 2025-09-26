import 'package:kitsucode/features/profile/model/user_profile_model.dart';
import 'package:kitsucode/features/profile/model/user_stats_model.dart';
import 'package:kitsucode/features/profile/model/user_achievement_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  final SupabaseClient _supabase;

  ProfileRepository(this._supabase);

  Future<UserProfileModel> fetchUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('No hay un usuario autenticado.');
    }

    try {
      final response = await _supabase.rpc(
        'get_user_profile_with_stats',
        params: {'user_id': user.id},
      );

      return UserProfileModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al cargar el perfil del usuario: $e');
    }
  }
  
  // Actualiza el perfil del usuario en la base de datos
  // recibe el id del usuario, un nuevo nombre y un nuevo avatar (ambos opc
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

  Future<UserStatsModel> fetchUserStats() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('No hay un usuario autenticado.');
    }

    try {
      final response = await _supabase
          .from('estadistica_usuario')
          .select()
          .eq('id_usuario', user.id)
          .maybeSingle(); // Usamos maybeSingle por si el usuario aún no tiene estadísticas

      if (response == null) {
        // Si no hay datos, regresamos un modelo vacío
        return UserStatsModel.empty();
      }

      return UserStatsModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al cargar las estadísticas: $e');
    }
  }


  // Consulta los logros del usuario actual
  Future<List<UserAchievementModel>> fetchUserAchievements() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('No hay un usuario autenticado.');
    }

    try {
      // Hacemos la consulta a la tabla de logros uniendo con la tabla intermedia 
      final response = await _supabase
          .from('logro')
          .select('*, usuario_logro!inner(*)')
          .eq('usuario_logro.id_usuario', user.id);

      // Convertimos la respuesta en una lista de nuestros modelos
      final achievements = (response as List)
          .map((json) => UserAchievementModel.fromJson(json))
          .toList();

      return achievements;
    } catch (e) {
      throw Exception('Error al cargar los logros: $e');
    }
  }
}
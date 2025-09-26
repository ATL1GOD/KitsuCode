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
      // --- CAMBIO CLAVE AQUÍ ---
      // Ya no hacemos un SELECT, llamamos a nuestra función con .rpc()
      final response = await _supabase.rpc(
        'get_user_profile_with_stats',
        params: {'user_id': user.id},
      );
      // --- FIN DEL CAMBIO ---

      // El resultado ya viene listo para nuestro modelo
      return UserProfileModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al cargar el perfil del usuario: $e');
    }
  }
  
  // --- ACTUALIZAR PERFIL DEL USUARIO (Lo usaremos más adelante) ---
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


  // --- 👇 AÑADE ESTA NUEVA FUNCIÓN COMPLETA 👇 ---
  Future<List<UserAchievementModel>> fetchUserAchievements() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('No hay un usuario autenticado.');
    }

    try {
      // Esta consulta es más avanzada. Le decimos a Supabase:
      // "Dame todos los datos de la tabla 'logro' (logro.*)
      //  pero solo aquellos cuyo id exista en la tabla 'usuario_logro'
      //  para el usuario actual (usuario_logro!inner(*))"
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
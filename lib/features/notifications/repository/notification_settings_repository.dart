import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kitsucode/features/notifications/model/notification_settings_model.dart';

// Provider para el Repositorio
final notificationSettingsRepositoryProvider = Provider((ref) {
  return NotificationSettingsRepository(
    supabaseClient: Supabase.instance.client
  );
});

class NotificationSettingsRepository {
  final SupabaseClient _supabaseClient;

  NotificationSettingsRepository({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  // Obtiene la lista de preferencias de notificación del usuario actual
  Future<List<NotificationSetting>> getNotificationSettings() async {
    try {
      final userId = _supabaseClient.auth.currentUser!.id;
      
      final response = await _supabaseClient
          .from('preferencias_notificacion')
          .select('''
            id_preferencia,
            habilitado,
            hora_notificacion,
            notificacion_tipo (
              id_tipo_notificacion,
              nombre_tipo,
              descripcion
            )
          ''')
          .eq('id_usuario', userId)
          .order('id_preferencia', ascending: true); // Ordenamos

      final settings = response
          .map((item) => NotificationSetting.fromJson(item))
          .toList();

      return settings;
      
    } catch (e) {
      // TODO: Manejar el caso donde un usuario nuevo no tiene preferencias
      print('Error al obtener preferencias de notificación: $e');
      rethrow;
    }
  }

Future<void> updateNotificationEnabled(int preferenciaId, bool habilitado) async {
    try {
      await _supabaseClient
          .from('preferencias_notificacion')
          .update({'habilitado': habilitado})
          .eq('id_preferencia', preferenciaId);
    } catch (e) {
      print("Error al actualizar 'habilitado': $e"); 
      rethrow;
    }
  }

  // --- ¡ASEGÚRATE DE QUE ESTA OTRA TAMBIÉN EXISTA! ---
  /// Actualiza la hora de una preferencia específica (DEBE aceptar null)
  Future<void> updateNotificationTime(int preferenciaId, String? hora) async {
    try {
      await _supabaseClient
          .from('preferencias_notificacion')
          .update({'hora_notificacion': hora}) // Pasa la hora (o null)
          .eq('id_preferencia', preferenciaId);
    } catch (e) {
      print("Error al actualizar 'hora_notificacion': $e");
      rethrow;
    }
  }

  // --- ¡Y ASEGÚRATE DE QUE ESTA NUEVA TAMBIÉN EXISTA! ---
  /// Actualiza el estado 'habilitado' de TODAS las preferencias del usuario.
  Future<void> updateAllEnabled(bool isEnabled) async {
    try {
      final userId = _supabaseClient.auth.currentUser!.id;
      
      await _supabaseClient
        .from('preferencias_notificacion')
        .update({'habilitado': isEnabled})
        .eq('id_usuario', userId);

    } catch (e) {
      print("Error al actualizar todas las notificaciones: $e");
      rethrow;
    }
  }
}
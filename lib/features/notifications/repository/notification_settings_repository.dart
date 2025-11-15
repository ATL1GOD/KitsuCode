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
          .order('id_preferencia', ascending: true);

      final settings = response
          .map((item) {
            // Convertir hora UTC a hora local antes de crear el modelo
            String? horaLocal;
            if (item['hora_notificacion'] != null) {
              horaLocal = _convertUtcToLocal(item['hora_notificacion'] as String);
              item['hora_notificacion'] = horaLocal;
            }
            return NotificationSetting.fromJson(item);
          })
          .toList();

      return settings;
      
    } catch (e) {
      print('Error al obtener preferencias de notificación: $e');
      rethrow;
    }
  }

  /// Convierte hora UTC de la BD a hora local del dispositivo
  String _convertUtcToLocal(String horaUtc) {
    try {
      final parts = horaUtc.split(':');
      final utcHour = int.parse(parts[0]);
      final utcMinute = int.parse(parts[1]);
      
      // Crear DateTime en UTC
      final now = DateTime.now();
      final utcTime = DateTime.utc(now.year, now.month, now.day, utcHour, utcMinute);
      
      // Convertir a hora local
      final localTime = utcTime.toLocal();
      
      // Formatear como HH:mm:ss
      return '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}:00';
    } catch (e) {
      print('Error convirtiendo hora UTC a local: $e');
      return horaUtc; // Si falla, devolver la hora original
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
  /// Actualiza la hora de una preferencia específica (convierte a UTC)
  Future<void> updateNotificationTime(int preferenciaId, String? hora) async {
    try {
      String? horaUTC;
      
      // Si hay una hora, convertirla a UTC
      if (hora != null) {
        final parts = hora.split(':');
        final localHour = int.parse(parts[0]);
        final localMinute = int.parse(parts[1]);
        
        // Crear DateTime con hora local
        final now = DateTime.now();
        final localTime = DateTime(now.year, now.month, now.day, localHour, localMinute);
        
        // Convertir a UTC
        final utcTime = localTime.toUtc();
        
        // Formatear como HH:mm:ss
        horaUTC = '${utcTime.hour.toString().padLeft(2, '0')}:${utcTime.minute.toString().padLeft(2, '0')}:00';
      }
      
      await _supabaseClient
          .from('preferencias_notificacion')
          .update({'hora_notificacion': horaUTC})
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
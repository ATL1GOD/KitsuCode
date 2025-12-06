import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kitsucode/features/notifications/model/notification_settings_model.dart';

final notificationSettingsRepositoryProvider = Provider((ref) {
  return NotificationSettingsRepository(
    supabaseClient: Supabase.instance.client,
  );
});

class NotificationSettingsRepository {
  final SupabaseClient _supabaseClient;

  NotificationSettingsRepository({required SupabaseClient supabaseClient})
    : _supabaseClient = supabaseClient;

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

      final settings = response.map((item) {
        String? horaLocal;
        if (item['hora_notificacion'] != null) {
          horaLocal = _convertUtcToLocal(item['hora_notificacion'] as String);
          item['hora_notificacion'] = horaLocal;
        }
        return NotificationSetting.fromJson(item);
      }).toList();

      return settings;
    } catch (e) {
      if (kDebugMode) {
        print('Error al obtener preferencias de notificación: $e');
      }
      rethrow;
    }
  }

  String _convertUtcToLocal(String horaUtc) {
    try {
      final parts = horaUtc.split(':');
      final utcHour = int.parse(parts[0]);
      final utcMinute = int.parse(parts[1]);

      final now = DateTime.now();
      final utcTime = DateTime.utc(
        now.year,
        now.month,
        now.day,
        utcHour,
        utcMinute,
      );

      final localTime = utcTime.toLocal();

      return '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}:00';
    } catch (e) {
      if (kDebugMode) {
        print('Error convirtiendo hora UTC a local: $e');
      }
      return horaUtc;
    }
  }

  Future<void> updateNotificationEnabled(
    int preferenciaId,
    bool habilitado,
  ) async {
    try {
      await _supabaseClient
          .from('preferencias_notificacion')
          .update({'habilitado': habilitado})
          .eq('id_preferencia', preferenciaId);
    } catch (e) {
      if (kDebugMode) {
        print("Error al actualizar 'habilitado': $e");
      }
      rethrow;
    }
  }

  Future<void> updateNotificationTime(int preferenciaId, String? hora) async {
    try {
      String? horaUTC;

      if (hora != null) {
        final parts = hora.split(':');
        final localHour = int.parse(parts[0]);
        final localMinute = int.parse(parts[1]);

        final now = DateTime.now();
        final localTime = DateTime(
          now.year,
          now.month,
          now.day,
          localHour,
          localMinute,
        );

        final utcTime = localTime.toUtc();

        horaUTC =
            '${utcTime.hour.toString().padLeft(2, '0')}:${utcTime.minute.toString().padLeft(2, '0')}:00';
      }

      await _supabaseClient
          .from('preferencias_notificacion')
          .update({'hora_notificacion': horaUTC})
          .eq('id_preferencia', preferenciaId);
    } catch (e) {
      if (kDebugMode) {
        print("Error al actualizar 'hora_notificacion': $e");
      }
      rethrow;
    }
  }

  Future<void> updateAllEnabled(bool isEnabled) async {
    try {
      final userId = _supabaseClient.auth.currentUser!.id;

      await _supabaseClient
          .from('preferencias_notificacion')
          .update({'habilitado': isEnabled})
          .eq('id_usuario', userId);
    } catch (e) {
      if (kDebugMode) {
        print("Error al actualizar todas las notificaciones: $e");
      }
      rethrow;
    }
  }
}

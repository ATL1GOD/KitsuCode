import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/notifications/model/notification_settings_model.dart';
import 'package:kitsucode/features/notifications/repository/notification_settings_repository.dart';

// El provider final que observará la UI
final notificationSettingsProvider = 
  AsyncNotifierProvider<NotificationSettingsNotifier, List<NotificationSetting>>(
    () => NotificationSettingsNotifier(),
  );

class NotificationSettingsNotifier extends AsyncNotifier<List<NotificationSetting>> {
  
  // El método 'build' es requerido por AsyncNotifier.
  // Es como un 'init' que obtiene el estado inicial.
  @override
  FutureOr<List<NotificationSetting>> build() async {
    final repository = ref.watch(notificationSettingsRepositoryProvider);
    return repository.getNotificationSettings();
  }

  // Método para actualizar el estado 'habilitado'
  Future<void> updateEnabled(int preferenciaId, bool habilitado) async {
    final repository = ref.read(notificationSettingsRepositoryProvider);
    
    // Actualización optimista: Cambia el estado local inmediatamente
    state = await AsyncValue.guard(() async {
      final currentState = state.value ?? [];
      return [
        for (final setting in currentState)
          if (setting.preferenciaId == preferenciaId)
            // Aquí deberíamos tener un método 'copyWith' en el modelo
            // Como no lo definimos, reconstruimos el objeto
            NotificationSetting(
              preferenciaId: setting.preferenciaId,
              habilitado: habilitado, // <-- El valor nuevo
              horaNotificacion: setting.horaNotificacion,
              tipoId: setting.tipoId,
              nombreTipo: setting.nombreTipo,
              descripcion: setting.descripcion,
              esRecordatorioHora: setting.esRecordatorioHora,
            )
          else
            setting,
      ];
    });

    // Ahora, intenta actualizar la base de datos
    try {
      await repository.updateNotificationEnabled(preferenciaId, habilitado);
    } catch (e, s) {
      // Si falla, revierte el estado y reporta el error
      state = AsyncError(e, s);
      // Opcionalmente, podrías recargar desde la BD
      // ref.invalidateSelf();
    }
  }

  // Método para actualizar la hora del recordatorio
  Future<void> updateTime(int preferenciaId, String? hora) async { // <-- String?
    final repository = ref.read(notificationSettingsRepositoryProvider);

    // Actualización optimista
    state = await AsyncValue.guard(() async {
      final currentState = state.value ?? [];
      return [
        for (final setting in currentState)
          if (setting.preferenciaId == preferenciaId)
            NotificationSetting(
              preferenciaId: setting.preferenciaId,
              habilitado: setting.habilitado,
              horaNotificacion: hora, // <-- El valor nuevo (puede ser null)
              tipoId: setting.tipoId,
              nombreTipo: setting.nombreTipo,
              descripcion: setting.descripcion,
              esRecordatorioHora: setting.esRecordatorioHora,
            )
          else
            setting,
      ];
    });

    // Actualizar la BD
    try {
      await repository.updateNotificationTime(preferenciaId, hora); // <-- Pasa la hora (o null)
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }

  // --- ¡AÑADE ESTA NUEVA FUNCIÓN! ---
  Future<void> updateAllEnabled(bool isEnabled) async {
    final repository = ref.read(notificationSettingsRepositoryProvider);

    // Actualización optimista (actualiza todas en el estado local)
    state = await AsyncValue.guard(() async {
      final currentState = state.value ?? [];
      return [
        for (final setting in currentState)
          NotificationSetting(
            preferenciaId: setting.preferenciaId,
            habilitado: isEnabled, // <-- El valor nuevo para todas
            horaNotificacion: setting.horaNotificacion,
            tipoId: setting.tipoId,
            nombreTipo: setting.nombreTipo,
            descripcion: setting.descripcion,
            esRecordatorioHora: setting.esRecordatorioHora,
          )
      ];
    });

    // Actualizar la BD
    try {
      await repository.updateAllEnabled(isEnabled);
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }
}
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/notifications/model/notification_settings_model.dart';
import 'package:kitsucode/features/notifications/repository/notification_settings_repository.dart';

final notificationSettingsProvider =
    AsyncNotifierProvider<
      NotificationSettingsNotifier,
      List<NotificationSetting>
    >(() => NotificationSettingsNotifier());

class NotificationSettingsNotifier
    extends AsyncNotifier<List<NotificationSetting>> {
  @override
  FutureOr<List<NotificationSetting>> build() async {
    final repository = ref.watch(notificationSettingsRepositoryProvider);
    return repository.getNotificationSettings();
  }

  Future<void> updateEnabled(int preferenciaId, bool habilitado) async {
    final repository = ref.read(notificationSettingsRepositoryProvider);

    state = await AsyncValue.guard(() async {
      final currentState = state.value ?? [];
      return [
        for (final setting in currentState)
          if (setting.preferenciaId == preferenciaId)
            NotificationSetting(
              preferenciaId: setting.preferenciaId,
              habilitado: habilitado,
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

    try {
      await repository.updateNotificationEnabled(preferenciaId, habilitado);
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }

  Future<void> updateTime(int preferenciaId, String? hora) async {
    final repository = ref.read(notificationSettingsRepositoryProvider);

    state = await AsyncValue.guard(() async {
      final currentState = state.value ?? [];
      return [
        for (final setting in currentState)
          if (setting.preferenciaId == preferenciaId)
            NotificationSetting(
              preferenciaId: setting.preferenciaId,
              habilitado: setting.habilitado,
              horaNotificacion: hora,
              tipoId: setting.tipoId,
              nombreTipo: setting.nombreTipo,
              descripcion: setting.descripcion,
              esRecordatorioHora: setting.esRecordatorioHora,
            )
          else
            setting,
      ];
    });

    try {
      await repository.updateNotificationTime(preferenciaId, hora);
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }

  Future<void> updateAllEnabled(bool isEnabled) async {
    final repository = ref.read(notificationSettingsRepositoryProvider);

    state = await AsyncValue.guard(() async {
      final currentState = state.value ?? [];
      return [
        for (final setting in currentState)
          NotificationSetting(
            preferenciaId: setting.preferenciaId,
            habilitado: isEnabled,
            horaNotificacion: setting.horaNotificacion,
            tipoId: setting.tipoId,
            nombreTipo: setting.nombreTipo,
            descripcion: setting.descripcion,
            esRecordatorioHora: setting.esRecordatorioHora,
          ),
      ];
    });

    try {
      await repository.updateAllEnabled(isEnabled);
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }
}

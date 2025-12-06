import 'package:flutter/material.dart';

class NotificationSetting {
  final int preferenciaId;
  final bool habilitado;
  final String? horaNotificacion;

  final int tipoId;
  final String nombreTipo;
  final String? descripcion;

  final bool esRecordatorioHora;

  NotificationSetting({
    required this.preferenciaId,
    required this.habilitado,
    this.horaNotificacion,
    required this.tipoId,
    required this.nombreTipo,
    this.descripcion,
    required this.esRecordatorioHora,
  });

  factory NotificationSetting.fromJson(Map<String, dynamic> json) {
    final tipoJson = json['notificacion_tipo'] as Map<String, dynamic>;

    final String nombreTipo = tipoJson['nombre_tipo'] as String;
    final bool esRecordatorio = nombreTipo.toLowerCase().contains(
      'recordatorio',
    );

    return NotificationSetting(
      preferenciaId: json['id_preferencia'] as int,
      habilitado: json['habilitado'] as bool,
      horaNotificacion: json['hora_notificacion'] as String?,

      tipoId: tipoJson['id_tipo_notificacion'] as int,
      nombreTipo: nombreTipo,
      descripcion: tipoJson['descripcion'] as String?,
      esRecordatorioHora: esRecordatorio,
    );
  }

  TimeOfDay get timeOfDay {
    if (horaNotificacion == null) {
      return const TimeOfDay(hour: 19, minute: 0);
    }
    try {
      final parts = horaNotificacion!.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return const TimeOfDay(hour: 19, minute: 0);
    }
  }

  static String timeOfDayToString(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }
}

import 'package:flutter/material.dart';

// Este modelo combinado representa una fila en la UI de Opciones de Notificación.
// Junta los datos de 'notificacion_tipo' y 'preferencias_notificacion'.
class NotificationSetting {
  // De 'preferencias_notificacion'
  final int preferenciaId;
  final bool habilitado;
  final String? horaNotificacion; // "19:00:00"

  // De 'notificacion_tipo'
  final int tipoId;
  final String nombreTipo;
  final String? descripcion;
  
  // Campo derivado para saber qué UI mostrar (Switch o Navegación)
  // Asumiremos que el recordatorio de estudio tiene un nombre_tipo específico
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

  // Constructor de fábrica desde el JSON que nos dará Supabase (con el join)
  factory NotificationSetting.fromJson(Map<String, dynamic> json) {
    final tipoJson = json['notificacion_tipo'] as Map<String, dynamic>;
    
    // Lógica para determinar si es un recordatorio de hora
    // TODO: Ajusta "Recordatorio de Estudio" al nombre exacto en tu BD
    final String nombreTipo = tipoJson['nombre_tipo'] as String;
    final bool esRecordatorio = nombreTipo.toLowerCase().contains('recordatorio');

    return NotificationSetting(
      // Campos de 'preferencias_notificacion'
      preferenciaId: json['id_preferencia'] as int,
      habilitado: json['habilitado'] as bool,
      horaNotificacion: json['hora_notificacion'] as String?,
      
      // Campos de 'notificacion_tipo'
      tipoId: tipoJson['id_tipo_notificacion'] as int,
      nombreTipo: nombreTipo,
      descripcion: tipoJson['descripcion'] as String?,
      esRecordatorioHora: esRecordatorio,
    );
  }

  // Helper para convertir la hora de la BD ("19:00:00") a TimeOfDay
  TimeOfDay get timeOfDay {
    if (horaNotificacion == null) {
      // Valor por defecto si no hay hora guardada
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

  // Helper para convertir TimeOfDay a String de BD ("HH:mm:ss")
  static String timeOfDayToString(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }
}
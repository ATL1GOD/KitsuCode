// [COMIENZO DEL ARCHIVO desafio_provider.dart]

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- Clases de Modelo Simples ---
// Modelo para los datos de la tarjeta de Evento Especial (Reto Agrupador)
class DesafioEspecial {
  final int idReto;
  final String titulo;
  final String descripcion;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final int recompensaExp;

  DesafioEspecial({
    required this.idReto,
    required this.titulo,
    required this.descripcion,
    required this.fechaInicio,
    required this.fechaFin,
    required this.recompensaExp,
  });

  // Factory para crear desde el JSON de Supabase
  factory DesafioEspecial.fromMap(Map<String, dynamic> map) {
    return DesafioEspecial(
      idReto: map['id_reto'],
      titulo: map['titulo'],
      descripcion: map['descripcion'] ?? 'Sin descripción.',
      fechaInicio: DateTime.parse(map['fecha_inicio']),
      fechaFin: DateTime.parse(map['fecha_final']),
      recompensaExp: map['recompensa_experiencia'] ?? 0,
    );
  }
}

// Modelo para los datos de la tarjeta de Desafío Diario (individual)
class RetoIndividual {
  final int idReto;
  final String titulo;
  final int recompensaExp;

  RetoIndividual({
    required this.idReto,
    required this.titulo,
    required this.recompensaExp,
  });

  // Factory para crear desde el JSON de Supabase
  factory RetoIndividual.fromMap(Map<String, dynamic> map) {
    return RetoIndividual(
      idReto: map['id_reto'],
      titulo: map['titulo'],
      recompensaExp: map['recompensa_experiencia'] ?? 0,
    );
  }
}

// Clase contenedora ÚNICA para el Reto Mensual
class RetoMensualData {
  final DesafioEspecial? agrupador; // Reto tipo 5
  final List<RetoIndividual> individuales; // Retos que lo componen
  final Set<int>
  completedRetoIds; // IDs de retos individuales completados por el usuario

  RetoMensualData({
    required this.agrupador,
    required this.individuales,
    required this.completedRetoIds,
  });
}

// --- El Provider ---

final supabase = Supabase.instance.client;

// El provider ahora devuelve RetoMensualData
final desafiosProvider = FutureProvider<RetoMensualData>((ref) async {
  // 0. Obtener el ID del usuario.
  final user = supabase.auth.currentUser;
  if (user == null) {
    // Manejar el caso de usuario no logueado
    throw Exception('User not logged in');
  }
  final userId = user.id;

  // 1. Consulta el Reto Agrupador Activo (tipo_reto = 5)
  final resultsEspeciales = await supabase
      .from('reto')
      .select(
        'id_reto, titulo, descripcion, fecha_inicio, fecha_final, recompensa_experiencia',
      )
      .eq('tipo_reto', 5) // Asumiendo que 5 es el tipo "Agrupador/Evento"
      .eq('especial', true)
      .eq('activo', true)
      .limit(1);

  final List<DesafioEspecial> especiales = (resultsEspeciales as List)
      .map((item) => DesafioEspecial.fromMap(item as Map<String, dynamic>))
      .toList();

  // Si no hay evento especial activo, retornar datos vacíos.
  if (especiales.isEmpty) {
    return RetoMensualData(
      agrupador: null,
      individuales: [],
      completedRetoIds: {},
    );
  }

  // 2. Obtener fechas del evento y Retos Individuales del Evento
  final event = especiales.first;
  final fechaInicioEvento = event.fechaInicio;
  final fechaFinalEvento = event.fechaFin;

  // Consulta 2.1: Retos Individuales que forman el Evento Mensual
  final resultsRetosIndividuales = await supabase
      .from('reto')
      .select('id_reto, titulo, recompensa_experiencia')
      .neq('tipo_reto', 5)
      .eq('especial', false)
      .eq('activo', true)
      .gte('fecha_inicio', fechaInicioEvento.toIso8601String())
      .lte('fecha_final', fechaFinalEvento.toIso8601String());

  final List<RetoIndividual> retosIndividuales =
      (resultsRetosIndividuales as List)
          .map((item) => RetoIndividual.fromMap(item as Map<String, dynamic>))
          .toList();

  // 3. Obtener el progreso del usuario para el Reto Agrupador
  final List<int> retosIndividualesIds = retosIndividuales
      .map((r) => r.idReto)
      .toList();

  final resultsCompleted = await supabase
      .from('intento_reto')
      .select('id_reto')
      .eq('id_usuario', userId)
      .eq('resultado', 'COMPLETADO')
      .inFilter('id_reto', retosIndividualesIds);

  final Set<int> completedMensualRetoIds = (resultsCompleted as List)
      .map((item) => item['id_reto'] as int)
      .toSet();

  return RetoMensualData(
    agrupador: event,
    individuales: retosIndividuales,
    completedRetoIds: completedMensualRetoIds,
  );
});
// [FIN DEL ARCHIVO desafio_provider.dart]

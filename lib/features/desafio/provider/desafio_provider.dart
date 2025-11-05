import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- Clases de Modelo Simples ---
// Modelo para los datos de la tarjeta de Evento Especial
class DesafioEspecial {
  final int idReto;
  final String titulo;
  final String descripcion;
  final DateTime fechaFin;

  DesafioEspecial({
    required this.idReto,
    required this.titulo,
    required this.descripcion,
    required this.fechaFin,
  });

  // Factory para crear desde el JSON de Supabase
  factory DesafioEspecial.fromMap(Map<String, dynamic> map) {
    return DesafioEspecial(
      idReto: map['id_reto'],
      titulo: map['titulo'],
      descripcion: map['descripcion'] ?? 'Sin descripción.',
      fechaFin: DateTime.parse(map['fecha_final']),
    );
  }
}

// Modelo para los datos de la tarjeta de Desafío Diario
class DesafioDiario {
  final int idReto;
  final String titulo;
  final int recompensaExp;
  // Podrías añadir dificultad, etc., si lo seleccionas en la query

  DesafioDiario({
    required this.idReto,
    required this.titulo,
    required this.recompensaExp,
  });

  // Factory para crear desde el JSON de Supabase
  factory DesafioDiario.fromMap(Map<String, dynamic> map) {
    return DesafioDiario(
      idReto: map['id_reto'],
      titulo: map['titulo'],
      recompensaExp: map['recompensa_experiencia'] ?? 0,
    );
  }
}

// Clase contenedora para ambos resultados
class DesafiosCompletos {
  final List<DesafioEspecial> especiales;
  final List<DesafioDiario> diarios;

  DesafiosCompletos({required this.especiales, required this.diarios});
}

// --- El Provider ---

final supabase = Supabase.instance.client;

final desafiosProvider = FutureProvider<DesafiosCompletos>((ref) async {
  final now = DateTime.now();

  // 1. Obtener Eventos Especiales (activos)
  final especialesResponse = await supabase
      .from('reto')
      .select('id_reto, titulo, descripcion, fecha_final')
      .eq('especial', true)
      .lte('fecha_inicio', now.toIso8601String()) // Que ya haya empezado
      .gte('fecha_final', now.toIso8601String()); // Que no haya terminado

  final List<DesafioEspecial> especiales = especialesResponse
      .map((item) => DesafioEspecial.fromMap(item))
      .toList();

  // 2. Obtener Desafíos Diarios (activos)
  final diariosResponse = await supabase
      .from('reto')
      .select('id_reto, titulo, recompensa_experiencia')
      .eq('especial', false)
      .eq('activo', true); // Solo los marcados como activos

  final List<DesafioDiario> diarios = diariosResponse
      .map((item) => DesafioDiario.fromMap(item))
      .toList();

  // 3. Devolver ambos
  return DesafiosCompletos(especiales: especiales, diarios: diarios);
});

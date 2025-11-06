// [COMIENZO DEL ARCHIVO desafio_provider.dart]

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- Clases de Modelo Simples ---
// Modelo para los datos de la tarjeta de Evento Especial
class DesafioEspecial {
  final int idReto;
  final String titulo;
  final String descripcion;
  final DateTime fechaFin;
  final int recompensaExp; // Añadido para consistencia con la VIEW

  DesafioEspecial({
    required this.idReto,
    required this.titulo,
    required this.descripcion,
    required this.fechaFin,
    required this.recompensaExp,
  });

  // Factory para crear desde el JSON de Supabase (usado por la VIEW)
  factory DesafioEspecial.fromMap(Map<String, dynamic> map) {
    return DesafioEspecial(
      idReto: map['id_reto'],
      titulo: map['titulo'],
      descripcion: map['descripcion'] ?? 'Sin descripción.',
      fechaFin: DateTime.parse(map['fecha_final']),
      recompensaExp: map['recompensa_experiencia'] ?? 0,
    );
  }
}

// Modelo para los datos de la tarjeta de Desafío Diario
class DesafioDiario {
  final int idReto;
  final String titulo;
  final int recompensaExp;

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
  // 1. Ejecutar las dos consultas en paralelo usando Future.wait
  //    Esto mejora el rendimiento al reducir la latencia de red.
  final results = await Future.wait([
    // Consulta 1: Eventos Especiales Activos en el Mes
    // 🔑 USAMOS LA VIEW DE SUPABASE, que ya aplica el filtro de fechas.
    supabase.from('desafios_especiales_activos').select('*'),

    // Consulta 2: Desafíos Diarios (No especiales, Activos)
    supabase
        .from('reto')
        .select('id_reto, titulo, recompensa_experiencia')
        .eq('especial', false)
        .eq('activo', true)
        .limit(5),
  ]);

  // 2. Procesar los resultados
  final List<DesafioEspecial> especiales = (results[0] as List)
      .map((item) => DesafioEspecial.fromMap(item))
      .toList();

  final List<DesafioDiario> diarios = (results[1] as List)
      .map((item) => DesafioDiario.fromMap(item))
      .toList();

  return DesafiosCompletos(especiales: especiales, diarios: diarios);
});
// [FIN DEL ARCHIVO desafio_provider.dart]

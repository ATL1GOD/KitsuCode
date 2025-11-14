// [COMIENZO DEL ARCHIVO desafio_provider.dart]
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- Helper para convertir Hex a Color ---
// Colócalo fuera de las clases, al inicio del archivo.
Color _colorFromHex(String hexString, {String fallback = '#808080'}) {
  final buffer = StringBuffer();
  String hex = hexString.replaceAll('#', '');
  if (hex.length == 6) {
    buffer.write('ff');
    buffer.write(hex);
  } else if (hex.length == 8) {
    buffer.write(hex);
  } else {
    // Si el string es inválido, usa el color de fallback (Gris)
    return _colorFromHex(fallback);
  }
  return Color(int.parse(buffer.toString(), radix: 16));
}

// --- Fin del Helper ---
// --- Clases de Modelo Simples ---
// Modelo para los datos de la tarjeta de Evento Especial (Reto Agrupador)
class DesafioEspecial {
  final int idReto;
  final String titulo;
  final String descripcion;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final Color colorClaro; // <-- 2. CAMBIADO A TIPO Color
  final Color colorOscuro; // <-- 3. CAMBIADO A TIPO Color
  final String svgEspecial; // <-- 4. AÑADIDO

  DesafioEspecial({
    required this.idReto,
    required this.titulo,
    required this.descripcion,
    required this.fechaInicio,
    required this.fechaFin,
    required this.colorClaro, // <-- 5. AÑADIDO AL CONSTRUCTOR
    required this.colorOscuro, // <-- 6. AÑADIDO AL CONSTRUCTOR
    required this.svgEspecial, // <-- 7. AÑADIDO AL CONSTRUCTOR
  });

  // Factory para crear desde el JSON de Supabase
  factory DesafioEspecial.fromMap(Map<String, dynamic> map) {
    // 8. Obtenemos el mapa anidado de los detalles
    final detalles = map['reto_especiales_detalles'] as Map<String, dynamic>?;

    return DesafioEspecial(
      idReto: map['id_reto'],
      titulo: map['titulo'],
      descripcion: map['descripcion'] ?? 'Sin descripción.',
      fechaInicio: DateTime.parse(map['fecha_inicio']),
      fechaFin: DateTime.parse(map['fecha_final']),

      // 9. Usamos el helper con valores por defecto
      colorClaro: _colorFromHex(
        detalles?['color_claro'] ?? '#66bb6a',
      ), // Verde claro por defecto
      colorOscuro: _colorFromHex(
        detalles?['color_oscuro'] ?? '#2e7d32',
      ), // Verde oscuro por defecto
      svgEspecial:
          detalles?['svg_especial'] ??
          'assets/images/default_fallback.svg', // SVG por defecto
    );
  }
}

// Modelo para los datos de la tarjeta de Desafío Diario (individual)
class RetoIndividual {
  final int idReto;
  final String titulo;
  final int nivelId; // <-- ¡AÑADIDO!

  RetoIndividual({
    required this.idReto,
    required this.titulo,
    required this.nivelId, // <-- ¡AÑADIDO!
  });

  // Factory para crear desde el JSON de Supabase
  factory RetoIndividual.fromMap(Map<String, dynamic> map) {
    // El join 'niveles(id_nivel)' devuelve una LISTA.
    // Tomamos el 'id_nivel' del primer (y probablemente único) nivel asociado.
    final niveles = map['niveles'] as List?;
    final int idNivelEncontrado;

    if (niveles != null && niveles.isNotEmpty) {
      // Extraemos el id_nivel del primer mapa en la lista
      idNivelEncontrado =
          (niveles.first as Map<String, dynamic>)['id_nivel'] as int? ?? 0;
    } else {
      idNivelEncontrado = 0; // Valor por defecto si no se encuentra
    }

    return RetoIndividual(
      idReto: map['id_reto'],
      titulo: map['titulo'],
      nivelId: idNivelEncontrado, // <-- ¡AÑADIDO!
    );
  }
}

// Clase contenedora ÚNICA para el Reto Mensual
class DesafioMensualData {
  final DesafioEspecial? agrupador; // Reto tipo 5
  final List<RetoIndividual> individuales; // Retos que lo componen
  final Set<int>
  completedRetoIds; // IDs de retos individuales completados por el usuario
  final bool isParentCompleted;

  DesafioMensualData({
    required this.agrupador,
    required this.individuales,
    required this.completedRetoIds,
    required this.isParentCompleted,
  });
}

// --- El Provider ---

final supabase = Supabase.instance.client;

// El provider ahora devuelve RetoMensualData
final desafiosProvider = FutureProvider<DesafioMensualData>((ref) async {
  // 0. Obtener el ID del usuario.
  final user = supabase.auth.currentUser;
  if (user == null) {
    // Manejar el caso de usuario no logueado
    throw Exception('Usuario no autenticado');
  }
  final userId = user.id;

  // 1. Obtener la fecha y hora actual en formato ISO
  final String now = DateTime.now().toIso8601String();

  // 1. Consulta el Reto Agrupador Activo
  final resultsEspeciales = await supabase
      .from('reto')
      .select(
        // 10. MODIFICAMOS LA CONSULTA
        'id_reto, titulo, descripcion, fecha_inicio, fecha_final, reto_especiales_detalles(color_claro, color_oscuro, svg_especial)',
      )
      .eq('especial', true)
      .eq(
        'activo',
        true,
      ) // Es bueno mantenerlo por si quieres desactivar uno manualmente
      .lte('fecha_inicio', now) // La fecha de inicio debe ser hoy o antes
      .gte('fecha_final', now) // La fecha final debe ser hoy o después
      .limit(1);

  final List<DesafioEspecial> especiales = (resultsEspeciales as List)
      .map((item) => DesafioEspecial.fromMap(item as Map<String, dynamic>))
      .toList();

  // Si no hay evento especial activo, retornar datos vacíos.
  if (especiales.isEmpty) {
    return DesafioMensualData(
      agrupador: null,
      individuales: [],
      completedRetoIds: {},
      isParentCompleted: false,
    );
  }

  // 2. Obtener fechas del evento y Retos Individuales del Evento
  final event = especiales.first;
  final fechaInicioEvento = event.fechaInicio;
  final fechaFinalEvento = event.fechaFin;

  // Consulta 2.1: Retos Individuales que forman el Evento Mensual
  final resultsRetosIndividuales = await supabase
      .from('reto')
      // ¡¡CAMBIO CLAVE AQUÍ!!
      // Hacemos un join a la tabla 'niveles' (basado en tu schema)
      // para obtener el 'id_nivel' asociado a este 'id_reto'.
      .select('id_reto, titulo, niveles(id_nivel)')
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
      .eq('resultado', 'completado')
      .inFilter('id_reto', retosIndividualesIds);

  final Set<int> completedMensualRetoIds = (resultsCompleted as List)
      .map((item) => item['id_reto'] as int)
      .toSet();

  final parentResult = await supabase
      .from('intento_reto')
      .select('id_reto')
      .eq('id_usuario', userId)
      .eq('id_reto', event.idReto) // <-- El ID del reto padre (tipo 5)
      .eq('resultado', 'completado')
      .limit(1);

  final bool isParentCompleted = parentResult.isNotEmpty;
  // --- FIN DE LA NUEVA LÓGICA ---

  return DesafioMensualData(
    agrupador: event,
    individuales: retosIndividuales,
    completedRetoIds: completedMensualRetoIds,
    isParentCompleted: isParentCompleted,
  );
});
// [FIN DEL ARCHIVO desafio_provider.dart]

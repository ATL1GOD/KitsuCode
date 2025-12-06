import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kitsucode/core/providers/connectivity_provider.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';

Color _colorFromHex(String hexString, {String fallback = '#808080'}) {
  final buffer = StringBuffer();
  String hex = hexString.replaceAll('#', '');
  if (hex.length == 6) {
    buffer.write('ff');
    buffer.write(hex);
  } else if (hex.length == 8) {
    buffer.write(hex);
  } else {
    return _colorFromHex(fallback);
  }
  return Color(int.parse(buffer.toString(), radix: 16));
}

class DesafioEspecial {
  final int idReto;
  final String titulo;
  final String descripcion;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final Color colorClaro;
  final Color colorOscuro;
  final String webpEspecial;

  DesafioEspecial({
    required this.idReto,
    required this.titulo,
    required this.descripcion,
    required this.fechaInicio,
    required this.fechaFin,
    required this.colorClaro,
    required this.colorOscuro,
    required this.webpEspecial,
  });

  factory DesafioEspecial.fromMap(Map<String, dynamic> map) {
    final detalles = map['reto_especiales_detalles'] as Map<String, dynamic>?;

    return DesafioEspecial(
      idReto: map['id_reto'],
      titulo: map['titulo'],
      descripcion: map['descripcion'] ?? 'Sin descripción.',
      fechaInicio: DateTime.parse(map['fecha_inicio']),
      fechaFin: DateTime.parse(map['fecha_final']),
      colorClaro: _colorFromHex(detalles?['color_claro'] ?? '#66bb6a'),
      colorOscuro: _colorFromHex(detalles?['color_oscuro'] ?? '#2e7d32'),
      webpEspecial:
          detalles?['asset_especial'] ?? 'assets/images/home/alerta.webp',
    );
  }
}

class RetoIndividual {
  final int idReto;
  final String titulo;
  final int nivelId;

  RetoIndividual({
    required this.idReto,
    required this.titulo,
    required this.nivelId,
  });

  factory RetoIndividual.fromMap(Map<String, dynamic> map) {
    final niveles = map['niveles'] as List?;
    final int idNivelEncontrado;

    if (niveles != null && niveles.isNotEmpty) {
      idNivelEncontrado =
          (niveles.first as Map<String, dynamic>)['id_nivel'] as int? ?? 0;
    } else {
      idNivelEncontrado = 0;
    }

    return RetoIndividual(
      idReto: map['id_reto'],
      titulo: map['titulo'],
      nivelId: idNivelEncontrado,
    );
  }
}

class DesafioMensualData {
  final DesafioEspecial? agrupador;
  final List<RetoIndividual> individuales;
  final Set<int> completedRetoIds;
  final bool isParentCompleted;

  DesafioMensualData({
    required this.agrupador,
    required this.individuales,
    required this.completedRetoIds,
    required this.isParentCompleted,
  });
}

final supabase = Supabase.instance.client;

final desafiosProvider = FutureProvider.autoDispose<DesafioMensualData>((
  ref,
) async {
  ref.watch(authStateProvider);
  final connectivityStatus = await ref.watch(connectivityProvider.future);
  if (connectivityStatus != ConnectivityStatus.online) {
    throw Exception('Sin conexión');
  }

  final user = supabase.auth.currentUser;
  if (user == null) {
    return DesafioMensualData(
      agrupador: null,
      individuales: [],
      completedRetoIds: {},
      isParentCompleted: false,
    );
  }
  final userId = user.id;
  final String now = DateTime.now().toIso8601String();

  final resultsEspeciales = await supabase
      .from('reto')
      .select(
        'id_reto, titulo, descripcion, fecha_inicio, fecha_final, reto_especiales_detalles(color_claro, color_oscuro, asset_especial)',
      )
      .eq('tipo_reto', 5)
      .eq('especial', true)
      .eq('activo', true)
      .lte('fecha_inicio', now)
      .gte('fecha_final', now)
      .limit(1);

  final List<DesafioEspecial> especiales = (resultsEspeciales as List)
      .map((item) => DesafioEspecial.fromMap(item as Map<String, dynamic>))
      .toList();

  if (especiales.isEmpty) {
    return DesafioMensualData(
      agrupador: null,
      individuales: [],
      completedRetoIds: {},
      isParentCompleted: false,
    );
  }

  final event = especiales.first;

  final resultsRetosIndividuales = await supabase
      .from('reto')
      .select('id_reto, titulo, niveles(id_nivel)')
      .eq('id_reto_padre', event.idReto)
      .eq('activo', true);

  final List<RetoIndividual> retosIndividuales =
      (resultsRetosIndividuales as List)
          .map((item) => RetoIndividual.fromMap(item as Map<String, dynamic>))
          .toList();

  final List<int> retosIndividualesIds = retosIndividuales
      .map((r) => r.idReto)
      .toList();

  Set<int> completedMensualRetoIds = {};

  if (retosIndividualesIds.isNotEmpty) {
    final resultsCompleted = await supabase
        .from('intento_reto')
        .select('id_reto')
        .eq('id_usuario', userId)
        .eq('resultado', 'completado')
        .inFilter('id_reto', retosIndividualesIds);

    completedMensualRetoIds = (resultsCompleted as List)
        .map((item) => item['id_reto'] as int)
        .toSet();
  }

  final parentResult = await supabase
      .from('intento_reto')
      .select('id_reto')
      .eq('id_usuario', userId)
      .eq('id_reto', event.idReto)
      .eq('resultado', 'completado')
      .limit(1);

  final bool isParentCompleted = parentResult.isNotEmpty;

  return DesafioMensualData(
    agrupador: event,
    individuales: retosIndividuales,
    completedRetoIds: completedMensualRetoIds,
    isParentCompleted: isParentCompleted,
  );
});

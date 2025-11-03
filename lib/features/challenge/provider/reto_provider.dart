// [COMIENZO DEL ARCHIVO /lib/features/challenge/provider/reto_provider.dart]

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 1. CLASE AUXILIAR (REVERTIDA)
//    Solo contiene el nombre de la dinámica y el contenido.
class ChallengeData {
  final String dinamicaNombre;
  final Map<String, dynamic> contenido;

  ChallengeData({required this.dinamicaNombre, required this.contenido});
}

// 2. PROVIDER GLOBAL DE SUPABASE
final supabase = Supabase.instance.client;

// 3. EL PROVIDER PRINCIPAL (REVERTIDO)
//    Vuelve a devolver un ChallengeData solo con 2 campos.
final challengeProvider = FutureProvider.family<ChallengeData, int>((
  ref,
  retoId,
) async {
  if (retoId == 0) {
    throw Exception('ID de reto inválido.');
  }

  try {
    // 4. LA CONSULTA (REVERTIDA)
    //    Ahora solo traemos 'contenido' y 'dinamicas ( nombre )'
    final response = await supabase
        .from('contenido_reto')
        .select(
          'contenido, dinamicas ( nombre )',
        ) // <-- CAMBIO: Se quitó 'reto ( titulo )'
        .eq('id_reto', retoId)
        .maybeSingle();

    if (response == null || response.isEmpty) {
      throw Exception('No se encontró contenido para este reto (ID: $retoId).');
    }

    // 5. EXTRACCIÓN Y VALIDACIÓN DE DATOS

    // Contenido (JSON)
    final Map<String, dynamic> contenido =
        response['contenido'] as Map<String, dynamic>;

    // Nombre de la Dinámica
    final dynamic dinamicasData = response['dinamicas'];
    if (dinamicasData == null ||
        dinamicasData is! Map ||
        dinamicasData['nombre'] == null) {
      throw Exception(
        'Error de integridad: El reto $retoId no tiene una dinámica (tipo_reto) válida asociada.',
      );
    }
    final String dinamicaNombre = dinamicasData['nombre'] as String;

    // 6. DEVOLVEMOS LOS DATOS EMPAQUETADOS (Sin título)
    return ChallengeData(dinamicaNombre: dinamicaNombre, contenido: contenido);
  } catch (e) {
    print('Error en challengeProvider: $e');
    throw Exception('Error al cargar el reto: $e');
  }
});

// [FIN DEL ARCHIVO /lib/features/challenge/provider/reto_provider.dart]

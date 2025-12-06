import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

class ChallengeData {
  final String dinamicaNombre;
  final Map<String, dynamic> contenido;
  final List<dynamic> recursos;

  ChallengeData({
    required this.dinamicaNombre,
    required this.contenido,
    required this.recursos,
  });
}

final supabase = Supabase.instance.client;

final challengeProvider = FutureProvider.family<ChallengeData, int>((
  ref,
  retoId,
) async {
  if (retoId == 0) {
    throw Exception('ID de reto inválido.');
  }

  try {
    final response = await supabase
        .from('contenido_reto')
        .select('''
          contenido, 
          dinamicas ( nombre ),
          reto ( recursos_json ) 
          ''')
        .eq('id_reto', retoId)
        .maybeSingle();

    if (response == null || response.isEmpty) {
      throw Exception('No se encontró contenido para este reto (ID: $retoId).');
    }

    final Map<String, dynamic> contenido =
        response['contenido'] as Map<String, dynamic>;

    final dynamic dinamicasData = response['dinamicas'];
    if (dinamicasData == null ||
        dinamicasData is! Map ||
        dinamicasData['nombre'] == null) {
      throw Exception(
        'Error de integridad: El reto $retoId no tiene una dinámica (tipo_reto) válida asociada.',
      );
    }
    final String dinamicaNombre = dinamicasData['nombre'] as String;

    final dynamic retoData = response['reto'];
    List<dynamic> recursosList = [];

    if (retoData != null &&
        retoData is Map &&
        retoData['recursos_json'] != null) {
      dynamic recursosJsonData = retoData['recursos_json'];

      if (recursosJsonData is String) {
        if (recursosJsonData.isNotEmpty) {
          try {
            recursosList = json.decode(recursosJsonData) as List<dynamic>;
          } catch (e) {
            if (kDebugMode) {
              print("Error al decodificar 'recursos_json' como String: $e");
            }
          }
        }
      } else if (recursosJsonData is List) {
        recursosList = recursosJsonData;
      }
    }

    return ChallengeData(
      dinamicaNombre: dinamicaNombre,
      contenido: contenido,
      recursos: recursosList,
    );
  } catch (e) {
    if (kDebugMode) {
      print('Error en challengeProvider: $e');
    }

    throw Exception('Error al cargar el reto: $e');
  }
});

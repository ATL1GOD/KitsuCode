// [COMIENZO DEL ARCHIVO /lib/features/challenge/provider/reto_provider.dart]

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert'; // Importante para decodificar el JSON de recursos

// 1. CLASE AUXILIAR (MODIFICADA)
class ChallengeData {
  final String dinamicaNombre;
  final Map<String, dynamic> contenido;
  final List<dynamic> recursos; // <-- AÑADIDO

  ChallengeData({
    required this.dinamicaNombre,
    required this.contenido,
    required this.recursos, // <-- AÑADIDO
  });
}

// 2. PROVIDER GLOBAL DE SUPABASE
final supabase = Supabase.instance.client;

// 3. EL PROVIDER PRINCIPAL (CORREGIDO)
final challengeProvider = FutureProvider.family<ChallengeData, int>((
  ref,
  retoId,
) async {
  if (retoId == 0) {
    throw Exception('ID de reto inválido.');
  }

  try {
    // 4. LA CONSULTA (¡CORREGIDA!)
    //    Volvemos a tu consulta original y añadimos el join a 'reto'
    final response = await supabase
        .from('contenido_reto') // <-- Tu tabla original
        .select(
          '''
          contenido, 
          dinamicas ( nombre ),
          reto ( recursos_json ) 
          '''
        ) // <-- ¡AÑADIDO EL JOIN SIMPLE A 'reto'!
        .eq('id_reto', retoId) // <-- Tu .eq() original
        .maybeSingle(); // <-- Tu .maybeSingle() original

    if (response == null || response.isEmpty) {
      throw Exception('No se encontró contenido para este reto (ID: $retoId).');
    }
    // 'response' es ahora el Map<String, dynamic> que esperas
    
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
    
    // Recursos (¡NUEVO!)
    final dynamic retoData = response['reto']; // Esto debería ser un Map
    List<dynamic> recursosList = [];
    
    // Verificamos que el join a 'reto' trajo datos y la columna 'recursos_json'
    if (retoData != null && retoData is Map && retoData['recursos_json'] != null) {
      // Tu BD tiene la columna 'recursos_json' como jsonb, 
      // pero a veces Supabase lo devuelve como String si se añadió después.
      // Manejamos ambos casos.
      
      dynamic recursosJsonData = retoData['recursos_json'];
      
      if (recursosJsonData is String) {
        // Si es un String, lo decodificamos
        if (recursosJsonData.isNotEmpty) {
           try {
            recursosList = json.decode(recursosJsonData) as List<dynamic>;
          } catch (e) {
            print("Error al decodificar 'recursos_json' como String: $e");
          }
        }
      } else if (recursosJsonData is List) {
        // Si ya es una Lista (formato JSONB nativo)
        recursosList = recursosJsonData;
      }

    }

    // 6. DEVOLVEMOS LOS DATOS EMPAQUETADOS
    return ChallengeData(
      dinamicaNombre: dinamicaNombre,
      contenido: contenido,
      recursos: recursosList, // <-- Pasamos la lista de recursos
    );
    
  } catch (e) {
    print('Error en challengeProvider: $e');
    // Relanzamos el error para que el 'error' del .when() lo atrape
    throw Exception('Error al cargar el reto: $e');
  }
});

// [FIN DEL ARCHIVO /lib/features/challenge/provider/reto_provider.dart]
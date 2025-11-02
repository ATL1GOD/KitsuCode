import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Asume que tienes una instancia de Supabase client
// (Probablemente la defines en un provider global)
final supabase = Supabase.instance.client;

// Este provider toma un ID de RETO y devuelve el JSONB de 'contenido_reto'
final challengeProvider = FutureProvider.family<Map<String, dynamic>, int>((
  ref,
  retoId,
) async {
  if (retoId == 0) {
    throw Exception('ID de reto inválido.');
  }

  try {
    // 1. Obtener el contenido del reto usando el ID del reto
    final response = await supabase
        .from('contenido_reto')
        .select('contenido') // Solo queremos la columna jsonb
        .eq('id_reto', retoId)
        .maybeSingle(); // Usar maybeSingle por si no existe

    if (response == null || response.isEmpty) {
      throw Exception('No se encontró contenido para este reto (ID: $retoId).');
    }

    // 2. Devolver el JSONB
    // (response['contenido'] ya es un Map<String, dynamic>)
    return response['contenido'] as Map<String, dynamic>;
  } catch (e) {
    print('Error en challengeProvider: $e');
    throw Exception('Error al cargar el reto: $e');
  }
});

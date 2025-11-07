import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 1. Provider para el repositorio
final challengeRepositoryProvider = Provider((ref) {
  final supabase = Supabase.instance.client;
  return ChallengeRepository(supabase);
});

// 2. La clase del Repositorio
class ChallengeRepository {
  final SupabaseClient _supabase;
  ChallengeRepository(this._supabase);

  // --- MODIFICADO: Ahora devuelve Future<int> ---
  Future<int> submitChallengeAttempt({
    required int retoId,
    required bool fueExitoso,
    required int tiempoQueTardo, // en segundos
  }) async {
    
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception("Usuario no autenticado");
    }

    try {
      // --- MODIFICADO: Usamos .select() para recuperar el dato ---
      final response = await _supabase.from('intento_reto').insert({
        'id_usuario': user.id,
        'id_reto': retoId,
        'resultado': fueExitoso ? 'completado' : 'fallido',
        'tiempo_empleado': tiempoQueTardo,
        // ¡El trigger de Supabase calculará 'experiencia_obtenida'!
      }).select('experiencia_obtenida'); // <-- PEDIMOS EL DATO DE VUELTA
      // --- FIN MODIFICADO ---

      if (response.isEmpty) {
        throw Exception("No se pudo obtener la experiencia del intento.");
      }
      
      // Devolvemos el valor
      final experiencia = response.first['experiencia_obtenida'] as int?;
      return experiencia ?? 0; // Devolvemos 0 si es nulo

    } catch (e) {
      // Manejar el error
      print("Error al guardar intento: $e");
      // Opcional: relanzar el error para que el provider lo maneje
      rethrow;
    }
  }
}
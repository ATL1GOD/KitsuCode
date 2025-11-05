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

  // Función que tu app llama al terminar un reto
  Future<void> submitChallengeAttempt({
    required int retoId,
    required bool fueExitoso,
    required int tiempoQueTardo, // en segundos
  }) async {
    
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception("Usuario no autenticado");
    }

    try {
      await _supabase.from('intento_reto').insert({
        'id_usuario': user.id,
        'id_reto': retoId,
        'resultado': fueExitoso ? 'completado' : 'fallido', // ¡Importante!
        'tiempo_empleado': tiempoQueTardo,
        // No enviamos 'experiencia_obtenida',
        // ¡El trigger de Supabase lo calculará solo!
      });

    } catch (e) {
      // Manejar el error
      print("Error al guardar intento: $e");
      // Opcional: relanzar el error para que el provider lo maneje
      rethrow;
    }
  }
}
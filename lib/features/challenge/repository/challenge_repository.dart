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

  // --- ¡FUNCIÓN QUE RETORNA LOS TROFEOS GANADOS! ---
  Future<int> submitChallengeAttempt({
    required int retoId,
    required int nivelId, // ← ¡AÑADIDO!
    required bool fueExitoso,
    required int tiempoQueTardo, // en segundos
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception("Usuario no autenticado");
    }

    try {
      // Llamamos a la función RPC que RETORNA los trofeos ganados
      final response = await _supabase.rpc(
        'completar_reto',
        params: {
          'id_reto_param': retoId,
          'id_nivel_param': nivelId, // ← ¡AÑADIDO!
          'id_usuario_param': user.id,
          'resultado_param': fueExitoso ? 'completado' : 'fallido',
          'tiempo_param': tiempoQueTardo,
        },
      );
      
      // Convertir la respuesta a int de manera segura
      if (response == null) {
        return 0;
      }
      
      // Intentar convertir a int
      if (response is int) {
        return response;
      } else if (response is num) {
        return response.toInt();
      } else {
        return 0;
      }
    } catch (e) {
      // Manejar el error
      rethrow;
    }
  }
}
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

  // --- ¡FUNCIÓN MODIFICADA! ---
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
      // En lugar de .insert(), llamamos a la función RPC
      // El 'await' ahora esperará a que AMBAS inserciones (intento y progreso) terminen.
      await _supabase.rpc(
        'completar_reto',
        params: {
          'id_reto_param': retoId,
          'id_usuario_param': user.id,
          'resultado_param': fueExitoso ? 'completado' : 'fallido',
          'tiempo_param': tiempoQueTardo,
        },
      );
    } catch (e) {
      // Manejar el error
      print("Error al llamar RPC 'completar_reto': $e");
      rethrow;
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final challengeRepositoryProvider = Provider((ref) {
  final supabase = Supabase.instance.client;
  return ChallengeRepository(supabase);
});

class ChallengeRepository {
  final SupabaseClient _supabase;
  ChallengeRepository(this._supabase);

  Future<int> submitChallengeAttempt({
    required int retoId,
    required int nivelId,
    required bool fueExitoso,
    required int tiempoQueTardo,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception("Usuario no autenticado");
    }

    try {
      final response = await _supabase.rpc(
        'completar_reto',
        params: {
          'id_reto_param': retoId,
          'id_nivel_param': nivelId,
          'id_usuario_param': user.id,
          'resultado_param': fueExitoso ? 'completado' : 'fallido',
          'tiempo_param': tiempoQueTardo,
        },
      );

      if (response == null) {
        return 0;
      }

      if (response is int) {
        return response;
      } else if (response is num) {
        return response.toInt();
      } else {
        return 0;
      }
    } catch (e) {
      rethrow;
    }
  }
}

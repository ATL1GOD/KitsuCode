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
          'id_usuario_param': user.id,
          'resultado_param': fueExitoso ? 'completado' : 'fallido',
          'tiempo_param': tiempoQueTardo,
        },
      );
      
      // Debug: Ver qué retorna la función
      print("✅ RPC completar_reto response: $response (tipo: ${response.runtimeType})");
      
      // Convertir la respuesta a int de manera segura
      if (response == null) {
        print("⚠️ La respuesta es null, retornando 0");
        return 0;
      }
      
      // Intentar convertir a int
      if (response is int) {
        print("✅ Retornando trofeos: $response");
        return response;
      } else if (response is num) {
        print("✅ Retornando trofeos (convertido): ${response.toInt()}");
        return response.toInt();
      } else {
        print("⚠️ Respuesta inesperada, retornando 0");
        return 0;
      }
    } catch (e, stackTrace) {
      // Manejar el error con más detalle
      print("❌ Error al llamar RPC 'completar_reto': $e");
      print("Stack trace: $stackTrace");
      rethrow;
    }
  }
}
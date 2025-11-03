// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:kitsucode/features/puzzle_game/model/puzzle_challenge_model.dart';

// final puzzleRepositoryProvider = Provider((ref) {
//   return PuzzleRepository();
// });

// class PuzzleRepository {
  
//   PuzzleRepository();

//   Future<PuzzleChallengeModel> getPuzzleChallenge(int retoId) async {
//     await Future.delayed(const Duration(seconds: 1));
    
//     if (retoId == 101) {
      
//       // --- ¡JSON SIMULADO ACTUALIZADO! ---
//       // Ahora usamos "type": "token" y "highlight"
//       final mockJson = {
//         "instruction": "Completa el código para verificar si un número es par.",
//         "lines": [
//           {"type": "token", "text": "#include", "highlight": "keyword"},
//           {"type": "token", "text": " <stdio.h>", "highlight": "string"},
//           {"type": "token", "text": "\n\n", "highlight": "normal"},
//           {"type": "token", "text": "int", "highlight": "type"},
//           {"type": "token", "text": " main() {", "highlight": "normal"},
//           {"type": "token", "text": "\n  ", "highlight": "normal"},
//           {"type": "token", "text": "int", "highlight": "type"},
//           {"type": "token", "text": " num = 10;", "highlight": "normal"},
//           {"type": "token", "text": "\n  ", "highlight": "normal"},
//           {"type": "blank", "id": "blank_1", "correct_option_id": "opt_A"},
//           {"type": "token", "text": " (num % 2 == 0) {", "highlight": "normal"},
//           {"type": "token", "text": "\n    printf(", "highlight": "normal"},
//           {"type": "token", "text": "\"Es par\"", "highlight": "string"},
//           {"type": "token", "text": ");", "highlight": "normal"},
//           {"type": "token", "text": "\n  }", "highlight": "normal"},
//           {"type": "token", "text": "\n  return 0;", "highlight": "normal"},
//           {"type": "token", "text": "\n}", "highlight": "normal"}
//         ],
//         "options": [
//           {"id": "opt_A", "text": "if"},
//           {"id": "opt_B", "text": "while"},
//           {"id": "opt_C", "text": "for"}
//         ]
//       };
//       // --- FIN DEL JSON ACTUALIZADO ---
      
//       return PuzzleChallengeModel.fromJson(mockJson);
//     }
    
//     throw Exception('Reto no encontrado (id: $retoId)');
//   }
// }

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/puzzle_game/model/puzzle_challenge_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Importa el provider de tu cliente.
import 'package:kitsucode/features/auth/provider/auth_provider.dart';


// 1. Modificamos el provider para que inyecte el cliente de Supabase
final puzzleRepositoryProvider = Provider((ref) {
  // Obtenemos el cliente de Supabase que ya usa tu app
  // Si no tienes un provider global, puedes usar Supabase.instance.client
  final supabaseClient = Supabase.instance.client;
  return PuzzleRepository(client: supabaseClient);
});

class PuzzleRepository {
  // 2. Añadimos el cliente de Supabase
  final SupabaseClient _client;
  PuzzleRepository({required SupabaseClient client}) : _client = client;

  /// Obtiene el desafío de puzzle desde la BD
  Future<PuzzleChallengeModel> getPuzzleChallenge(int retoId) async {
    
    // --- 3. ¡ESTA ES LA LÓGICA REAL DE LA BD! ---
    try {
      // Hacemos un SELECT a la tabla 'contenido_reto'
      final response = await _client
          .from('contenido_reto')
          .select('contenido') // ... solo queremos la columna 'contenido' (el jsonb)
          .eq('id_reto', retoId) // ... donde el id_reto coincida
          .single(); // ... y esperamos un solo resultado.

      // El 'response' es un Map, p.ej: {'contenido': { ...nuestro json... }}
      final contenidoJson = response['contenido'] as Map<String, dynamic>;
      
      // Usamos el modelo para parsear ese JSON
      return PuzzleChallengeModel.fromJson(contenidoJson);

    } on PostgrestException catch (e) {
      // Manejo de errores de Supabase (p.ej. no encontró el reto)
      print('Error de Supabase al cargar reto: ${e.message}');
      throw Exception('Error al cargar el desafío: ${e.message}');
    } catch (e) {
      // Error genérico (p.ej. error de parseo del JSON)
      print('Error inesperado en PuzzleRepository: $e');
      throw Exception('Error inesperado: $e');
    }
    // --- FIN DE LA LÓGICA REAL ---
  }
}
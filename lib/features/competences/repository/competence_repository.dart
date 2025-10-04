// // lib/features/competences/repository/competence_repository.dart

// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:kitsucode/features/competences/model/ranking_model.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// // 1. Contrato
// abstract class CompetenceRepository { 
//   Future<List<RankingModel>> fetchGlobalRanking(int languageId, int difficultyId);
// }

// // 2. Implementación de Supabase
// class SupabaseCompetenceRepository implements CompetenceRepository {
//   final SupabaseClient _supabase;

//   SupabaseCompetenceRepository(this._supabase);

//   @override
//   Future<List<RankingModel>> fetchGlobalRanking(int languageId, int difficultyId) async {
//     try {
//       // LLAMADA RPC (Remote Procedure Call) a la función que acabamos de crear
//       final response = await _supabase.rpc(
//         'get_global_ranking', 
//         params: {
//           'p_language_id': languageId,   // Filtro por Lenguaje
//           'p_difficulty_id': difficultyId, // Filtro por Dificultad
//         }
//       );
      
//       // La respuesta es una lista de JSON, la mapeamos al modelo
//       final rankingList = (response as List)
//           .map((json) => RankingModel.fromJson(json))
//           .toList();

//       return rankingList;
      
//     } catch (e) {
//         // En caso de error de conexión/servidor (E_05)
//         throw Exception('E_05: Error al cargar el ranking desde el servidor. ${e.toString()}');
//     }
//   }
// }

// // 3. Provider de la Capa de Datos
// final competenceRepositoryProvider = Provider<CompetenceRepository>((ref) {
//   // Aseguramos el uso del cliente de Supabase
//   final supabaseClient = Supabase.instance.client;
//   return SupabaseCompetenceRepository(supabaseClient); 
// });

// lib/features/competences/repository/competence_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/competences/model/ranking_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math'; 

// 1. Contrato
abstract class CompetenceRepository { 
  Future<List<RankingModel>> fetchGlobalRanking(int languageId, int difficultyId);
}

// 2. Implementación de Supabase (Comentada)
class SupabaseCompetenceRepository implements CompetenceRepository {
  final SupabaseClient _supabase;

  SupabaseCompetenceRepository(this._supabase);

  @override
  Future<List<RankingModel>> fetchGlobalRanking(int languageId, int difficultyId) async {
    // ⚠️ CÓDIGO REAL DE SUPABASE COMENTADO PARA USAR EL MOCK DE DEBUG
    /*
    try {
      final response = await _supabase.rpc(
        'get_global_ranking', 
        params: {
          'p_language_id': languageId,   
          'p_difficulty_id': difficultyId, 
        }
      );
      
      final rankingList = (response as List)
          .map((json) => RankingModel.fromJson(json))
          .toList();

      return rankingList;
      
    } catch (e) {
        throw Exception('E_05: Error al cargar el ranking desde el servidor. ${e.toString()}');
    }
    */
    throw UnimplementedError('El repositorio Supabase está comentado. Activa Mock para debug.');
  }
}

// 3. Implementación de Mock (para debug con 30 usuarios)
class MockCompetenceRepository implements CompetenceRepository {
  final Random _random = Random();

  @override
  Future<List<RankingModel>> fetchGlobalRanking(int languageId, int difficultyId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final List<RankingModel> ranking = [];
    
    // Generar 30 usuarios para que la lista sea scrollable
    for (int i = 1; i <= 30; i++) {
      String username = i == 2 ? 'dxniel7' : 'Usuario$i'; 
      int score = 5000 - (i * 100) + _random.nextInt(100);
      String rankName;
      
      if (score >= 4500) rankName = 'Diamante';
      else if (score >= 3500) rankName = 'Oro';
      else if (score >= 2000) rankName = 'Plata';
      else rankName = 'Bronce';

      ranking.add(RankingModel(
        userId: 'id_$i',
        username: username,
        profileName: 'Competidor $i',
        // Usamos assets de prueba (avatar_tiburon, avatar_leon, etc.)
        avatarUrl: 'assets/images/avatar_${i % 4 == 0 ? 'leon' : i % 3 == 0 ? 'mono' : 'tiburon'}.png',
        totalScore: score,
        rank: rankName,
        position: i, // La posición se asigna después de ordenar
      ));
    }

    // Ordenar por puntaje y asignar posición final
    ranking.sort((a, b) => b.totalScore.compareTo(a.totalScore));
    for (int i = 0; i < ranking.length; i++) {
        ranking[i] = RankingModel(
          userId: ranking[i].userId,
          username: ranking[i].username,
          profileName: ranking[i].profileName,
          avatarUrl: ranking[i].avatarUrl,
          totalScore: ranking[i].totalScore,
          rank: ranking[i].rank,
          position: i + 1, // Posición final
        );
    }

    return ranking;
  }
}

// 4. Provider de la Capa de Datos (SWITCH ACTIVO)
final competenceRepositoryProvider = Provider<CompetenceRepository>((ref) {
  // final supabaseClient = Supabase.instance.client;
  // return SupabaseCompetenceRepository(supabaseClient); 
  
  // 💡 ESTO ACTIVA EL MOCK PARA VER 30 USUARIOS
  return MockCompetenceRepository(); 
});

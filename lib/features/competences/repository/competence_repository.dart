// lib/features/competences/repository/competence_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/competences/model/ranking_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

// 1. Contrato (Define qué debe hacer el repositorio)
abstract class CompetenceRepository {
  Future<List<RankingModel>> fetchGlobalRanking(
    int languageId,
    int timeFilterId,
  );
}

// 2. Implementación Real con Supabase
class SupabaseCompetenceRepository implements CompetenceRepository {
  final SupabaseClient _supabase;
  SupabaseCompetenceRepository(this._supabase);

  @override
  Future<List<RankingModel>> fetchGlobalRanking(
    int languageId,
    int timeFilterId,
  ) async {
    try {
      final response = await _supabase.rpc(
        'get_global_ranking',
        params: {'p_language_id': languageId, 'p_time_filter_id': timeFilterId},
      );
      final rankingList = (response as List)
          .map((json) => RankingModel.fromJson(json))
          .toList();
      return rankingList;
    } catch (e) {
      throw Exception(
        'E_05: Error al cargar el ranking desde el servidor. ${e.toString()}',
      );
    }
  }
}

// 3. Implementación de Prueba (Mock) para desarrollo de UI
class MockCompetenceRepository implements CompetenceRepository {
  final Random _random = Random();

  @override
  Future<List<RankingModel>> fetchGlobalRanking(
    int languageId,
    int difficultyId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final List<RankingModel> ranking = [];

    // IDs reales para que las tarjetas de perfil funcionen en modo prueba
    const String currentUserUUID = '8777115a-572f-4f53-a5c7-cac3bbfe58c6';
    const String otherUserUUID = 'd9469641-ab01-4fe8-a0c0-67645b28ea56';

    for (int i = 1; i <= 30; i++) {
      String userId;
      String username;
      String profileName;

      if (i == 1) {
        // Usuario Top 1 de prueba
        userId = otherUserUUID;
        username = 'Usuario1';
        profileName = 'Competidor 1';
      } else if (i == 2) {
        // Tu usuario de prueba
        userId = currentUserUUID;
        username = 'dxniel7';
        profileName = 'Dxniel7';
      } else {
        // El resto de usuarios falsos
        userId = 'fake-id-$i';
        username = 'Usuario$i';
        profileName = 'Competidor $i';
      }

      int score = 5000 - (i * 100) + _random.nextInt(100);
      String rankName;

      if (score >= 4500) {
        rankName = 'Diamante';
      } else if (score >= 3500)
        rankName = 'Oro';
      else if (score >= 2000)
        rankName = 'Plata';
      else
        rankName = 'Bronce';

      ranking.add(
        RankingModel(
          userId: userId,
          username: username,
          profileName: profileName,
          avatarUrl:
              'assets/images/avatar_${i % 4 == 0
                  ? 'leon'
                  : i % 3 == 0
                  ? 'mono'
                  : 'tiburon'}.png',
          totalScore: score,
          rank: rankName,
          position: i,
        ),
      );
    }

    ranking.sort((a, b) => b.totalScore.compareTo(a.totalScore));
    for (int i = 0; i < ranking.length; i++) {
      ranking[i] = RankingModel(
        userId: ranking[i].userId,
        username: ranking[i].username,
        profileName: ranking[i].profileName,
        avatarUrl: ranking[i].avatarUrl,
        totalScore: ranking[i].totalScore,
        rank: ranking[i].rank,
        position: i + 1,
      );
    }
    return ranking;
  }
}

// 4. Provider de la Capa de Datos (El interruptor)
final competenceRepositoryProvider = Provider<CompetenceRepository>((ref) {
  // Para conectar a tu base de datos real:
  final supabaseClient = Supabase.instance.client;
  return SupabaseCompetenceRepository(supabaseClient);

  // Para diseñar la UI con datos de prueba (ignora la base de datos):
  // return MockCompetenceRepository();
});


// lib/features/competences/repository/competence_repository.dart

// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:kitsucode/features/competences/model/ranking_model.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'dart:math';

// // Contrato
// abstract class CompetenceRepository {
//   Future<List<RankingModel>> fetchGlobalRanking(int languageId, int difficultyId);
// }

// // Implementación de Mock (para debug con 30 usuarios)
// class MockCompetenceRepository implements CompetenceRepository {
//   final Random _random = Random();

//   @override
//   Future<List<RankingModel>> fetchGlobalRanking(int languageId, int difficultyId) async {
//     await Future.delayed(const Duration(milliseconds: 400));
//     final List<RankingModel> ranking = [];

//     for (int i = 1; i <= 30; i++) {
//       final isCurrentUser = i == 2;
//       final username = isCurrentUser ? 'dxniel7' : 'Usuario$i';
//       // --- AJUSTE CLAVE AQUÍ ---
//       // Si es el usuario actual, usa el nombre de perfil real, si no, el de competidor.
//       final profileName = isCurrentUser ? 'Dxniel7' : 'Competidor $i';
      
//       int score = 5000 - (i * 100) + _random.nextInt(100);
//       String rankName;

//       if (score >= 4500) rankName = 'Diamante';
//       else if (score >= 3500) rankName = 'Oro';
//       else if (score >= 2000) rankName = 'Plata';
//       else rankName = 'Bronce';

//       ranking.add(RankingModel(
//         userId: 'id_$i',
//         username: username,
//         profileName: profileName, // Usamos la variable con el nombre corregido
//         avatarUrl: 'assets/images/avatar_${i % 4 == 0 ? 'leon' : i % 3 == 0 ? 'mono' : 'tiburon'}.png',
//         totalScore: score,
//         rank: rankName,
//         position: i,
//       ));
//     }

//     ranking.sort((a, b) => b.totalScore.compareTo(a.totalScore));
//     for (int i = 0; i < ranking.length; i++) {
//       ranking[i] = RankingModel(
//         userId: ranking[i].userId,
//         username: ranking[i].username,
//         profileName: ranking[i].profileName,
//         avatarUrl: ranking[i].avatarUrl,
//         totalScore: ranking[i].totalScore,
//         rank: ranking[i].rank,
//         position: i + 1,
//       );
//     }

//     return ranking;
//   }
// }

// // 4. Provider de la Capa de Datos (SWITCH ACTIVO)
// final competenceRepositoryProvider = Provider<CompetenceRepository>((ref) {
//   // final supabaseClient = Supabase.instance.client;
//   // return SupabaseCompetenceRepository(supabaseClient); 
  
//   // 💡 ESTO ACTIVA EL MOCK PARA VER 30 USUARIOS
//   return MockCompetenceRepository(); 
// });

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/competences/model/ranking_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

abstract class CompetenceRepository {
  Future<List<RankingModel>> fetchGlobalRanking(
    int languageId,
    int timeFilterId,
  );
}

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

class MockCompetenceRepository implements CompetenceRepository {
  final Random _random = Random();

  @override
  Future<List<RankingModel>> fetchGlobalRanking(
    int languageId,
    int difficultyId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final List<RankingModel> ranking = [];

    const String currentUserUUID = '8777115a-572f-4f53-a5c7-cac3bbfe58c6';
    const String otherUserUUID = 'd9469641-ab01-4fe8-a0c0-67645b28ea56';

    for (int i = 1; i <= 30; i++) {
      String userId;
      String username;
      String profileName;

      if (i == 1) {
        userId = otherUserUUID;
        username = 'Usuario1';
        profileName = 'Competidor 1';
      } else if (i == 2) {
        userId = currentUserUUID;
        username = 'dxniel7';
        profileName = 'Dxniel7';
      } else {
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
          idAvatarSeleccionado: (i % 20) + 1,
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
        idAvatarSeleccionado: ranking[i].idAvatarSeleccionado,
        totalScore: ranking[i].totalScore,
        rank: ranking[i].rank,
        position: i + 1,
      );
    }
    return ranking;
  }
}

final competenceRepositoryProvider = Provider<CompetenceRepository>((ref) {
  final supabaseClient = Supabase.instance.client;
  return SupabaseCompetenceRepository(supabaseClient);
});

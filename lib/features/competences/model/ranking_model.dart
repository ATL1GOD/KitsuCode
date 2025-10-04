// lib/features/competences/model/ranking_model.dart

class RankingModel {
  final String userId;
  final String username;
  final String profileName;
  final String avatarUrl;
  final int totalScore; // Puntuación total (RN-04)
  final String rank;      // Rango (e.g., Bronce, Plata, Oro)
  final int position;   // Posición en el ranking (1, 2, 3...)

  RankingModel({
    required this.userId,
    required this.username,
    required this.profileName,
    required this.avatarUrl,
    required this.totalScore,
    required this.rank,
    required this.position,
  });

  // Método opcional para simular la creación desde un JSON de Supabase
  factory RankingModel.fromJson(Map<String, dynamic> json) {
    return RankingModel(
      userId: json['user_id'] as String,
      username: json['username'] as String,
      profileName: json['profile_name'] as String,
      avatarUrl: json['avatar_url'] as String,
      totalScore: json['total_score'] as int,
      rank: json['rank'] as String,
      position: json['position'] as int,
    );
  }
}
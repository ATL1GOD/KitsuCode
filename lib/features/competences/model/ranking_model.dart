// lib/features/competences/model/ranking_model.dart

class RankingModel {
  final String userId;
  final String username;
  final String profileName;
  final String avatarUrl;
  final int totalScore;
  final String rank;
  final int position;

  RankingModel({
    required this.userId,
    required this.username,
    required this.profileName,
    required this.avatarUrl,
    required this.totalScore,
    required this.rank,
    required this.position,
  });

  // --- fromJson ACTUALIZADO PARA SER MÁS SEGURO ---
  factory RankingModel.fromJson(Map<String, dynamic> json) {
    return RankingModel(
      userId: json['user_id'] ?? '', // Valor por defecto si es nulo
      username: json['username'] ?? 'N/A',
      profileName: json['profile_name'] ?? 'Usuario',
      avatarUrl: json['avatar_url'] ?? 'assets/images/login_zorro.png', // Avatar por defecto
      totalScore: (json['total_score'] ?? 0) as int,
      rank: json['rank'] ?? 'Bronce',
      position: (json['position'] ?? 0) as int,
    );
  }
}
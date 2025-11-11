// lib/features/competences/model/ranking_model.dart

class RankingModel {
  final String userId;
  final String username;
  final String profileName;
  final int idAvatarSeleccionado; // ✅ CAMBIADO de avatarUrl a idAvatarSeleccionado
  final int totalScore;
  final String rank;
  final int position;

  RankingModel({
    required this.userId,
    required this.username,
    required this.profileName,
    required this.idAvatarSeleccionado,
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
      // ✅ CAMBIADO: Ahora lee id_avatar_seleccionado en lugar de avatar_url
      idAvatarSeleccionado: json['id_avatar_seleccionado'] ?? 1, // Default: Zorro
      totalScore: (json['total_score'] ?? 0) as int,
      rank: json['rank'] ?? 'Bronce',
      position: (json['position'] ?? 0) as int,
    );
  }
}
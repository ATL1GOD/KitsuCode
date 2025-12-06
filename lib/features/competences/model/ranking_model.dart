class RankingModel {
  final String userId;
  final String username;
  final String profileName;
  final int idAvatarSeleccionado;
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

  factory RankingModel.fromJson(Map<String, dynamic> json) {
    return RankingModel(
      userId: json['user_id'] ?? '',
      username: json['username'] ?? 'N/A',
      profileName: json['profile_name'] ?? 'Usuario',

      idAvatarSeleccionado: json['id_avatar_seleccionado'] ?? 1,
      totalScore: (json['total_score'] ?? 0) as int,
      rank: json['rank'] ?? 'Bronce',
      position: (json['position'] ?? 0) as int,
    );
  }
}

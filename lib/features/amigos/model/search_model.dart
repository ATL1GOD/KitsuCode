class UserSearchPreviewModel {
  final String userId;
  final String nombrePerfil;
  final String nombreUsuario;
  final int idAvatarSeleccionado;
  final String rank;
  final List<int> rankLanguageIds;

  UserSearchPreviewModel({
    required this.userId,
    required this.nombrePerfil,
    required this.nombreUsuario,
    required this.idAvatarSeleccionado,
    required this.rank,
    required this.rankLanguageIds,
  });

  factory UserSearchPreviewModel.fromJson(Map<String, dynamic> json) {
    List<int> parseLanguageIds(dynamic ids) {
      if (ids is List) {
        return ids.map((id) => (id as num).toInt()).toList();
      }
      return [];
    }

    return UserSearchPreviewModel(
      userId: json['userId'] ?? '',
      nombrePerfil: json['nombrePerfil'] ?? 'Usuario',
      nombreUsuario: json['nombreUsuario'] ?? 'N/A',
      idAvatarSeleccionado:
          (json['idAvatarSeleccionado'] as num?)?.toInt() ?? 1,
      rank: json['rank'] ?? 'Bronce',
      rankLanguageIds: parseLanguageIds(json['rankLanguageIds']),
    );
  }
}

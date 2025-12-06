class FollowListModel {
  final String userId;
  final String nombreUsuario;
  final String nombrePerfil;
  final int idAvatarSeleccionado;
  final bool isFollowing;

  FollowListModel({
    required this.userId,
    required this.nombreUsuario,
    required this.nombrePerfil,
    required this.idAvatarSeleccionado,
    required this.isFollowing,
  });

  factory FollowListModel.fromJson(Map<String, dynamic> json) {
    return FollowListModel(
      userId: json['user_id'],
      nombreUsuario: json['nombre_usuario'] ?? 'N/A',
      nombrePerfil: json['nombre_perfil'] ?? 'Sin Nombre',

      idAvatarSeleccionado: json['id_avatar_seleccionado'] ?? 1,

      isFollowing: json['is_following'] ?? false,
    );
  }

  FollowListModel copyWith({
    String? userId,
    String? nombreUsuario,
    String? nombrePerfil,
    int? idAvatarSeleccionado,
    bool? isFollowing,
  }) {
    return FollowListModel(
      userId: userId ?? this.userId,
      nombreUsuario: nombreUsuario ?? this.nombreUsuario,
      nombrePerfil: nombrePerfil ?? this.nombrePerfil,
      idAvatarSeleccionado: idAvatarSeleccionado ?? this.idAvatarSeleccionado,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }
}

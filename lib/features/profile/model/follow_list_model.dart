class FollowListModel {
  final String userId;
  final String nombreUsuario;
  final String nombrePerfil;
  final int idAvatarSeleccionado; // ✅ CAMBIADO de avatarUrl a idAvatarSeleccionado
  final bool isFollowing; // Indica si el usuario que ve la lista sigue a este perfil.

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
      // ✅ CAMBIADO: Ahora lee id_avatar_seleccionado en lugar de avatar_url
      idAvatarSeleccionado: json['id_avatar_seleccionado'] ?? 1, // Default: Zorro
      // Se asume que el backend devuelve un booleano para el estado de seguimiento.
      isFollowing: json['is_following'] ?? false, 
    );
  }

  // Método para clonar y modificar instancias, útil para actualizar el estado de 'isFollowing'
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
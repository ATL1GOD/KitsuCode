class FollowListModel {
  final String userId;
  final String nombreUsuario;
  final String nombrePerfil;
  final String avatarUrl;
  final bool isFollowing; // Indica si el usuario que ve la lista sigue a este perfil.

  FollowListModel({
    required this.userId,
    required this.nombreUsuario,
    required this.nombrePerfil,
    required this.avatarUrl,
    required this.isFollowing,
  });

  factory FollowListModel.fromJson(Map<String, dynamic> json) {
    return FollowListModel(
      userId: json['user_id'],
      nombreUsuario: json['nombre_usuario'] ?? 'N/A',
      nombrePerfil: json['nombre_perfil'] ?? 'Sin Nombre',
      // Se asume que el backend devuelve un valor predeterminado o un URL válido.
      avatarUrl: json['avatar_url'] ?? 'assets/images/login_zorro.png',
      // Se asume que el backend devuelve un booleano para el estado de seguimiento.
      isFollowing: json['is_following'] ?? false, 
    );
  }

  // Método para clonar y modificar instancias, útil para actualizar el estado de 'isFollowing'
  FollowListModel copyWith({
    String? userId,
    String? nombreUsuario,
    String? nombrePerfil,
    String? avatarUrl,
    bool? isFollowing,
  }) {
    return FollowListModel(
      userId: userId ?? this.userId,
      nombreUsuario: nombreUsuario ?? this.nombreUsuario,
      nombrePerfil: nombrePerfil ?? this.nombrePerfil,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }
}
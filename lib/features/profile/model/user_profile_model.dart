class UserProfileModel {
  final String userId;
  final String nombreUsuario;
  final String correo;
  final String nombrePerfil;
  final String avatarUrl;
  final int siguiendoCount;  
  final int seguidoresCount; 
  final int cambiosAvatarHoy;
  final int cambiosNombrePerfilEsteMes;

  UserProfileModel({
    required this.userId,
    required this.nombreUsuario,
    required this.correo,
    required this.nombrePerfil,
    required this.avatarUrl,
    required this.siguiendoCount,
    required this.seguidoresCount, 
    required this.cambiosAvatarHoy,
    required this.cambiosNombrePerfilEsteMes,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      userId: json['id'],
      nombreUsuario: json['nombre_usuario'] ?? 'N/A',
      correo: json['correo'] ?? 'Sin correo',
      nombrePerfil: json['nombre_perfil'] ?? 'Sin Nombre',
      avatarUrl: json['avatar_url'] ?? 'assets/images/login_zorro.png',
      
      siguiendoCount: json['siguiendo_count'] ?? 0,
      seguidoresCount: json['seguidores_count'] ?? 0, 
      cambiosAvatarHoy: json['cambios_avatar_hoy'] ?? 0,
      cambiosNombrePerfilEsteMes: json['cambios_nombre_perfil_este_mes'] ?? 0
    );
  }

  // Método para clonar y modificar instancias
  UserProfileModel copyWith({
    String? userId,
    String? nombreUsuario,
    String? correo,
    String? nombrePerfil,
    String? avatarUrl,
    int? siguiendoCount,
    int? seguidoresCount,
    int? cambiosAvatarHoy,
    int? cambiosNombrePerfilEsteMes,
  }) {
    return UserProfileModel(
      userId: userId ?? this.userId,
      nombreUsuario: nombreUsuario ?? this.nombreUsuario,
      correo: correo ?? this.correo,
      nombrePerfil: nombrePerfil ?? this.nombrePerfil,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      siguiendoCount: siguiendoCount ?? this.siguiendoCount,
      seguidoresCount: seguidoresCount ?? this.seguidoresCount,
      cambiosAvatarHoy: cambiosAvatarHoy ?? this.cambiosAvatarHoy,
      cambiosNombrePerfilEsteMes: cambiosNombrePerfilEsteMes ?? this.cambiosNombrePerfilEsteMes,
    );
  }
}
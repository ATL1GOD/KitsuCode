class UserProfileModel {
  final String userId;
  final String nombreUsuario;
  final String correo;
  final String nombrePerfil;
  final int idAvatarSeleccionado; // ¡CAMBIO! Ahora es int en lugar de String
  final int siguiendoCount;  
  final int seguidoresCount; 
  final int cambiosAvatarHoy;
  final int cambiosNombrePerfilEsteMes;

  UserProfileModel({
    required this.userId,
    required this.nombreUsuario,
    required this.correo,
    required this.nombrePerfil,
    required this.idAvatarSeleccionado,
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
      idAvatarSeleccionado: json['id_avatar_seleccionado'] ?? 1, // Default: Zorro
      
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
    int? idAvatarSeleccionado,
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
      idAvatarSeleccionado: idAvatarSeleccionado ?? this.idAvatarSeleccionado,
      siguiendoCount: siguiendoCount ?? this.siguiendoCount,
      seguidoresCount: seguidoresCount ?? this.seguidoresCount,
      cambiosAvatarHoy: cambiosAvatarHoy ?? this.cambiosAvatarHoy,
      cambiosNombrePerfilEsteMes: cambiosNombrePerfilEsteMes ?? this.cambiosNombrePerfilEsteMes,
    );
  }
}
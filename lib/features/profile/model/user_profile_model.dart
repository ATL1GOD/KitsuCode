class UserProfileModel {
  final String userId;
  final String nombreUsuario;
  final String correo;
  final String nombrePerfil;
  final int idAvatarSeleccionado;
  final int siguiendoCount;
  final int seguidoresCount;
  final int cambiosAvatarHoy;
  final int cambiosNombrePerfilEsteMes;
  final int nivelConocimiento;
  final bool onboardingCompletado;
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
    required this.nivelConocimiento,
    required this.onboardingCompletado,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      userId: json['id'] as String,
      nombreUsuario: json['nombre_usuario'] as String? ?? '',
      correo: json['correo'] ?? 'Sin correo',
      nombrePerfil: json['nombre_perfil'] as String? ?? '',
      idAvatarSeleccionado: json['id_avatar_seleccionado'] as int? ?? 1,
      siguiendoCount: json['siguiendo_count'] ?? 0,
      seguidoresCount: json['seguidores_count'] ?? 0,
      cambiosAvatarHoy: json['cambios_avatar_hoy'] ?? 0,
      cambiosNombrePerfilEsteMes: json['cambios_nombre_perfil_este_mes'] ?? 0,
      nivelConocimiento: json['nivel_conocimiento'] as int? ?? 0,
      onboardingCompletado: json['onboarding_completado'] as bool? ?? false,
    );
  }

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
    int? nivelConocimiento,
    bool? onboardingCompletado,
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
      cambiosNombrePerfilEsteMes:
          cambiosNombrePerfilEsteMes ?? this.cambiosNombrePerfilEsteMes,
      nivelConocimiento: nivelConocimiento ?? this.nivelConocimiento,
      onboardingCompletado: onboardingCompletado ?? this.onboardingCompletado,
    );
  }
}

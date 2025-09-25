// lib/features/profile/model/user_profile_model.dart

class UserProfileModel {
  final String userId;
  final String nombreUsuario;
  final String nombrePerfil;
  final String avatarUrl;
  final int siguiendoCount;
  final int seguidoresCount;

  UserProfileModel({
    required this.userId,
    required this.nombreUsuario,
    required this.nombrePerfil,
    required this.avatarUrl,
    required this.siguiendoCount,
    required this.seguidoresCount,
  });

  // NUEVO: Método copyWith
  // Nos permite crear una copia del perfil actualizando solo los campos que necesitamos.
  UserProfileModel copyWith({
    String? userId,
    String? nombreUsuario,
    String? nombrePerfil,
    String? avatarUrl,
    int? siguiendoCount,
    int? seguidoresCount,
  }) {
    return UserProfileModel(
      userId: userId ?? this.userId,
      nombreUsuario: nombreUsuario ?? this.nombreUsuario,
      nombrePerfil: nombrePerfil ?? this.nombrePerfil,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      siguiendoCount: siguiendoCount ?? this.siguiendoCount,
      seguidoresCount: seguidoresCount ?? this.seguidoresCount,
    );
  }
}
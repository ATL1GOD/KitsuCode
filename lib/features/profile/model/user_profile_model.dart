// lib/features/profile/model/user_profile_model.dart

class UserProfileModel {
  final String userId;
  final String nombreUsuario;
  final String correo;
  final String nombrePerfil;
  final String avatarUrl;
  final int siguiendoCount;  // <-- NUEVO
  final int seguidoresCount; // <-- NUEVO

  UserProfileModel({
    required this.userId,
    required this.nombreUsuario,
    required this.correo,
    required this.nombrePerfil,
    required this.avatarUrl,
    required this.siguiendoCount, // <-- NUEVO
    required this.seguidoresCount, // <-- NUEVO
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      userId: json['id'],
      nombreUsuario: json['nombre_usuario'] ?? 'N/A',
      correo: json['correo'] ?? 'Sin correo',
      nombrePerfil: json['nombre_perfil'] ?? 'Sin Nombre',
      avatarUrl: json['avatar_url'] ?? 'assets/images/login_zorro.png',
      // Mapeamos los nuevos contadores que vienen de la función
      siguiendoCount: json['siguiendo_count'] ?? 0, // <-- NUEVO
      seguidoresCount: json['seguidores_count'] ?? 0, // <-- NUEVO
    );
  }
}
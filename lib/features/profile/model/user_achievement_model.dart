// lib/features/profile/model/user_achievement_model.dart

class UserAchievementModel {
  final int id;
  final String nombre;
  final String descripcion;
  final String iconUrl; 
  final bool obtenido;

  UserAchievementModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.iconUrl,
    required this.obtenido,
  });
  
  factory UserAchievementModel.fromJson(Map<String, dynamic> json) {
    // La función RPC de Supabase nos da los nombres de columna en minúsculas
    return UserAchievementModel(
      id: json['id'], 
      nombre: json['nombre'] ?? 'Logro',
      descripcion: json['descripcion'] ?? 'Sin descripción',
      // 'iconurl' es el alias que definimos en la función RPC
      iconUrl: json['iconurl'] ?? 'assets/images/zorro_oops.png', 
      obtenido: json['obtenido'] ?? false,
    );
  }
}
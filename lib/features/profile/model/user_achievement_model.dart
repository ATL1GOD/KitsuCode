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
    // La función RPC nos da los nombres de columna en minúsculas
    return UserAchievementModel(
      id: json['id'], 
      nombre: json['nombre'] ?? 'Logro',
      descripcion: json['descripcion'] ?? 'Sin descripción',
      // 'iconurl' es el alias 'AS iconUrl' que definimos en la función RPC
      // Supabase lo convierte a minúsculas.
      iconUrl: json['iconurl'] ?? 'assets/images/zorro_oops.png', 
      // 'obtenido' es el booleano que la RPC calcula por nosotros
      obtenido: json['obtenido'] ?? false,
    );
  }
}
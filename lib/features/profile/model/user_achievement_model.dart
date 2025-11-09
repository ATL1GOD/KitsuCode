// lib/features/profile/model/user_achievement_model.dart

class UserAchievementModel {
  final int id;
  final String nombre;
  final String descripcion;
  final String iconUrl; 
  final bool obtenido;
  final String raridad; // <-- ¡NUEVO CAMPO!

  UserAchievementModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.iconUrl,
    required this.obtenido,
    required this.raridad, // <-- ¡NUEVO EN CONSTRUCTOR!
  });
  
  factory UserAchievementModel.fromJson(Map<String, dynamic> json) {
    return UserAchievementModel(
      id: json['id'], 
      nombre: json['nombre'] ?? 'Logro',
      descripcion: json['descripcion'] ?? 'Sin descripción',
      iconUrl: json['iconurl'] ?? 'assets/images/zorro_oops.png', 
      obtenido: json['obtenido'] ?? false,
      raridad: json['raridad'] ?? 'Común', // <-- ¡NUEVO PARSEO!
    );
  }
}
// lib/features/profile/model/user_achievement_model.dart

class UserAchievementModel {
  final int id;
  final String nombre;
  final String descripcion;
  // Podríamos añadir un campo para el icono si lo guardas en la BD
  // final String iconUrl; 

  UserAchievementModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
  });

  factory UserAchievementModel.fromJson(Map<String, dynamic> json) {
    // La consulta unirá las tablas, así que los datos vendrán juntos
    return UserAchievementModel(
      id: json['id_logro'],
      nombre: json['nombre'] ?? 'Logro',
      descripcion: json['descripcion'] ?? 'Sin descripción',
    );
  }
}
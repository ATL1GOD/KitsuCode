class UserAchievementModel {
  final int id;
  final String nombre;
  final String descripcion;
  // Creo podriamos añadir un campo para el icono 
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
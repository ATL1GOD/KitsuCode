// class UserAchievementModel {
//   final int id;
//   final String nombre;
//   final String descripcion;
//   // Creo podriamos añadir un campo para el icono 
//   // final String iconUrl; 

//   UserAchievementModel({
//     required this.id,
//     required this.nombre,
//     required this.descripcion,
//   });
  
//   factory UserAchievementModel.fromJson(Map<String, dynamic> json) {
//     // La consulta unirá las tablas, así que los datos vendrán juntos
//     return UserAchievementModel(
//       id: json['id_logro'],
//       nombre: json['nombre'] ?? 'Logro',
//       descripcion: json['descripcion'] ?? 'Sin descripción',
//     );
//   }
// }


// lib/features/profile/model/user_achievement_model.dart nuevo modelo, aun necesito verificarlo 

class UserAchievementModel {
  final int id;
  final String nombre;
  final String descripcion;
  // --- CAMBIOS AQUÍ: Se añadieron los campos que faltaban ---
  final String iconUrl; 
  final bool obtenido;

  UserAchievementModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.iconUrl, // Requerido en el constructor
    required this.obtenido,  // Requerido en el constructor
  });
  
  factory UserAchievementModel.fromJson(Map<String, dynamic> json) {
    return UserAchievementModel(
      // Asumo que el ID del logro viene como 'id' desde la tabla 'logro'
      id: json['id'], 
      nombre: json['nombre'] ?? 'Logro',
      descripcion: json['descripcion'] ?? 'Sin descripción',
      // Asumo que el icono viene como 'icono'
      iconUrl: json['icono'] ?? 'assets/images/zorro_oops.png', 
      // La presencia de 'usuario_logro' indica que fue obtenido
      obtenido: json['usuario_logro'] != null && (json['usuario_logro'] as List).isNotEmpty,
    );
  }
}
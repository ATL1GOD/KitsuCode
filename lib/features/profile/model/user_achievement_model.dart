class UserAchievementModel {
  final int id;
  final String nombre;
  final String descripcion;
  final String iconUrl;
  final bool obtenido;
  final String raridad;

  UserAchievementModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.iconUrl,
    required this.obtenido,
    required this.raridad,
  });

  factory UserAchievementModel.fromJson(Map<String, dynamic> json) {
    return UserAchievementModel(
      id: json['id'],
      nombre: json['nombre'] ?? 'Logro',
      descripcion: json['descripcion'] ?? 'Sin descripción',
      iconUrl: json['iconurl'] ?? 'assets/images/zorro_oops.png',
      obtenido: json['obtenido'] ?? false,
      raridad: json['raridad'] ?? 'Común',
    );
  }
}

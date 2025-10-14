class UserStatsModel {
  final int retosCompletados;
  final double porcentajeAciertos;
  final double porcentajeFallos; 
  final int rachaDias;

  UserStatsModel({
    required this.retosCompletados,
    required this.porcentajeAciertos,
    required this.porcentajeFallos,
    required this.rachaDias,
  });

  // El valor por defecto si no se encuentran estadísticas para el usuario
  factory UserStatsModel.empty() {
    return UserStatsModel(
      retosCompletados: 0,
      porcentajeAciertos: 0.0,
      porcentajeFallos: 0.0,
      rachaDias: 0,
    );
  }

  factory UserStatsModel.fromJson(Map<String, dynamic> json) {
    return UserStatsModel(
      retosCompletados: json['retos_completados'] ?? 0,
      porcentajeAciertos: (json['porcentaje_aciertos'] as num?)?.toDouble() ?? 0.0,
      // Mapeamos la nueva columna de la base de datos
      porcentajeFallos: (json['porcentaje_fallos'] as num?)?.toDouble() ?? 0.0,
      rachaDias: json['racha_dias'] ?? 0,
    );
  }
}
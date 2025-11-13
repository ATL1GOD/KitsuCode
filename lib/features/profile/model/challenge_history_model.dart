// lib/features/profile/model/challenge_history_model.dart

class ChallengeHistoryModel {
  final String challengeTitle;
  final String sectionTitle;
  final String dinamicaNombre; // <-- AÑADIDO
  final DateTime completedAt;
  final int xpGained;

  ChallengeHistoryModel({
    required this.challengeTitle,
    required this.sectionTitle,
    required this.dinamicaNombre, // <-- AÑADIDO
    required this.completedAt,
    required this.xpGained,
  });

  factory ChallengeHistoryModel.fromJson(Map<String, dynamic> json) {
    // Usamos el alias 'reto' que pusimos en la consulta
    final retoData = json['reto'] as Map<String, dynamic>?;

    // Info de Sección (sin cambios)
    final nivelesList = retoData?['niveles'] as List? ?? [];
    final seccionData = nivelesList.isNotEmpty
        ? nivelesList.first['secciones'] as Map<String, dynamic>?
        : null;
    final seccionTitulo = seccionData?['titulo'] as String? ?? 'General';

    // Info de Dinámica (nuevo)
    // Usamos el alias 'dinamicas' que pusimos en la consulta
    final dinamicaData = retoData?['dinamicas'] as Map<String, dynamic>?;
    final dinamicaNombre = dinamicaData?['nombre'] as String? ?? 'Desconocida';

    return ChallengeHistoryModel(
      challengeTitle: retoData?['titulo'] as String? ?? 'Reto Desconocido',
      sectionTitle: seccionTitulo,
      dinamicaNombre: dinamicaNombre, // <-- AÑADIDO
      completedAt: DateTime.parse(json['fecha_intento'] as String),
      xpGained: json['experiencia_obtenida'] as int? ?? 0,
    );
  }
}
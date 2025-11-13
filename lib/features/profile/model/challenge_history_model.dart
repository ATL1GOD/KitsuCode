// lib/features/profile/model/challenge_history_model.dart

class ChallengeHistoryModel {
  final String challengeTitle;
  final String sectionTitle;
  final String dinamicaNombre;
  final DateTime completedAt;
  final int xpGained;
  final String resultado; // <-- 1. AÑADE ESTA LÍNEA

  ChallengeHistoryModel({
    required this.challengeTitle,
    required this.sectionTitle,
    required this.dinamicaNombre,
    required this.completedAt,
    required this.xpGained,
    required this.resultado, // <-- 2. AÑADE ESTA LÍNEA
  });

  factory ChallengeHistoryModel.fromJson(Map<String, dynamic> json) {
    // ... (el parseo de retoData, seccionData, dinamicaData no cambia)
    final retoData = json['reto'] as Map<String, dynamic>?;
    final nivelesList = retoData?['niveles'] as List? ?? [];
    final seccionData = nivelesList.isNotEmpty
        ? nivelesList.first['secciones'] as Map<String, dynamic>?
        : null;
    final seccionTitulo = seccionData?['titulo'] as String? ?? 'General';
    final dinamicaData = retoData?['dinamicas'] as Map<String, dynamic>?;
    final dinamicaNombre = dinamicaData?['nombre'] as String? ?? 'Desconocida';

    return ChallengeHistoryModel(
      challengeTitle: retoData?['titulo'] as String? ?? 'Reto Desconocido',
      sectionTitle: seccionTitulo,
      dinamicaNombre: dinamicaNombre,
      completedAt: DateTime.parse(json['fecha_intento'] as String),
      xpGained: json['experiencia_obtenida'] as int? ?? 0,
      resultado: json['resultado'] as String? ?? 'fallido', // <-- 3. AÑADE ESTA LÍNEA
    );
  }
}
// --- NUEVO: Importación para el modelo de recursos ---
import 'package:kitsucode/features/challenge/view/feedback/challenge_failure_view.dart' show RecursoModel;

// Representa el reto completo parseado desde el JSON
class ColumnsChallenge {
  final List<ColumnPair> pares;
  // --- NUEVO ---
  final List<RecursoModel> recursos;

  ColumnsChallenge({
    required this.pares,
    required this.recursos, // <-- AÑADIDO
  });

  factory ColumnsChallenge.fromJson(Map<String, dynamic> json) {
    var paresList = json['pares'] as List;
    List<ColumnPair> pares = paresList
        .map((i) => ColumnPair.fromJson(i as Map<String, dynamic>))
        .toList();

    // --- NUEVA LÓGICA DE RECURSOS ---
    final List<dynamic> recursosJson = json['recursos'] as List<dynamic>? ?? [];
    final List<RecursoModel> recursosList = recursosJson
        .map((r) => RecursoModel.fromJson(r as Map<String, dynamic>))
        .toList();
    // --- FIN NUEVA LÓGICA ---

    return ColumnsChallenge(
      pares: pares,
      recursos: recursosList, // <-- AÑADIDO
    );
  }
}

// Representa un solo par del JSON
class ColumnPair {
// ... (El resto de tu archivo 'columnas_model.dart' no cambia) ...
  final int id;
  final String termino;
  final String definicion;

  ColumnPair({
    required this.id,
    required this.termino,
    required this.definicion,
  });

  factory ColumnPair.fromJson(Map<String, dynamic> json) {
    return ColumnPair(
      id: json['id'] as int,
      termino: json['termino'] as String,
      definicion: json['definicion'] as String,
    );
  }
}

// --- Modelos internos para la UI ---

// Representa una "burbuja" individual en la pantalla
class ChallengeItem {
  final int pairId; // El ID del par al que pertenece (ej: 1, 2, 3, 4)
  final String text;
  final ItemType type; // Si es 'termino' o 'definicion'

  ChallengeItem({required this.pairId, required this.text, required this.type});
}

enum ItemType { termino, definicion }
// --- NUEVO: Importación para el modelo de recursos ---
import 'package:kitsucode/features/challenge/view/feedback/challenge_failure_view.dart' show RecursoModel;

class CodigoChallenge {
  final List<CodigoPregunta> preguntas;
  // --- NUEVO ---
  final List<RecursoModel> recursos;

  CodigoChallenge({
    required this.preguntas,
    required this.recursos, // <-- AÑADIDO
  });

  factory CodigoChallenge.fromJson(Map<String, dynamic> json) {
    if (json['preguntas'] == null || json['preguntas'] is! List) {
      throw FormatException(
        "El JSON no contiene una lista de 'preguntas' válida.",
      );
    }

    final List<dynamic> preguntasList = json['preguntas'];

    // --- NUEVA LÓGICA DE RECURSOS ---
    final List<dynamic> recursosJson = json['recursos'] as List<dynamic>? ?? [];
    final List<RecursoModel> recursosList = recursosJson
        .map((r) => RecursoModel.fromJson(r as Map<String, dynamic>))
        .toList();
    // --- FIN NUEVA LÓGICA ---

    return CodigoChallenge(
      preguntas: preguntasList
          .map((p) => CodigoPregunta.fromJson(p as Map<String, dynamic>))
          .toList(),
      recursos: recursosList, // <-- AÑADIDO
    );
  }
}

// --- ¡MODIFICADO! ---
// Modelo para cada pregunta
class CodigoPregunta {
  // ... (El resto de esta clase no cambia) ...
// ... (El resto de tu archivo 'codigo_model.dart' no cambia) ...
  final String instruccion;
  final List<CodigoFragmento> fragmentos; // <-- CAMBIO

  CodigoPregunta({
    required this.instruccion,
    required this.fragmentos, // <-- CAMBIO
  });

  factory CodigoPregunta.fromJson(Map<String, dynamic> json) {
    if (json['instruccion'] == null ||
        json['fragmentos'] == null ||
        json['fragmentos'] is! List) {
      throw FormatException(
        "La pregunta JSON no contiene 'instruccion' o 'fragmentos' válidos.",
      );
    }

    final List<dynamic> fragmentosList = json['fragmentos'];

    return CodigoPregunta(
      instruccion: json['instruccion'] as String,
      fragmentos:
          fragmentosList // <-- CAMBIO
              .map((f) => CodigoFragmento.fromJson(f as Map<String, dynamic>))
              .toList(),
    );
  }
}

// --- ¡NUEVO! ---
// Modelo para cada fragmento (texto o input)
class CodigoFragmento {
  final String tipo; // "texto" o "input"
  final String valor; // El texto a mostrar o la respuesta correcta

  CodigoFragmento({required this.tipo, required this.valor});

  factory CodigoFragmento.fromJson(Map<String, dynamic> json) {
    if (json['tipo'] == null || json['valor'] == null) {
      throw FormatException("El fragmento JSON no contiene 'tipo' o 'valor'.");
    }
    return CodigoFragmento(
      tipo: json['tipo'] as String,
      valor: json['valor'] as String,
    );
  }
}
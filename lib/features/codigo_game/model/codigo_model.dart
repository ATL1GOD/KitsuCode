import 'package:kitsucode/features/challenge/view/feedback/challenge_failure_view.dart'
    show RecursoModel;

class CodigoChallenge {
  final List<CodigoPregunta> preguntas;

  final List<RecursoModel> recursos;

  CodigoChallenge({required this.preguntas, required this.recursos});

  factory CodigoChallenge.fromJson(Map<String, dynamic> json) {
    if (json['preguntas'] == null || json['preguntas'] is! List) {
      throw FormatException(
        "El JSON no contiene una lista de 'preguntas' válida.",
      );
    }

    final List<dynamic> preguntasList = json['preguntas'];

    final List<dynamic> recursosJson = json['recursos'] as List<dynamic>? ?? [];
    final List<RecursoModel> recursosList = recursosJson
        .map((r) => RecursoModel.fromJson(r as Map<String, dynamic>))
        .toList();

    return CodigoChallenge(
      preguntas: preguntasList
          .map((p) => CodigoPregunta.fromJson(p as Map<String, dynamic>))
          .toList(),
      recursos: recursosList,
    );
  }
}

class CodigoPregunta {
  final String instruccion;
  final List<CodigoFragmento> fragmentos;

  CodigoPregunta({required this.instruccion, required this.fragmentos});

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
      fragmentos: fragmentosList
          .map((f) => CodigoFragmento.fromJson(f as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CodigoFragmento {
  final String tipo;
  final String valor;

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

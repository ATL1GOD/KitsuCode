// lib/features/codigo_game/model/codigo_model.dart

import 'dart:convert';

// Modelo principal que recibirá el loader
class CodigoChallenge {
  final List<CodigoPregunta> preguntas;

  CodigoChallenge({required this.preguntas});

  factory CodigoChallenge.fromJson(Map<String, dynamic> json) {
    // Validamos que 'preguntas' exista y sea una lista
    if (json['preguntas'] == null || json['preguntas'] is! List) {
      throw FormatException(
        "El JSON no contiene una lista de 'preguntas' válida.",
      );
    }

    // Parseamos la lista de preguntas
    final List<dynamic> preguntasList = json['preguntas'];

    return CodigoChallenge(
      preguntas: preguntasList
          .map((p) => CodigoPregunta.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}

// Modelo para cada ítem individual del reto
class CodigoPregunta {
  final String instruccion;
  final String texto_antes;
  final String texto_despues;
  final String respuesta_correcta;

  CodigoPregunta({
    required this.instruccion,
    required this.texto_antes,
    required this.texto_despues,
    required this.respuesta_correcta,
  });

  factory CodigoPregunta.fromJson(Map<String, dynamic> json) {
    // Validamos que todos los campos existan
    final requiredKeys = [
      'instruccion',
      'texto_antes',
      'texto_despues',
      'respuesta_correcta',
    ];
    for (var key in requiredKeys) {
      if (json[key] == null || json[key] is! String) {
        throw FormatException("La pregunta JSON no contiene un '$key' válido.");
      }
    }

    return CodigoPregunta(
      instruccion: json['instruccion'] as String,
      texto_antes: json['texto_antes'] as String,
      texto_despues: json['texto_despues'] as String,
      respuesta_correcta: json['respuesta_correcta'] as String,
    );
  }
}

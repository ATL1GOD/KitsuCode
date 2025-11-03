// lib/features/puzzle_game/model/puzzle_challenge_model.dart (CORREGIDO)

import 'dart:convert';
import 'package:flutter/material.dart'; // ¡Necesario para UniqueKey!

PuzzleChallengeModel puzzleChallengeModelFromJson(String str) =>
    PuzzleChallengeModel.fromJson(json.decode(str));

class PuzzleChallengeModel {
  final String instruction;
  final List<PuzzleLine> lines;
  final List<PuzzleOption> options;

  PuzzleChallengeModel({
    required this.instruction,
    required this.lines,
    required this.options,
  });

  factory PuzzleChallengeModel.fromJson(Map<String, dynamic> json) {
    if (json['instruction'] == null || json['lines'] == null || json['options'] == null) {
      throw Exception("El JSON del puzzle no tiene el formato esperado (falta 'instruction', 'lines' u 'options')");
    }
    
    return PuzzleChallengeModel(
      instruction: json['instruction'] as String,
      lines: (json['lines'] as List)
          .map((lineJson) => PuzzleLine.fromJson(lineJson))
          .toList(),
      options: (json['options'] as List)
          .map((optionJson) => PuzzleOption.fromJson(optionJson))
          .toList(),
    );
  }
}

// --- CLASES DE LÍNEAS (Sin cambios) ---
abstract class PuzzleLine {
  final String type;
  PuzzleLine(this.type);

  factory PuzzleLine.fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'code':
        return TokenLine.fromJson(json, 'normal');
      case 'token':
        return TokenLine.fromJson(json, json['highlight'] ?? 'normal');
      case 'blank':
        return BlankLine.fromJson(json);
      default:
        throw Exception('Tipo de línea desconocido: ${json['type']}');
    }
  }
}

class TokenLine extends PuzzleLine {
  final String text;
  final String highlight; 

  TokenLine({
    required this.text, 
    required this.highlight,
  }) : super('token'); 

  factory TokenLine.fromJson(Map<String, dynamic> json, String highlightType) {
    return TokenLine(
      text: json['text'] ?? '',
      highlight: highlightType,
    );
  }
}

class BlankLine extends PuzzleLine {
  final String id; 
  final String correctOptionId;
  
  BlankLine({required this.id, required this.correctOptionId}) : super('blank');

  factory BlankLine.fromJson(Map<String, dynamic> json) {
    return BlankLine(
      id: json['id'] ?? (throw Exception("El 'blank' no tiene id")),
      correctOptionId: json['correct_option_id'] ?? (throw Exception("El 'blank' no tiene correct_option_id")),
    );
  }
}

// --- CLASE PuzzleOption (¡CORREGIDA!) ---
class PuzzleOption {
  final String id; // El ID semántico (ej: "opt_A")
  final String text;
  
  // ¡NUEVO CAMPO! Un ID único para esta *instancia* de ficha
  final String uniqueId; 

  PuzzleOption({
    required this.id, 
    required this.text,
    String? uniqueId, // Opcional para el constructor
  }) : uniqueId = uniqueId ?? UniqueKey().toString(); // Asigna un ID de instancia único

  factory PuzzleOption.fromJson(Map<String, dynamic> json) {
    return PuzzleOption(
      id: json['id'] ?? (throw Exception("La 'option' no tiene id")),
      text: json['text'] ?? '',
      // El 'uniqueId' será asignado automáticamente por el constructor
    );
  }

  // ¡CORREGIDO! Ahora compara por 'uniqueId', no por 'id'
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PuzzleOption &&
          runtimeType == other.runtimeType &&
          uniqueId == other.uniqueId; // <-- ¡CAMBIO CLAVE!

  // ¡CORREGIDO! El hashCode debe basarse en lo mismo que 'operator=='
  @override
  int get hashCode => uniqueId.hashCode; // <-- ¡CAMBIO CLAVE!
}
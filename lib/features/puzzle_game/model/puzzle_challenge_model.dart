import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:kitsucode/features/challenge/view/feedback/challenge_failure_view.dart'
    show RecursoModel;

PuzzleChallengeModel puzzleChallengeModelFromJson(String str) =>
    PuzzleChallengeModel.fromJson(json.decode(str));

class PuzzleChallengeModel {
  final String instruction;
  final List<PuzzleLine> lines;
  final List<PuzzleOption> options;

  final List<RecursoModel> recursos;

  PuzzleChallengeModel({
    required this.instruction,
    required this.lines,
    required this.options,
    required this.recursos,
  });

  factory PuzzleChallengeModel.fromJson(Map<String, dynamic> json) {
    if (json['instruction'] == null ||
        json['lines'] == null ||
        json['options'] == null) {
      throw Exception(
        "El JSON del puzzle no tiene el formato esperado (falta 'instruction', 'lines' u 'options')",
      );
    }

    final List<dynamic> recursosJson = json['recursos'] as List<dynamic>? ?? [];
    final List<RecursoModel> recursosList = recursosJson
        .map((r) => RecursoModel.fromJson(r as Map<String, dynamic>))
        .toList();

    return PuzzleChallengeModel(
      instruction: json['instruction'] as String,
      lines: (json['lines'] as List)
          .map((lineJson) => PuzzleLine.fromJson(lineJson))
          .toList(),
      options: (json['options'] as List)
          .map((optionJson) => PuzzleOption.fromJson(optionJson))
          .toList(),
      recursos: recursosList,
    );
  }
}

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

  TokenLine({required this.text, required this.highlight}) : super('token');

  factory TokenLine.fromJson(Map<String, dynamic> json, String highlightType) {
    return TokenLine(text: json['text'] ?? '', highlight: highlightType);
  }
}

class BlankLine extends PuzzleLine {
  final String id;
  final String correctOptionId;

  BlankLine({required this.id, required this.correctOptionId}) : super('blank');

  factory BlankLine.fromJson(Map<String, dynamic> json) {
    return BlankLine(
      id: json['id'] ?? (throw Exception("El 'blank' no tiene id")),
      correctOptionId:
          json['correct_option_id'] ??
          (throw Exception("El 'blank' no tiene correct_option_id")),
    );
  }
}

class PuzzleOption {
  final String id;
  final String text;

  final String uniqueId;

  PuzzleOption({required this.id, required this.text, String? uniqueId})
    : uniqueId = uniqueId ?? UniqueKey().toString();

  factory PuzzleOption.fromJson(Map<String, dynamic> json) {
    return PuzzleOption(
      id: json['id'] ?? (throw Exception("La 'option' no tiene id")),
      text: json['text'] ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PuzzleOption &&
          runtimeType == other.runtimeType &&
          uniqueId == other.uniqueId;

  @override
  int get hashCode => uniqueId.hashCode;
}

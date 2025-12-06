import 'package:flutter/material.dart';

Color _colorFromHex(String hexColor) {
  final hex = hexColor.replaceAll("#", "");
  return Color(int.parse("FF$hex", radix: 16));
}

class LevelData {
  final int idNivel;
  final int nivel;
  final int? retoId;
  final String iconAsset;
  final String? dinamicaNombre;
  final bool isCompleted;
  final bool isLocked;

  const LevelData({
    required this.idNivel,
    required this.nivel,
    this.retoId,
    required this.iconAsset,
    this.dinamicaNombre,
    this.isCompleted = false,
    this.isLocked = false,
  });

  factory LevelData.fromJson(Map<String, dynamic> json) {
    final retoData = json['reto'] as Map<String, dynamic>?;
    String? dinamicaNombre;
    if (retoData != null && retoData['dinamicas'] != null) {
      dinamicaNombre = retoData['dinamicas']['nombre'] as String?;
    }

    final String iconAsset =
        json['icon_asset'] ?? 'assets/images/home/estrella.svg';

    return LevelData(
      idNivel: json['id_nivel'] as int,
      nivel: json['orden'] as int,
      retoId: json['id_reto'] as int?,
      iconAsset: iconAsset,
      dinamicaNombre: dinamicaNombre,
      isCompleted: false,
      isLocked: false,
    );
  }

  LevelData copyWith({bool? isCompleted, bool? isLocked}) {
    return LevelData(
      idNivel: idNivel,
      nivel: nivel,
      retoId: retoId,
      iconAsset: iconAsset,
      dinamicaNombre: dinamicaNombre,
      isCompleted: isCompleted ?? this.isCompleted,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}

class SectionData {
  final int id;
  final int etapa;
  final String titulo;
  final String descripcion;
  final Color color;
  final Color colorOscuro;
  final List<LevelData> levels;
  final bool isLocked;

  const SectionData({
    required this.id,
    required this.etapa,
    required this.titulo,
    required this.descripcion,
    required this.color,
    required this.colorOscuro,
    required this.levels,
    this.isLocked = false,
  });

  factory SectionData.fromJson(Map<String, dynamic> json) {
    final hexColor = json['color'] as String;
    final hexColorOscuro = json['coloroscuro'] as String;
    final List<dynamic> levelListJson = json['niveles'] as List? ?? [];

    return SectionData(
      id: json['id_seccion'] as int,
      etapa: json['orden'] as int,
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String? ?? '',
      color: _colorFromHex(hexColor),
      colorOscuro: _colorFromHex(hexColorOscuro),
      levels: levelListJson
          .map((levelJson) => LevelData.fromJson(levelJson))
          .toList(),
      isLocked: false,
    );
  }

  SectionData copyWith({List<LevelData>? levels, bool? isLocked}) {
    return SectionData(
      id: id,
      etapa: etapa,
      titulo: titulo,
      descripcion: descripcion,
      color: color,
      colorOscuro: colorOscuro,
      levels: levels ?? this.levels,
      isLocked: isLocked ?? this.isLocked,
    );
  }

  static List<SectionData> applySequentialSectionLock(
    List<SectionData> sections,
  ) {
    final List<SectionData> finalSections = [];

    bool previousLevelWasCompleted = true;

    for (var currentSection in sections) {
      final List<LevelData> newLevels = [];

      for (var level in currentSection.levels) {
        final bool isLevelLocked = !previousLevelWasCompleted;

        newLevels.add(level.copyWith(isLocked: isLevelLocked));

        previousLevelWasCompleted = level.isCompleted;
      }

      final newSection = currentSection.copyWith(
        isLocked: false,
        levels: newLevels,
      );

      finalSections.add(newSection);
    }

    return finalSections;
  }
}

// [COMIENZO DEL ARCHIVO home_model.dart]
import 'package:flutter/material.dart';

// ... (helpers de color sin cambios) ...
Color _colorFromHex(String hexColor) {
  final hex = hexColor.replaceAll("#", "");
  return Color(int.parse("FF$hex", radix: 16));
}

// ------------------------------------
// MODELO DE NIVEL
// ------------------------------------
class LevelData {
  // ... (campos sin cambios) ...
  final int idNivel;
  final int nivel; // niveles.orden
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

  // --- ¡¡SIMPLIFICADO!! ---
  // Ya no necesita leer 'progreso_usuario'
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
      isCompleted: false, // ¡Se asignará en el PROVIDER!
      isLocked: false, // ¡Se asignará en el PROVIDER!
    );
  }

  // ¡¡IMPORTANTE!! Asegúrate que 'copyWith' tenga 'isCompleted'
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

// ------------------------------------
// MODELO DE SECCIÓN
// ------------------------------------
class SectionData {
  // ... (campos sin cambios) ...
  final int id;
  final int etapa; // secciones.orden
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

  // --- SIN CAMBIOS ---
  // (Solo se simplificó la lógica interna de LevelData)
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

  // ¡¡IMPORTANTE!! Asegúrate que 'copyWith' tenga 'levels'
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

  // --- ¡¡SIN CAMBIOS!! ---
  // Esta lógica ya es perfecta y no necesita modificarse.
  // Recibirá los datos con 'isCompleted' ya aplicado por el provider.
  static List<SectionData> applySequentialSectionLock(
    List<SectionData> sections,
  ) {
    final List<SectionData> finalSections = [];
    bool isPreviousSectionCompleted = true; // Desbloquea la Sección 1

    // Bucle de SECCIONES
    for (int i = 0; i < sections.length; i++) {
      final currentSection = sections[i];
      final bool isSectionLocked = !isPreviousSectionCompleted;

      // Bucle de NIVELES
      final List<LevelData> newLevels = [];
      bool isPreviousLevelCompleted = true; // Desbloquea el Nivel 1.1

      for (int j = 0; j < currentSection.levels.length; j++) {
        final level = currentSection.levels[j];

        final bool isLevelLocked = isSectionLocked || !isPreviousLevelCompleted;

        newLevels.add(level.copyWith(isLocked: isLevelLocked));

        isPreviousLevelCompleted = level.isCompleted;
      }

      final newSection = currentSection.copyWith(
        isLocked: isSectionLocked,
        levels: newLevels,
      );
      finalSections.add(newSection);

      isPreviousSectionCompleted = newLevels.every(
        (level) => level.isCompleted,
      );
    }
    return finalSections;
  }
}
// [FIN DEL ARCHIVO home_model.dart]
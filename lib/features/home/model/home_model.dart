// [COMIENZO DEL ARCHIVO home_model.dart]
import 'package:flutter/material.dart';

// ... (helpers de color sin cambios) ...
Color _colorFromHex(String hexColor) {
  final hex = hexColor.replaceAll("#", "");
  return Color(int.parse("FF$hex", radix: 16));
}


// MODELO DE NIVEL
  
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

  // Esto se usa para actualizar isCompleted e isLocked
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

// MODELO DE SECCIÓN
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

  // esta función no cambia en absoluto
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

  // Recibirá los datos con 'isCompleted' ya aplicado por el provider.
  static List<SectionData> applySequentialSectionLock(
    List<SectionData> sections,
  ) {
    final List<SectionData> finalSections = [];
    
    // Esta es la ÚNICA bandera que importa.
    // Trata todo el mapa (todas las secciones) como un solo camino.
    // Empieza en 'true' para desbloquear el primer nivel del mapa.
    bool previousLevelWasCompleted = true;

    // Bucle de SECCIONES
    for (var currentSection in sections) {
      
      final List<LevelData> newLevels = [];

      // Bucle de NIVELES
      // Este bucle simplemente continúa donde el anterior se quedó
      for (var level in currentSection.levels) {
        
        // Un nivel está bloqueado SI Y SOLO SI
        // el nivel anterior (incluso si fue en la sección anterior) NO está completo.
        final bool isLevelLocked = !previousLevelWasCompleted;

        newLevels.add(level.copyWith(isLocked: isLevelLocked));

        // Actualizamos la bandera para la *siguiente* iteración.
        // El siguiente nivel dependerá de si *este* nivel está completo.
        previousLevelWasCompleted = level.isCompleted;
      }

      // La sección en sí misma NUNCA debe estar bloqueada.
      // Solo sus niveles internos.
      final newSection = currentSection.copyWith(
        isLocked: false, // Siempre desbloqueada
        levels: newLevels,
      );
      
      finalSections.add(newSection);
    }
    
    return finalSections;
  }
}
// [FIN DEL ARCHIVO home_model.dart]
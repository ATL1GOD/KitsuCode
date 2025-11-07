// [COMIENZO DEL ARCHIVO home_model.dart]
import 'package:flutter/material.dart';

// --- Helpers de Color (Sin cambios) ---
Color _colorFromHex(String hexColor) {
  final hex = hexColor.replaceAll("#", "");
  return Color(int.parse("FF$hex", radix: 16));
}
// --- Fin Helpers ---

// ------------------------------------
// MODELO DE NIVEL
// ------------------------------------
class LevelData {
  final int idNivel; // Viene de niveles.id_nivel
  final int nivel; // Viene de niveles.orden
  final int? retoId; // Viene de niveles.id_reto
  final String iconAsset; // Viene de niveles.icon_asset
  final String? dinamicaNombre;

  // --- Campos de Estado ---
  final bool isCompleted;
  final bool isLocked;

  const LevelData({
    required this.idNivel,
    required this.nivel,
    this.retoId,
    required this.iconAsset,
    this.dinamicaNombre,
    this.isCompleted = false,
    this.isLocked = false, // El valor por defecto es 'false'
  });

  // --- CONSTRUCTOR JSON (Lee el progreso) ---
  factory LevelData.fromJson(Map<String, dynamic> json) {
    // 1. Revisa si 'progreso_usuario' existe y NO está vacío
    //    Esta lista la filtra RLS y la consulta del repositorio.
    final progressList = json['progreso_usuario'] as List? ?? [];
    final bool isCompleted = progressList.isNotEmpty;

    // 2. Extrae el nombre de la dinámica (si existe)
    final retoData = json['reto'] as Map<String, dynamic>?;
    String? dinamicaNombre;
    if (retoData != null && retoData['dinamicas'] != null) {
      dinamicaNombre = retoData['dinamicas']['nombre'] as String?;
    }

    // 3. Extrae el asset (Asume un valor por defecto si no viene)
    final String iconAsset =
        json['icon_asset'] ?? 'assets/images/home/estrella.svg';

    return LevelData(
      idNivel: json['id_nivel'] as int,
      nivel: json['orden'] as int, // Mapea 'orden' a 'nivel'
      retoId: json['id_reto'] as int?,
      iconAsset: iconAsset,
      dinamicaNombre: dinamicaNombre,
      isCompleted: isCompleted, // ¡Determinado por la consulta!
      isLocked: false, // El bloqueo se calcula DESPUÉS, en el provider.
    );
  }

  // Método 'copyWith' (Necesario para la lógica de bloqueo)
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
  final int id;
  final int etapa; // 'orden' de la tabla secciones
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

  // Constructor 'fromJson'
  factory SectionData.fromJson(Map<String, dynamic> json) {
    final hexColor = json['color'] as String;
    final hexColorOscuro = json['coloroscuro'] as String;
    final List<dynamic> levelListJson = json['niveles'] as List? ?? [];

    // NOTA: La lista de niveles ya viene ordenada por 'niveles.orden'
    // gracias a la consulta en el repositorio.

    return SectionData(
      id: json['id_seccion'] as int,
      etapa: json['orden'] as int, // Mapea 'orden' a 'etapa'
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String? ?? '',
      color: _colorFromHex(hexColor),
      colorOscuro: _colorFromHex(hexColorOscuro),
      levels: levelListJson
          .map((levelJson) => LevelData.fromJson(levelJson))
          .toList(),
      isLocked: false, // El bloqueo se calcula en el siguiente paso
    );
  }

  // Método 'copyWith' (Necesario para la lógica de bloqueo)
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

  // --- ¡¡ESTA ES LA LÓGICA DE DESBLOQUEO!! ---
  static List<SectionData> applySequentialSectionLock(
    List<SectionData> sections,
  ) {
    final List<SectionData> finalSections = [];

    // Esta bandera rastrea si la SECCIÓN anterior se completó.
    // Empieza en 'true' para desbloquear la primera sección.
    bool isPreviousSectionCompleted = true;

    // Bucle de SECCIONES (i)
    // (La lista 'sections' ya está ordenada por 'secciones.orden')
    for (int i = 0; i < sections.length; i++) {
      final currentSection = sections[i];

      // 1. LÓGICA DE SECCIÓN:
      // Una sección está bloqueada si la sección ANTERIOR no está completa.
      final bool isSectionLocked = !isPreviousSectionCompleted;

      // 2. LÓGICA DE NIVELES (DENTRO DE LA SECCIÓN):
      final List<LevelData> newLevels = [];

      // Esta bandera rastrea si el NIVEL anterior se completó.
      // Empieza en 'true' para desbloquear el primer nivel de la sección.
      bool isPreviousLevelCompleted = true;

      // Bucle de NIVELES (j)
      // (La lista 'currentSection.levels' ya está ordenada por 'niveles.orden')
      for (int j = 0; j < currentSection.levels.length; j++) {
        final level = currentSection.levels[j];

        // Un nivel (level) está bloqueado si:
        // A) La SECCIÓN entera ('isSectionLocked') está bloqueada
        // B) O si el NIVEL ANTERIOR ('isPreviousLevelCompleted') no está completo.
        final bool isLevelLocked = isSectionLocked || !isPreviousLevelCompleted;

        newLevels.add(level.copyWith(isLocked: isLevelLocked));

        // Actualizamos para la SIGUIENTE iteración del bucle de NIVELES
        isPreviousLevelCompleted = level.isCompleted;
      }

      // 3. Recreamos la sección con los datos actualizados
      final newSection = currentSection.copyWith(
        isLocked: isSectionLocked,
        levels: newLevels,
      );
      finalSections.add(newSection);

      // 4. Actualizamos para la SIGUIENTE iteración del bucle de SECCIONES
      // La *próxima* sección depende de si *esta* (newSection) está 100% completa.
      isPreviousSectionCompleted = newLevels.every(
        (level) => level.isCompleted,
      );
    }

    return finalSections;
  }
}
// [FIN DEL ARCHIVO home_model.dart]
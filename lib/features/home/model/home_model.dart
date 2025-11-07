// [COMIENZO DEL ARCHIVO home_model.dart]
import 'package:flutter/material.dart';

// --- Helpers de Color (Sin cambios) ---
Color _darkenColor(Color color, double factor) {
  return HSLColor.fromColor(color)
      .withLightness(
        (HSLColor.fromColor(color).lightness - factor).clamp(0.0, 1.0),
      )
      .toColor();
}

Color _colorFromHex(String hexColor) {
  final hex = hexColor.replaceAll("#", "");
  return Color(int.parse("FF$hex", radix: 16));
}
// --- Fin Helpers ---

// MODELO DE NIVEL: Actualizado con isCompleted y isLocked
class LevelData {
  final int idNivel; // Viene de niveles.id_nivel
  final int nivel; // Viene de niveles.orden
  final int? retoId; // Viene de niveles.id_reto
  final String iconAsset; // Viene de niveles.icon_asset
  final String? dinamicaNombre;

  // --- NUEVOS CAMPOS ---
  final bool isCompleted;
  final bool isLocked;
  // --- FIN NUEVOS CAMPOS ---

  const LevelData({
    required this.idNivel,
    required this.nivel,
    this.retoId,
    required this.iconAsset,
    this.dinamicaNombre,
    this.isCompleted = false,
    this.isLocked = true,
  });

  factory LevelData.fromJson(Map<String, dynamic> json) {
    String? nombreDinamica;
    if (json['reto'] != null &&
        json['reto'] is Map &&
        json['reto']['dinamicas'] != null) {
      nombreDinamica = json['reto']['dinamicas']['nombre'] as String?;
    }

    // El campo 'progreso_usuario' es una lista de resultados de la subconsulta de Supabase.
    // Si la lista NO está vacía, significa que el registro de progreso existe.
    final List<dynamic>? progresoUsuario = json['progreso_usuario'];
    final bool nivelCompletado =
        progresoUsuario != null && progresoUsuario.isNotEmpty;

    return LevelData(
      idNivel: (json['id_nivel'] as int?) ?? 0,
      nivel: (json['orden'] as int?) ?? 0, // Usar 'orden' de la tabla niveles
      retoId: json['id_reto'] as int?,
      iconAsset: (json['icon_asset'] as String?) ?? 'images/home/estrella.svg',
      dinamicaNombre: nombreDinamica,
      isCompleted: nivelCompletado, // <--- Determinado por la consulta
      isLocked:
          !nivelCompletado, // <--- Bloqueado por defecto, ajustado en SectionData
    );
  }

  // Función para crear la copia desbloqueada/bloqueada en el frontend
  LevelData copyWith({bool? isLocked}) {
    return LevelData(
      idNivel: idNivel,
      nivel: nivel,
      retoId: retoId,
      iconAsset: iconAsset,
      dinamicaNombre: dinamicaNombre,
      isCompleted: isCompleted,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}

// MODELO DE SECCIÓN: Implementa la lógica de bloqueo secuencial
class SectionData {
  final Color color;
  final Color colorOscuro;
  final int etapa; // 'orden' de la tabla secciones
  final String titulo;
  final int id; // Mapeado a id_seccion
  final List<LevelData> levels; // Lista de niveles anidados

  // --- NUEVOS CAMPOS ---
  final bool isCompleted;
  final bool isLocked;
  // --- FIN NUEVOS CAMPOS ---

  const SectionData({
    required this.color,
    required this.colorOscuro,
    required this.etapa,
    required this.titulo,
    required this.id,
    required this.levels,
    this.isCompleted = false, // Inicializado
    this.isLocked = true, // Inicializado
  });

  factory SectionData.fromJson(Map<String, dynamic> json) {
    final baseColor = _colorFromHex(json['color']);

    final List<dynamic>? levelsJson = json['niveles'];

    final List<LevelData> levels = levelsJson != null
        ? levelsJson
              .map<LevelData>((lJson) => LevelData.fromJson(lJson))
              .toList()
        : [];

    // 1. Ordenar los niveles
    levels.sort((a, b) => a.nivel.compareTo(b.nivel));

    // 2. Aplicar lógica de bloqueo secuencial INTERNO a la sección
    final List<LevelData> finalLevels = [];
    bool isPreviousCompleted = true; // Asumimos que podemos empezar

    for (int i = 0; i < levels.length; i++) {
      LevelData current = levels[i];

      // Bloqueado si el nivel anterior NO está completo (excepto el primero)
      // La lógica de bloqueo EXTERNA se aplicará en applySequentialSectionLock
      bool isLocked = !isPreviousCompleted && i != 0;

      // Si es el primer nivel (i=0), NUNCA está bloqueado inicialmente por lógica INTERNA
      if (i == 0) {
        isLocked = false;
      }

      finalLevels.add(current.copyWith(isLocked: isLocked));

      // Actualizamos el estado para la próxima iteración.
      isPreviousCompleted = current.isCompleted;
    }
    // --- FIN LÓGICA DE BLOQUEO INTERNO ---

    // Determinar si TODA la sección está completada.
    final bool isSectionCompleted = finalLevels.every(
      (level) => level.isCompleted,
    );

    return SectionData(
      id: json['id_seccion'] as int,
      etapa: (json['orden'] as int?) ?? 0,
      titulo: json['titulo'] as String,
      color: baseColor,
      colorOscuro: _colorFromHex(json['coloroscuro']),
      levels: finalLevels,
      isCompleted: isSectionCompleted, // <--- Guardamos el estado de la sección
      isLocked:
          true, // <--- Bloqueada por defecto, se ajustará en applySequentialSectionLock.
    );
  }

  // Función para crear la copia desbloqueada/bloqueada en el frontend
  SectionData copyWith({bool? isLocked, List<LevelData>? levels}) {
    return SectionData(
      color: color,
      colorOscuro: colorOscuro,
      etapa: etapa,
      titulo: titulo,
      id: id,
      levels: levels ?? this.levels,
      isCompleted: isCompleted,
      isLocked: isLocked ?? this.isLocked,
    );
  }

  // --- NUEVO MÉTODO ESTÁTICO: LÓGICA DE BLOQUEO ENTRE SECCIONES ---
  static List<SectionData> applySequentialSectionLock(
    List<SectionData> sections,
  ) {
    // 1. Aseguramos que las secciones estén ordenadas por etapa/orden
    sections.sort((a, b) => a.etapa.compareTo(b.etapa)); //

    final List<SectionData> finalSections = [];
    bool isPreviousSectionCompleted = true; // El mapa se desbloquea al inicio

    for (int i = 0; i < sections.length; i++) {
      SectionData currentSection = sections[i];

      // 2. Lógica de Bloqueo de la Sección:
      // Está bloqueada si la anterior NO está completa. Solo la primera (i=0) empieza desbloqueada.
      bool isSectionLocked = !isPreviousSectionCompleted && i != 0;

      // Si es la primera sección, NUNCA está bloqueada al inicio.
      if (i == 0) {
        isSectionLocked = false;
      }

      // 3. Bloqueo de Niveles DENTRO de la Sección:
      final List<LevelData>
      newLevels = currentSection.levels.asMap().entries.map((entry) {
        final level = entry.value;

        // Si la SECCIÓN está bloqueada, el PRIMER nivel de la sección debe estar bloqueado.
        if (entry.key == 0 && isSectionLocked) {
          return level.copyWith(isLocked: true);
        }

        // Si la sección está bloqueada, cualquier nivel está bloqueado.
        // Si la sección no está bloqueada, usamos el estado de bloqueo interno (level.isLocked).
        final bool shouldLockLevel = isSectionLocked || level.isLocked;

        return level.copyWith(isLocked: shouldLockLevel);
      }).toList();

      finalSections.add(
        currentSection.copyWith(
          isLocked: isSectionLocked,
          levels:
              newLevels, // Usamos la lista de niveles con bloqueo actualizado
        ),
      );

      // 4. Actualizamos el estado para la próxima iteración.
      isPreviousSectionCompleted = currentSection.isCompleted;
    }

    return finalSections;
  }
}
// [FIN DEL ARCHIVO home_model.dart]
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

  const SectionData({
    required this.color,
    required this.colorOscuro,
    required this.etapa,
    required this.titulo,
    required this.id,
    required this.levels,
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

    // 2. Aplicar lógica de bloqueo secuencial (Duolingo)
    final List<LevelData> finalLevels = [];
    bool isPreviousCompleted = true; // Asumimos que podemos empezar

    for (int i = 0; i < levels.length; i++) {
      LevelData current = levels[i];

      // El nivel actual está bloqueado si el nivel anterior NO está completo.
      // Solo el primer nivel (orden 1) puede estar desbloqueado si isPreviousCompleted es falso.
      bool isLocked = !isPreviousCompleted && i != 0;

      // Si es el primer nivel (i=0), NUNCA está bloqueado inicialmente.
      if (i == 0) {
        isLocked = false;
      }

      finalLevels.add(current.copyWith(isLocked: isLocked));

      // Actualizamos el estado para la próxima iteración.
      // El siguiente nivel solo puede desbloquearse si este nivel actual está completado.
      isPreviousCompleted = current.isCompleted;
    }
    // --- FIN LÓGICA DE BLOQUEO ---

    return SectionData(
      id: json['id_seccion'] as int,
      etapa: (json['orden'] as int?) ?? 0,
      titulo: json['titulo'] as String,
      color: baseColor,
      colorOscuro: _colorFromHex(json['coloroscuro']),
      levels:
          finalLevels, // <-- Usamos la lista final con la lógica de bloqueo aplicada
    );
  }
}

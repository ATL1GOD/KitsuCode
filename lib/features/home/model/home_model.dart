import 'package:flutter/material.dart';

// --- Helpers de Color ---
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

// NUEVO MODELO: Para representar un nivel/botón dentro de una sección
class LevelData {
  final int idNivel; // Viene de seccion_niveles.id_niveles
  final int nivel; // Viene de seccion_niveles.nivel
  final int? retoId; // Viene de seccion_niveles.reto_id
  final String iconAsset; // Viene de seccion_niveles.icon_asset

  const LevelData({
    required this.idNivel,
    required this.nivel,
    this.retoId,
    required this.iconAsset,
  });

  factory LevelData.fromJson(Map<String, dynamic> json) {
    return LevelData(
      idNivel: (json['id_niveles'] as int?) ?? 0,
      nivel: json['nivel'] as int,
      retoId: json['reto_id'] as int?,
      // CORRECCIÓN: Usar valor por defecto si el asset de la DB es nulo o vacío
      iconAsset: (json['icon_asset'] as String?) ?? 'images/home/estrella.svg',
    );
  }
}

// MODELO MODIFICADO: SectionData
class SectionData {
  final Color color;
  final Color colorOscuro;
  final int etapa;
  // CORRECCIÓN: Se elimina la referencia a la columna 'seccion'
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

    // Mapear los niveles anidados (que vienen como 'seccion_niveles')
    final List<dynamic>? levelsJson = json['seccion_niveles'];
    final List<LevelData> levels = levelsJson != null
        ? levelsJson
              .map<LevelData>((lJson) => LevelData.fromJson(lJson))
              .toList()
        : [];

    // IMPORTANTE: Ordenar los niveles por su campo 'nivel' para mostrarlos en orden
    levels.sort((a, b) => a.nivel.compareTo(b.nivel));

    return SectionData(
      id:
          json['id_seccion']
              as int, // Usar 'id_seccion' de la tabla 'secciones'
      etapa: json['etapa'] as int,
      // Se omite 'seccion' para evitar el error.
      titulo: json['titulo'] as String,
      color: baseColor,
      colorOscuro: _darkenColor(baseColor, 0.1),
      levels: levels, // Asignar la lista de niveles
    );
  }
}

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

// MODELO DE NIVEL: Actualizado con dinamicaNombre
class LevelData {
  final int idNivel; // Viene de niveles.id_nivel
  final int nivel; // Viene de niveles.orden
  final int? retoId; // Viene de niveles.id_reto
  final String iconAsset; // Viene de niveles.icon_asset

  // --- NUEVO CAMPO ---
  final String? dinamicaNombre;
  // --- FIN NUEVO CAMPO ---

  const LevelData({
    required this.idNivel,
    required this.nivel,
    this.retoId,
    required this.iconAsset,
    this.dinamicaNombre, // <-- Añadir al constructor
  });

  factory LevelData.fromJson(Map<String, dynamic> json) {
    // --- LÓGICA MEJORADA ---
    String? nombreDinamica;
    if (json['reto'] != null &&
        json['reto'] is Map &&
        json['reto']['dinamicas'] != null) {
      nombreDinamica = json['reto']['dinamicas']['nombre'] as String?;
    }
    // --- FIN LÓGICA MEJORADA ---

    return LevelData(
      idNivel: (json['id_nivel'] as int?) ?? 0,
      nivel: (json['orden'] as int?) ?? 0, // Usar 'orden' de la tabla niveles
      retoId: json['id_reto'] as int?,
      iconAsset: (json['icon_asset'] as String?) ?? 'images/home/estrella.svg',
      dinamicaNombre: nombreDinamica, // <-- Asignar el valor
    );
  }
}

// MODELO DE SECCIÓN: Actualizado para 'niveles'
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

    // Mapear los niveles anidados (que vienen como 'niveles')
    // --- CORRECCIÓN CLAVE ---
    final List<dynamic>? levelsJson =
        json['niveles']; // <-- NO 'seccion_niveles'
    // --- FIN CORRECCIÓN ---

    final List<LevelData> levels = levelsJson != null
        ? levelsJson
              .map<LevelData>((lJson) => LevelData.fromJson(lJson))
              .toList()
        : [];

    // Ordenar los niveles (sin cambios)
    levels.sort((a, b) => a.nivel.compareTo(b.nivel));

    return SectionData(
      id: json['id_seccion'] as int,
      // Usar 'orden' de la tabla 'secciones' como 'etapa'
      etapa: (json['orden'] as int?) ?? 0,
      titulo: json['titulo'] as String,
      color: baseColor,
      // Usar 'coloroscuro' que viene de la DB
      colorOscuro: _colorFromHex(json['coloroscuro']),
      levels: levels,
    );
  }
}

import 'package:flutter/material.dart';

// --- Helpers de Color ---
// Mueve la lógica de 'darken' aquí para que el modelo la maneje.
Color _darkenColor(Color color, double factor) {
  return HSLColor.fromColor(color)
      .withLightness(
        (HSLColor.fromColor(color).lightness - factor).clamp(0.0, 1.0),
      )
      .toColor();
}

// Helper para convertir el String '#RRGGBB' de Supabase a un objeto Color.
Color _colorFromHex(String hexColor) {
  final hex = hexColor.replaceAll("#", "");
  return Color(int.parse("FF$hex", radix: 16));
}
// --- Fin Helpers ---

class SectionData {
  final Color color;
  final Color colorOscuro;
  final int etapa;
  final int seccion;
  final String titulo;
  // Podrías añadir el 'id' si lo necesitas
  // final int id;

  const SectionData({
    required this.color,
    required this.colorOscuro,
    required this.etapa,
    required this.seccion,
    required this.titulo,
  });

  // Factory constructor para crear una instancia desde un JSON (mapa)
  factory SectionData.fromJson(Map<String, dynamic> json) {
    // Lee el color base de la DB
    final baseColor = _colorFromHex(json['color']);

    return SectionData(
      // id: json['id'] as int, // Descomenta si añades 'id'
      etapa: json['etapa'] as int,
      seccion: json['seccion'] as int,
      titulo: json['titulo'] as String,
      color: baseColor,
      // Calcula el color oscuro automáticamente
      colorOscuro: _darkenColor(baseColor, 0.1),
    );
  }
}

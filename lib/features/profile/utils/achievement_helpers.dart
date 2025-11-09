// lib/features/profile/utils/achievement_helpers.dart
import 'package:flutter/material.dart';

// Colores de rareza estándar
const Color kRarityCommon = Color(0xFF1eff00); // Verde
const Color kRarityRare = Color(0xFF0070dd);   // Azul
const Color kRarityEpic = Color(0xFFa335ee);    // Morado
const Color kRarityLegendary = Color(0xFFff8000); // Dorado/Naranja

/// Devuelve el color asociado con la rareza del logro
Color getRarityColor(String raridad) {
  switch (raridad) {
    case 'Común':
      return kRarityCommon;
    case 'Raro':
      return kRarityRare;
    case 'Épico':
      return kRarityEpic;
    case 'Legendario':
      return kRarityLegendary;
    default:
      return Colors.grey; // Color por defecto
  }
}

/// Devuelve el texto de la rareza en mayúsculas
String getRarityText(String raridad) {
  return raridad.toUpperCase();
}
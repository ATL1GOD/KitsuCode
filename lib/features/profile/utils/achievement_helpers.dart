import 'package:flutter/material.dart';

const Color kRarityCommon = Color(0xFF1eff00);
const Color kRarityRare = Color(0xFF0070dd);
const Color kRarityEpic = Color(0xFFa335ee);
const Color kRarityLegendary = Color(0xFFff8000);

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
      return Colors.grey;
  }
}

String getRarityText(String raridad) {
  return raridad.toUpperCase();
}

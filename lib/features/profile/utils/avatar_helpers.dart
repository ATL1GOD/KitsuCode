// lib/features/profile/utils/avatar_helpers.dart

import 'package:flutter/material.dart';
import 'package:kitsucode/features/profile/model/avatar_model.dart';

/// Obtiene el color principal de un avatar por su ID
/// Busca en la lista de avatares cargados o usa fallback
Color getAvatarColorById(int avatarId, [List<AvatarModel>? avatares]) {
  if (avatares != null && avatares.isNotEmpty) {
    try {
      final avatar = avatares.firstWhere((a) => a.id == avatarId);
      return parseColorFromString(avatar.colorPrimario);
    } catch (e) {
      // Si no se encuentra, usar el primero
      return parseColorFromString(avatares.first.colorPrimario);
    }
  }

  // Fallback por ID (basado en los IDs que insertaste)
  switch (avatarId) {
    case 1: return const Color(0xFFE65100); // Zorro
    case 2: return const Color(0xFFD84315); // Mono
    case 3: return const Color(0xFF7B1FA2); // Gato
    case 4: return const Color(0xFF2E7D32); // Panda
    case 5: return const Color(0xFF0097A7); // Tiburón
    case 6: return const Color(0xFFF57F17); // León
    default: return const Color(0xFFE65100); // Default: Zorro
  }
}

/// Obtiene el asset path de un avatar por su ID
String getAvatarAssetPathById(int avatarId, [List<AvatarModel>? avatares]) {
  if (avatares != null && avatares.isNotEmpty) {
    try {
      final avatar = avatares.firstWhere((a) => a.id == avatarId);
      return avatar.assetPath;
    } catch (e) {
      return avatares.first.assetPath;
    }
  }

  // Fallback por ID
  switch (avatarId) {
    case 1: return 'assets/images/login_zorro.png';
    case 2: return 'assets/images/avatar_mono.png';
    case 3: return 'assets/images/avatar_gato.png';
    case 4: return 'assets/images/avatar_panda.png';
    case 5: return 'assets/images/avatar_tiburon.png';
    case 6: return 'assets/images/avatar_leon.png';
    default: return 'assets/images/login_zorro.png';
  }
}

/// Convierte un string de color (ej: '0xFFE65100') a Color
Color parseColorFromString(String colorString) {
  try {
    final cleanColor = colorString.replaceFirst('0x', '');
    final intValue = int.parse(cleanColor, radix: 16);
    return Color(intValue);
  } catch (e) {
    return const Color(0xFFE65100); // Default: naranja del zorro
  }
}

/// Obtiene el color del avatar directamente desde el modelo
Color getAvatarColor(AvatarModel avatar) {
  return parseColorFromString(avatar.colorPrimario);
}

/// Filtra avatares por tipo (comun o especial)
List<AvatarModel> filterAvataresByTipo(List<AvatarModel> avatares, String tipo) {
  return avatares.where((avatar) => avatar.tipo == tipo).toList();
}

/// Filtra solo los avatares desbloqueados
List<AvatarModel> filterAvatarsDesbloqueados(List<AvatarModel> avatares) {
  return avatares.where((avatar) => avatar.desbloqueado).toList();
}

/// Filtra solo los avatares bloqueados
List<AvatarModel> filterAvatarsBloqueados(List<AvatarModel> avatares) {
  return avatares.where((avatar) => !avatar.desbloqueado).toList();
}

/// Obtiene un avatar específico por ID
AvatarModel? getAvatarById(int avatarId, List<AvatarModel> avatares) {
  try {
    return avatares.firstWhere((a) => a.id == avatarId);
  } catch (e) {
    return null;
  }
}

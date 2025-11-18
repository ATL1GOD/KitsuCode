// lib/features/profile/utils/avatar_helpers.dart

import 'package:flutter/material.dart';
import 'package:kitsucode/features/profile/model/avatar_model.dart';

/// Obtiene el color principal de un avatar por su ID
/// Requiere la lista de avatares de la BD
Color getAvatarColorById(int avatarId, List<AvatarModel> avatares) {
  if (avatares.isEmpty) {
    debugPrint('⚠️ Lista de avatares vacía, usando color por defecto');
    return _getDefaultColor();
  }

  try {
    final avatar = avatares.firstWhere((a) => a.id == avatarId);
    return parseColorFromString(avatar.colorPrimario);
  } catch (e) {
    debugPrint('⚠️ Avatar ID $avatarId no encontrado, usando primer avatar');
    return parseColorFromString(avatares.first.colorPrimario);
  }
}

/// Obtiene el asset path de un avatar por su ID
/// Requiere la lista de avatares de la BD
String getAvatarAssetPathById(int avatarId, List<AvatarModel> avatares) {
  if (avatares.isEmpty) {
    debugPrint('⚠️ Lista de avatares vacía, usando asset por defecto');
    return _getDefaultAssetPath();
  }

  try {
    final avatar = avatares.firstWhere((a) => a.id == avatarId);
    return avatar.assetPath;
  } catch (e) {
    debugPrint('⚠️ Avatar ID $avatarId no encontrado, usando primer avatar');
    return avatares.first.assetPath;
  }
}

/// Obtiene un avatar completo por su ID
/// Retorna null si no se encuentra
AvatarModel? getAvatarById(int avatarId, List<AvatarModel> avatares) {
  try {
    return avatares.firstWhere((a) => a.id == avatarId);
  } catch (e) {
    debugPrint('⚠️ Avatar ID $avatarId no encontrado');
    return null;
  }
}

/// Obtiene el color del avatar directamente desde el modelo
Color getAvatarColor(AvatarModel avatar) {
  return parseColorFromString(avatar.colorPrimario);
}

/// ============================================================================
/// FILTROS Y BÚSQUEDAS
/// ============================================================================

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

/// Obtiene avatares comunes desbloqueados
List<AvatarModel> getAvataresComunesDesbloqueados(List<AvatarModel> avatares) {
  return avatares
      .where((avatar) => avatar.tipo == 'comun' && avatar.desbloqueado)
      .toList();
}

/// Obtiene avatares especiales desbloqueados
List<AvatarModel> getAvataresEspecialesDesbloqueados(List<AvatarModel> avatares) {
  return avatares
      .where((avatar) => avatar.tipo == 'especial' && avatar.desbloqueado)
      .toList();
}

/// Cuenta avatares desbloqueados por tipo
Map<String, int> countAvataresByTipo(List<AvatarModel> avatares) {
  return {
    'comun': avatares.where((a) => a.tipo == 'comun' && a.desbloqueado).length,
    'especial': avatares.where((a) => a.tipo == 'especial' && a.desbloqueado).length,
    'total': avatares.where((a) => a.desbloqueado).length,
  };
}


/// Convierte un string de color (ej: '0xFFE65100') a Color
Color parseColorFromString(String colorString) {
  try {
    // Limpiar el string
    String cleanColor = colorString.trim();
    
    // Remover el prefijo 0x si existe
    if (cleanColor.startsWith('0x') || cleanColor.startsWith('0X')) {
      cleanColor = cleanColor.substring(2);
    }
    
    // Agregar FF al inicio si no tiene alpha
    if (cleanColor.length == 6) {
      cleanColor = 'FF$cleanColor';
    }
    
    // Parsear como hexadecimal
    final intValue = int.parse(cleanColor, radix: 16);
    return Color(intValue);
  } catch (e) {
    debugPrint('❌ Error parseando color "$colorString": $e');
    return _getDefaultColor();
  }
}

/// Convierte un Color a string hexadecimal
String colorToString(Color color) {
  return '0x${color.value.toRadixString(16).toUpperCase().padLeft(8, '0')}';
}


/// Verifica si un avatar está desbloqueado
bool isAvatarUnlocked(int avatarId, List<AvatarModel> avatares) {
  final avatar = getAvatarById(avatarId, avatares);
  return avatar?.desbloqueado ?? false;
}

/// Verifica si un avatar existe en la lista
bool avatarExists(int avatarId, List<AvatarModel> avatares) {
  return avatares.any((a) => a.id == avatarId);
}

/// Obtiene el progreso de desbloqueo de avatares
Map<String, dynamic> getAvatarProgress(List<AvatarModel> avatares) {
  final total = avatares.length;
  final desbloqueados = avatares.where((a) => a.desbloqueado).length;
  
  return {
    'total': total,
    'desbloqueados': desbloqueados,
    'bloqueados': total - desbloqueados,
    'porcentaje': total > 0 ? (desbloqueados / total * 100).toInt() : 0,
  };
}


/// Ordena avatares por nombre
List<AvatarModel> sortAvataresByName(List<AvatarModel> avatares, {bool ascending = true}) {
  final sorted = List<AvatarModel>.from(avatares);
  sorted.sort((a, b) {
    final comparison = a.nombre.compareTo(b.nombre);
    return ascending ? comparison : -comparison;
  });
  return sorted;
}

/// Ordena avatares por ID
List<AvatarModel> sortAvataresByID(List<AvatarModel> avatares, {bool ascending = true}) {
  final sorted = List<AvatarModel>.from(avatares);
  sorted.sort((a, b) {
    final comparison = a.id.compareTo(b.id);
    return ascending ? comparison : -comparison;
  });
  return sorted;
}

/// Ordena avatares: desbloqueados primero, luego bloqueados
List<AvatarModel> sortAvataresByUnlockStatus(List<AvatarModel> avatares) {
  final desbloqueados = avatares.where((a) => a.desbloqueado).toList();
  final bloqueados = avatares.where((a) => !a.desbloqueado).toList();
  return [...desbloqueados, ...bloqueados];
}


/// Color por defecto si no se puede cargar desde BD
Color _getDefaultColor() {
  return const Color(0xFFE65100); // Naranja del zorro
}

/// Asset path por defecto si no se puede cargar desde BD
String _getDefaultAssetPath() {
  return 'assets/images/login_zorro.png';
}

/// Busca avatares por nombre (búsqueda parcial)
List<AvatarModel> searchAvataresByName(List<AvatarModel> avatares, String query) {
  if (query.isEmpty) return avatares;
  
  final lowerQuery = query.toLowerCase();
  return avatares.where((avatar) {
    return avatar.nombre.toLowerCase().contains(lowerQuery);
  }).toList();
}

/// Obtiene el siguiente avatar disponible para desbloquear
AvatarModel? getNextLockedAvatar(List<AvatarModel> avatares) {
  try {
    return avatares.firstWhere((a) => !a.desbloqueado);
  } catch (e) {
    return null; // Todos están desbloqueados
  }
}

/// Obtiene avatares aleatorios (útil para recompensas)
List<AvatarModel> getRandomAvatares(List<AvatarModel> avatares, int count) {
  if (avatares.length <= count) return avatares;
  
  final shuffled = List<AvatarModel>.from(avatares)..shuffle();
  return shuffled.take(count).toList();
}
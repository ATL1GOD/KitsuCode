import 'package:flutter/material.dart';
import 'package:kitsucode/features/profile/model/avatar_model.dart';

Color getAvatarColorById(int avatarId, [List<AvatarModel>? avatares]) {
  if (avatares != null && avatares.isNotEmpty) {
    try {
      final avatar = avatares.firstWhere((a) => a.id == avatarId);
      return parseColorFromString(avatar.colorPrimario);
    } catch (_) {
      return parseColorFromString(avatares.first.colorPrimario);
    }
  }
  return Colors.grey;
}

String getAvatarAssetPathById(int avatarId, [List<AvatarModel>? avatares]) {
  if (avatares != null && avatares.isNotEmpty) {
    try {
      final avatar = avatares.firstWhere((a) => a.id == avatarId);
      return avatar.assetPath;
    } catch (_) {
      return avatares.first.assetPath;
    }
  }
  return '';
}

Color parseColorFromString(String colorString) {
  try {
    final cleanColor = colorString.replaceFirst('0x', '');
    final intValue = int.parse(cleanColor, radix: 16);
    return Color(intValue);
  } catch (_) {
    return Colors.grey;
  }
}

List<AvatarModel> filterAvataresByTipo(
  List<AvatarModel> avatares,
  String tipo,
) {
  return avatares.where((a) => a.tipo == tipo).toList();
}

List<AvatarModel> filterAvatarsDesbloqueados(List<AvatarModel> avatares) {
  return avatares.where((a) => a.desbloqueado).toList();
}

List<AvatarModel> filterAvatarsBloqueados(List<AvatarModel> avatares) {
  return avatares.where((a) => !a.desbloqueado).toList();
}

AvatarModel? getAvatarById(int avatarId, List<AvatarModel> avatares) {
  try {
    return avatares.firstWhere((a) => a.id == avatarId);
  } catch (_) {
    return null;
  }
}

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Un widget "inteligente" que muestra una imagen desde un 'asset' local
/// o desde una URL de 'network' (http) usando caché.
class SmartImage extends StatelessWidget {
  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;

  const SmartImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final bool esUrlDeRed = path.startsWith('http');

    // 🎯 OPTIMIZACIÓN: Calcular cache dimensions si se especifican width/height
    final int? cacheWidth = width != null ? (width! * 2).round() : null;
    final int? cacheHeight = height != null ? (height! * 2).round() : null;

    if (esUrlDeRed) {
      // 2. Si es URL, usamos CachedNetworkImage
      return CachedNetworkImage(
        imageUrl: path,
        width: width,
        height: height,
        fit: fit,
        // 🎯 OPTIMIZACIÓN: Limitar tamaño en memoria
        memCacheWidth: cacheWidth,
        memCacheHeight: cacheHeight,
        // Placeholder más ligero
        placeholder: (context, url) => Container(
          width: width,
          height: height,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        // Muestra un ícono de error
        errorWidget: (context, url, error) {
          return Container(
            width: width,
            height: height,
            color: Theme.of(context).colorScheme.surfaceContainer,
            child: Icon(Icons.error_outline,
                color: Theme.of(context).colorScheme.outline),
          );
        },
      );
    } else {
      // 3. Si no, es un asset local, usamos Image.asset
      return Image.asset(
        path,
        width: width,
        height: height,
        fit: fit,
        // 🎯 OPTIMIZACIÓN: Limitar tamaño en cache
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Theme.of(context).colorScheme.surfaceContainer,
            child: Icon(Icons.image_not_supported_outlined,
                color: Theme.of(context).colorScheme.outline),
          );
        },
      );
    }
  }
}
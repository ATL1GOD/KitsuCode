import 'package:flutter/material.dart';

/// Un widget "inteligente" que muestra una imagen desde un 'asset' local
/// o desde una URL de 'network' (http).
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
    // 1. Revisamos si el path es una URL de internet
    final bool esUrlDeRed = path.startsWith('http');

    if (esUrlDeRed) {
      // 2. Si es URL, usamos Image.network
      return Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        // Muestra un 'cargando...'
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        // Muestra un ícono de error si falla la descarga
        errorBuilder: (context, error, stackTrace) {
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
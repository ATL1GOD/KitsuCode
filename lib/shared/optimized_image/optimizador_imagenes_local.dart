import 'package:flutter/material.dart';

class OptimizedLocalImage extends StatelessWidget {
  final String assetPath;
  final double width;
  final double height;
  final BoxFit fit;
  final bool enableCache;

  const OptimizedLocalImage({
    super.key,
    required this.assetPath,
    required this.width,
    required this.height,
    this.fit = BoxFit.contain,
    this.enableCache = true,
  });

  @override
  Widget build(BuildContext context) {
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: (width * devicePixelRatio).round(),
      cacheHeight: (height * devicePixelRatio).round(),
      filterQuality: FilterQuality.low, // Máximo rendimiento para íconos
      isAntiAlias: false, // Desactiva anti-aliasing para mejor rendimiento
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return child;
        }
        return Container(
          width: width,
          height: height,
          color: Colors.transparent,
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: Icon(Icons.image, size: width * 0.5, color: Colors.grey[400]),
        );
      },
    );
  }
}

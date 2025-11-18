// lib/shared/optimized_image/optimizador_imagenes.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/scheduler.dart'; // <-- Ya no se necesita

// CAMBIO GRANDE: Convertido de StatefulWidget a StatelessWidget
class OptimizedImage extends StatelessWidget {
  final String imagePath;
  final double width;
  final double height;
  final BoxFit fit;
  final bool enableCache;
  final bool isLocalAsset;

  const OptimizedImage({
    super.key,
    required this.imagePath,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.enableCache = true,
    this.isLocalAsset = false,
  });

  // --- TODA LA LÓGICA DE STATE (initState, _shouldLoad, etc.) SE HA IDO ---

  // La función ahora recibe 'context' porque lo necesita para el MediaQuery
  String _getOptimizedUrl(BuildContext context) {
    if (isLocalAsset) return imagePath;

    const projectId = 'dagwwsclohbjsmxseuqd';
    const bucketName = 'assets';

    final mediaQuery = MediaQuery.of(context);
    final devicePixelRatio = mediaQuery.devicePixelRatio;

    final targetWidth = (width * devicePixelRatio).round();

    return 'https://$projectId.supabase.co/storage/v1/object/public/$bucketName/$imagePath'
        '?width=$targetWidth'
        '&quality=${_calculateQuality(devicePixelRatio)}'
        '&format=webp'
        '&cache=3600';
  }

  int _calculateQuality(double devicePixelRatio) {
    if (devicePixelRatio > 3.0) return 90;
    if (devicePixelRatio > 2.0) return 85;
    return 80;
  }

  @override
  Widget build(BuildContext context) {
    // Ya no hay 'if (!_shouldLoad ...)'

    // 1. Manejar assets locales primero
    if (isLocalAsset) {
      return _buildLocalImage(context);
    }

    // 2. Calcular la URL aquí, es súper rápido
    final String optimizedUrl = _getOptimizedUrl(context);

    // 3. Manejar imágenes de red sin caché
    if (!enableCache) {
      return _buildNetworkImageWithoutCache(context, optimizedUrl);
    }

    // 4. El caso principal: Imagen de red cacheada
    // Esto irá directo a la caché de MEMORIA y no parpadeará
    return _buildCachedNetworkImage(context, optimizedUrl);
  }

  // --- Los widgets de construcción ahora reciben 'context' ---

  Widget _buildLocalImage(BuildContext context) {
    return Image.asset(
      imagePath,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: (width * 2).round(),
      errorBuilder: (context, error, stackTrace) => _buildErrorWidget(context),
    );
  }

  Widget _buildCachedNetworkImage(BuildContext context, String imageUrl) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      // ESTA ES LA CLAVE: Si está en memoria, la muestra en 0ms (sin fade)
      fadeInDuration: const Duration(milliseconds: 0),
      // Un fade-out suave si la URL cambia
      fadeOutDuration: const Duration(milliseconds: 200),
      useOldImageOnUrlChange: true,
      memCacheWidth: (width * 2).round(),
      memCacheHeight: (height * 2).round(),
      placeholder: (context, url) => _buildSkeletonWidget(context),
      errorWidget: (context, url, error) => _buildErrorWidget(context),
    );
  }

  Widget _buildNetworkImageWithoutCache(
      BuildContext context, String imageUrl) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: (width * 2).round(),
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: child,
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildSkeletonWidget(context);
      },
      errorBuilder: (context, error, stackTrace) => _buildErrorWidget(context),
    );
  }

  Widget _buildSkeletonWidget(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        Icons.photo,
        color: Colors.grey[300],
        size: width * 0.2,
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    final minSize = width < height ? width : height;
    return Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Icon(
        Icons.broken_image,
        color: Theme.of(context).colorScheme.outline,
        size: minSize * 0.3,
      ),
    );
  }
}

class OptimizedImageListTile extends StatelessWidget {
  final String imagePath;
  final double width;
  final double height;
  final BoxFit fit;

  const OptimizedImageListTile({
    super.key,
    required this.imagePath,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return OptimizedImage(
      imagePath: imagePath,
      width: width,
      height: height,
      fit: fit,
      enableCache: true,
      // AÑADIDO: Asumimos que OptimizedImageListTile
      // también podría manejar assets locales.
      // Si siempre son de red, puedes quitar esto.
      isLocalAsset:
          !imagePath.startsWith('http') && !imagePath.startsWith('avatares/'),
    );
  }
}
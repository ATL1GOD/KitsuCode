// lib/shared/optimized_image/optimizador_imagenes.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
    if (isLocalAsset) {
      return _buildLocalImage(context);
    }

    final String optimizedUrl = _getOptimizedUrl(context);

    if (!enableCache) {
      return _buildNetworkImageWithoutCache(context, optimizedUrl);
    }

    return _buildCachedNetworkImage(context, optimizedUrl);
  }

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
      fadeInDuration: const Duration(milliseconds: 0),
      fadeOutDuration: const Duration(milliseconds: 200),
      useOldImageOnUrlChange: true,
      memCacheWidth: (width * 2).round(),
      memCacheHeight: (height * 2).round(),
      placeholder: (context, url) => _buildSkeletonWidget(context),
      errorWidget: (context, url, error) => _buildErrorWidget(context),
    );
  }

  Widget _buildNetworkImageWithoutCache(BuildContext context, String imageUrl) {
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
        color: Colors.grey[200], // Un gris más claro para el fondo
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: SizedBox(
          width: width * 0.4, // Ancho del indicador de progreso
          child: LinearProgressIndicator(
            color: Colors.grey[300], // Color de la barra de progreso
            backgroundColor: Colors.grey[200], // Fondo de la barra
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    final minSize = width < height ? width : height;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHigh, // Un color un poco más oscuro que el surface normal
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        Icons
            .image_not_supported_outlined, // Un icono de error más moderno y menos "roto"
        color: Theme.of(
          context,
        ).colorScheme.outlineVariant, // Color del borde o un gris más oscuro
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
      isLocalAsset:
          !imagePath.startsWith('http') && !imagePath.startsWith('avatares/'),
    );
  }
}

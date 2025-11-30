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

    // --- LÓGICA DE SEGURIDAD ---
    int targetWidth;

    // 1. Si tienes un ancho definido (lo que usabas antes), sigue igual.
    if (width.isFinite) {
      targetWidth = (width * devicePixelRatio).round();
    }
    // 2. Si es infinito (tu nuevo banner), usamos un ancho estándar de pantalla (ej. 1080px)
    //    para pedirle a Supabase una imagen de buena calidad pero no gigante.
    else {
      targetWidth = 1080;
    }

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
      // AQUÍ ESTÁ LA PROTECCIÓN:
      // Si width es número (ej. 100), calcula 200. Si es infinito, pasa NULL.
      // Cuando pasas NULL a cacheWidth, Flutter usa el tamaño original del archivo.
      // Esto es seguro y no rompe nada.
      cacheWidth: width.isFinite ? (width * 2).round() : null,
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

      // PROTECCIÓN IGUAL QUE ARRIBA
      memCacheWidth: width.isFinite ? (width * 2).round() : null,
      // Si la altura también fuera infinita (raro), también lo protegemos
      memCacheHeight: height.isFinite ? (height * 2).round() : null,

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
      // PROTECCIÓN
      cacheWidth: width.isFinite ? (width * 2).round() : null,
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
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        // PROTECCIÓN VISUAL:
        // Si el ancho es infinito, la barrita de carga no puede ser "infinita * 0.4".
        // Le ponemos un tamaño fijo de 100px para que se vea bien.
        child: SizedBox(
          width: width.isFinite ? width * 0.4 : 100.0,
          child: LinearProgressIndicator(
            color: Colors.grey[300],
            backgroundColor: Colors.grey[200],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    // PROTECCIÓN PARA EL ICONO DE ERROR
    final safeWidth = width.isFinite ? width : 100.0;
    final safeHeight = height.isFinite ? height : 100.0;

    // Usamos los valores seguros para calcular el tamaño del icono
    final minSize = safeWidth < safeHeight ? safeWidth : safeHeight;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        Icons.image_not_supported_outlined,
        color: Theme.of(context).colorScheme.outlineVariant,
        size: minSize * 0.3,
      ),
    );
  }
}

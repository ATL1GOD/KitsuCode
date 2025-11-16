// lib/widgets/optimized_image.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/scheduler.dart';

class OptimizedImage extends StatefulWidget {
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

  @override
  State<OptimizedImage> createState() => _OptimizedImageState();
}

class _OptimizedImageState extends State<OptimizedImage> {
  late final String _optimizedUrl;
  bool _shouldLoad = false;

  @override
  void initState() {
    super.initState();
    _optimizedUrl = _getOptimizedUrl();

    // ✅ OPTIMIZACIÓN: Carga diferida para mejorar rendimiento
    _scheduleLoad();
  }

  void _scheduleLoad() {
    // Carga en el siguiente frame para no bloquear la UI
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _shouldLoad = true;
        });
      }
    });
  }

  String _getOptimizedUrl() {
    if (widget.isLocalAsset) return widget.imagePath;

    const projectId = 'dagwwsclohbjsmxseuqd';
    const bucketName = 'assets';

    final mediaQuery = MediaQuery.of(context);
    final devicePixelRatio = mediaQuery.devicePixelRatio;

    final targetWidth = (widget.width * devicePixelRatio).round();

    return 'https://$projectId.supabase.co/storage/v1/object/public/$bucketName/${widget.imagePath}'
        '?width=$targetWidth'
        '&quality=${_calculateQuality(devicePixelRatio)}'
        '&format=webp'
        '&cache=3600';
  }

  int _calculateQuality(double devicePixelRatio) {
    // Calidades optimizadas para buena calidad visual
    if (devicePixelRatio > 3.0) return 90;
    if (devicePixelRatio > 2.0) return 85;
    return 80;
  }

  @override
  Widget build(BuildContext context) {
    final bool isNetworkImage = _optimizedUrl.startsWith('http');

    // ✅ OPTIMIZACIÓN: Container inicial mínimo hasta que se decida cargar
    if (!_shouldLoad) {
      return _buildSkeletonWidget();
    }

    // Assets locales
    if (!isNetworkImage || widget.isLocalAsset) {
      return _buildLocalImage();
    }

    // ✅ OPTIMIZACIÓN: Usar Image.network si el cache está desactivado
    if (!widget.enableCache) {
      return _buildNetworkImageWithoutCache();
    }

    return _buildCachedNetworkImage();
  }

  Widget _buildLocalImage() {
    return Image.asset(
      widget.imagePath,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      cacheWidth: (widget.width * 2).round(),
      errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
    );
  }

  Widget _buildCachedNetworkImage() {
    return CachedNetworkImage(
      imageUrl: _optimizedUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,

      // ✅ OPTIMIZACIONES DE RENDIMIENTO:
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 200),

      // Menos procesamiento de imágenes
      useOldImageOnUrlChange: true,

      // Cache en memoria con buena resolución
      memCacheWidth: (widget.width * 2).round(),
      memCacheHeight: (widget.height * 2).round(),

      placeholder: (context, url) => _buildSkeletonWidget(),
      errorWidget: (context, url, error) => _buildErrorWidget(),
    );
  }

  Widget _buildNetworkImageWithoutCache() {
    return Image.network(
      _optimizedUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,

      // ✅ OPTIMIZACIONES:
      cacheWidth: (widget.width * 2).round(),
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
        return _buildSkeletonWidget();
      },
      errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
    );
  }

  // ✅ Widget de carga eficiente
  Widget _buildSkeletonWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        Icons.photo,
        color: Colors.grey[300],
        size: widget.width * 0.2,
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Icon(
        Icons.broken_image,
        color: Theme.of(context).colorScheme.outline,
        size:
            (widget.width < widget.height ? widget.width : widget.height) * 0.3,
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

// ✅ VERSIÓN OPTIMIZADA para listas
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
    );
  }
}

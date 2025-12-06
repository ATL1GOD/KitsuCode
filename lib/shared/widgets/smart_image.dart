import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

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

    final int? cacheWidth = width != null ? (width! * 2).round() : null;
    final int? cacheHeight = height != null ? (height! * 2).round() : null;

    if (esUrlDeRed) {
      return CachedNetworkImage(
        imageUrl: path,
        width: width,
        height: height,
        fit: fit,

        memCacheWidth: cacheWidth,
        memCacheHeight: cacheHeight,

        placeholder: (context, url) => Container(
          width: width,
          height: height,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),

        errorWidget: (context, url, error) {
          return Container(
            width: width,
            height: height,
            color: Theme.of(context).colorScheme.surfaceContainer,
            child: Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.outline,
            ),
          );
        },
      );
    } else {
      return Image.asset(
        path,
        width: width,
        height: height,
        fit: fit,

        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Theme.of(context).colorScheme.surfaceContainer,
            child: Icon(
              Icons.image_not_supported_outlined,
              color: Theme.of(context).colorScheme.outline,
            ),
          );
        },
      );
    }
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.backgroundColor = const Color(0xFFF3F4F6),
    this.placeholderIcon = Icons.image_outlined,
    this.errorIcon = Icons.image_not_supported_outlined,
  });

  final String imageUrl;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Color backgroundColor;
  final IconData placeholderIcon;
  final IconData errorIcon;

  @override
  Widget build(BuildContext context) {
    final content = imageUrl.isEmpty
        ? _FallbackImage(
            backgroundColor: backgroundColor,
            icon: placeholderIcon,
          )
        : CachedNetworkImage(
            imageUrl: imageUrl,
            fit: fit,
            placeholder: (context, url) => _FallbackImage(
              backgroundColor: backgroundColor,
              child: const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              ),
            ),
            errorWidget: (context, url, error) => _FallbackImage(
              backgroundColor: backgroundColor,
              icon: errorIcon,
            ),
          );

    if (borderRadius == null) {
      return content;
    }

    return ClipRRect(borderRadius: borderRadius!, child: content);
  }
}

class _FallbackImage extends StatelessWidget {
  const _FallbackImage({required this.backgroundColor, this.icon, this.child});

  final Color backgroundColor;
  final IconData? icon;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: backgroundColor),
      child: Center(
        child:
            child ??
            Icon(
              icon ?? Icons.image_outlined,
              size: 30,
              color: const Color(0xFF94A3B8),
            ),
      ),
    );
  }
}

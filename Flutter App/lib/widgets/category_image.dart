import 'dart:typed_data';

import 'package:flutter/material.dart';

class CategoryImage extends StatelessWidget {
  const CategoryImage({
    super.key,
    this.imageUrl,
    this.imageBytes,
    this.borderRadius,
  });

  final String? imageUrl;
  final Uint8List? imageBytes;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final value = imageUrl?.trim() ?? '';
    final image = imageBytes != null
        ? _memoryImage(imageBytes!)
        : value.isEmpty
        ? const _CategoryImageFallback()
        : value.toLowerCase().startsWith('data:image/')
        ? _dataImage(value)
        : Image.network(
            value,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) =>
                progress == null ? child : const _CategoryImageLoading(),
            errorBuilder: (context, error, stackTrace) =>
                const _CategoryImageFallback(),
          );

    return borderRadius == null
        ? image
        : ClipRRect(borderRadius: borderRadius!, child: image);
  }

  Widget _dataImage(String value) {
    try {
      return _memoryImage(
        Uint8List.fromList(UriData.parse(value).contentAsBytes()),
      );
    } on FormatException {
      return const _CategoryImageFallback();
    }
  }

  Widget _memoryImage(Uint8List bytes) => Image.memory(
    bytes,
    fit: BoxFit.cover,
    errorBuilder: (context, error, stackTrace) =>
        const _CategoryImageFallback(),
  );
}

class _CategoryImageLoading extends StatelessWidget {
  const _CategoryImageLoading();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Color(0xFFF3F4F6),
    child: Center(
      child: SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.2),
      ),
    ),
  );
}

class _CategoryImageFallback extends StatelessWidget {
  const _CategoryImageFallback();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Color(0xFFF3F4F6),
    child: Center(
      child: Icon(Icons.category_outlined, size: 30, color: Color(0xFF94A3B8)),
    ),
  );
}

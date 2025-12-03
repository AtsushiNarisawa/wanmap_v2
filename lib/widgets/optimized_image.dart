import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// 遅延読み込みとキャッシュを備えた最適化された画像ウィジェット
class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) =>
          placeholder ??
          Container(
            color: Colors.grey[300],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      errorWidget: (context, url, error) =>
          errorWidget ??
          Container(
            color: Colors.grey[300],
            child: const Icon(Icons.error, color: Colors.red),
          ),
      // メモリキャッシュの設定（画像をメモリに保存する際のサイズ）
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
      // キャッシュ最適化（画像デコード時のサイズ制限でメモリ使用量を削減）
      cacheWidth: (width != null && width! > 0) ? (width! * 2).toInt() : null,
      cacheHeight: (height != null && height! > 0) ? (height! * 2).toInt() : null,
      // 最大キャッシュサイズ（ディスクキャッシュの上限）
      maxWidthDiskCache: 1000,
      maxHeightDiskCache: 1000,
    );
  }
}

/// サムネイル用の最適化された画像ウィジェット（小さいサイズ）
class OptimizedThumbnail extends StatelessWidget {
  final String imageUrl;
  final double size;

  const OptimizedThumbnail({
    super.key,
    required this.imageUrl,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return OptimizedImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      placeholder: Container(
        width: size,
        height: size,
        color: Colors.grey[300],
        child: const Icon(Icons.image, size: 24, color: Colors.grey),
      ),
    );
  }
}
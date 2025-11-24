import 'package:flutter/material.dart';
import '../services/photo_service.dart';
import 'photo_viewer.dart';

/// 散歩写真グリッド表示ウィジェット（Phase 3拡張）
class WalkPhotoGrid extends StatelessWidget {
  final List<WalkPhoto> photos;
  final int maxPhotosToShow;

  const WalkPhotoGrid({
    super.key,
    required this.photos,
    this.maxPhotosToShow = 3,
  });

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayPhotos = photos.take(maxPhotosToShow).toList();
    final remainingCount = photos.length - maxPhotosToShow;

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: displayPhotos.length,
        itemBuilder: (context, index) {
          final photo = displayPhotos[index];
          final isLast = index == displayPhotos.length - 1;
          final showMoreIndicator = isLast && remainingCount > 0;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () {
                // 写真タップで拡大表示
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PhotoViewer(
                      photoUrls: photos.map((p) => p.publicUrl).toList(),
                      initialIndex: index,
                    ),
                  ),
                );
              },
              child: Stack(
                children: [
                  // 写真サムネイル
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      photo.publicUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[300],
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                  // +N枚表示（最後の写真に重ねる）
                  if (showMoreIndicator)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '+$remainingCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

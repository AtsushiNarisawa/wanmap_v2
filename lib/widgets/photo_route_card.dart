import 'package:flutter/material.dart';
import '../models/route_model.dart';
import '../models/area_info.dart';

/// 写真付きルートカード
class PhotoRouteCard extends StatelessWidget {
  final RouteModel route;
  final VoidCallback? onTap;

  const PhotoRouteCard({
    super.key,
    required this.route,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final area = route.area != null ? AreaInfo.getById(route.area!) : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 170,
          child: Row(
            children: [
              // 左: サムネイル画像
              _buildThumbnail(context),
              
              // 右: ルート情報
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 公開バッジ + エリアバッジ
                      Row(
                        children: [
                          // 公開バッジ
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.public, size: 12, color: Colors.white),
                                SizedBox(width: 2),
                                Text(
                                  '公開',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // エリアバッジ
                          if (area != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '${area.emoji} ${area.displayName}',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // タイトル
                      Text(
                        route.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // エリア・都道府県
                      if (route.prefecture != null)
                        Text(
                          route.prefecture!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      
                      const Spacer(),
                      
                      // 統計情報
                      Row(
                        children: [
                          Icon(Icons.straighten, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${(route.distance / 1000).toStringAsFixed(1)}km',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.timer, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${(route.duration / 60).toStringAsFixed(0)}分',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // 日付といいね（TODO: いいね数は後で実装）
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            route.formatDate(),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                          // TODO: いいね数を表示
                          // const Spacer(),
                          // Row(
                          //   children: [
                          //     Icon(Icons.favorite, size: 14, color: Colors.red[300]),
                          //     const SizedBox(width: 4),
                          //     Text('15', style: TextStyle(fontSize: 11)),
                          //   ],
                          // ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// サムネイル画像を構築
  Widget _buildThumbnail(BuildContext context) {
    return Container(
      width: 150,
      height: 170,
      decoration: BoxDecoration(
        color: Colors.grey[300],
      ),
      child: route.thumbnailUrl != null
          ? Image.network(
              route.thumbnailUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildPlaceholder(context);
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
            )
          : _buildPlaceholder(context),
    );
  }

  /// プレースホルダー画像（写真がない場合）
  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pets,
            size: 60,
            color: Theme.of(context).primaryColor.withOpacity(0.3),
          ),
          const SizedBox(height: 8),
          Text(
            '写真なし',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).primaryColor.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

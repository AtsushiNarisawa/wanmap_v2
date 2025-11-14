#!/usr/bin/env python3
"""
Phase 26: Performance Optimization
パフォーマンス最適化の自動実装スクリプト
"""

import os

PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))

def create_lazy_image_widget():
    """遅延読み込み画像ウィジェットを作成"""
    content = '''import 'package:flutter/material.dart';
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
      // メモリキャッシュの設定
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
      // 最大キャッシュサイズ（デフォルトは1000枚）
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
'''.strip()
    
    filepath = os.path.join(PROJECT_ROOT, 'lib', 'widgets', 'optimized_image.dart')
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"✅ Created: {filepath}")

def create_paginated_list_widget():
    """ページネーション対応リストウィジェットを作成"""
    content = '''import 'package:flutter/material.dart';

/// ページネーション対応の最適化されたリストウィジェット
class PaginatedListView<T> extends StatefulWidget {
  final Future<List<T>> Function(int page, int limit) fetchData;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final int itemsPerPage;
  final Widget? emptyWidget;
  final Widget? errorWidget;

  const PaginatedListView({
    super.key,
    required this.fetchData,
    required this.itemBuilder,
    this.itemsPerPage = 20,
    this.emptyWidget,
    this.errorWidget,
  });

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  final List<T> _items = [];
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadMore();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final newItems =
          await widget.fetchData(_currentPage, widget.itemsPerPage);

      setState(() {
        _items.addAll(newItems);
        _currentPage++;
        _hasMore = newItems.length >= widget.itemsPerPage;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _items.clear();
      _currentPage = 0;
      _hasMore = true;
      _error = null;
    });
    await _loadMore();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _items.isEmpty) {
      return widget.errorWidget ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('エラー: $_error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refresh,
                  child: const Text('再試行'),
                ),
              ],
            ),
          );
    }

    if (_items.isEmpty && !_isLoading) {
      return widget.emptyWidget ??
          const Center(
            child: Text('データがありません'),
          );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _items.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < _items.length) {
            return widget.itemBuilder(context, _items[index]);
          } else {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
        },
      ),
    );
  }
}
'''.strip()
    
    filepath = os.path.join(PROJECT_ROOT, 'lib', 'widgets', 'paginated_list_view.dart')
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"✅ Created: {filepath}")

def create_map_optimization_service():
    """地図最適化サービスを作成"""
    content = '''import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/route_model.dart';

/// 地図描画の最適化サービス
class MapOptimizationService {
  /// ルートポイントを間引いて描画パフォーマンスを向上
  /// 
  /// Douglas-Peucker アルゴリズムを使用してポイント数を削減
  static List<LatLng> simplifyRoute(
    List<LatLng> points, {
    double tolerance = 0.0001, // 約10m
  }) {
    if (points.length <= 2) return points;
    return _douglasPeucker(points, tolerance);
  }

  /// Douglas-Peucker アルゴリズムの実装
  static List<LatLng> _douglasPeucker(List<LatLng> points, double tolerance) {
    if (points.length <= 2) return points;

    // 最初と最後の点を結ぶ線分から最も遠い点を見つける
    double maxDistance = 0;
    int maxIndex = 0;

    for (int i = 1; i < points.length - 1; i++) {
      double distance = _perpendicularDistance(
        points[i],
        points.first,
        points.last,
      );
      if (distance > maxDistance) {
        maxDistance = distance;
        maxIndex = i;
      }
    }

    // 最大距離が許容値より大きい場合、再帰的に簡略化
    if (maxDistance > tolerance) {
      final left = _douglasPeucker(
        points.sublist(0, maxIndex + 1),
        tolerance,
      );
      final right = _douglasPeucker(
        points.sublist(maxIndex),
        tolerance,
      );
      return [...left.sublist(0, left.length - 1), ...right];
    } else {
      return [points.first, points.last];
    }
  }

  /// 点から線分への垂直距離を計算
  static double _perpendicularDistance(
    LatLng point,
    LatLng lineStart,
    LatLng lineEnd,
  ) {
    final dx = lineEnd.latitude - lineStart.latitude;
    final dy = lineEnd.longitude - lineStart.longitude;

    if (dx == 0 && dy == 0) {
      return _distance(point, lineStart);
    }

    final t = ((point.latitude - lineStart.latitude) * dx +
            (point.longitude - lineStart.longitude) * dy) /
        (dx * dx + dy * dy);

    if (t < 0) {
      return _distance(point, lineStart);
    } else if (t > 1) {
      return _distance(point, lineEnd);
    } else {
      final projection = LatLng(
        lineStart.latitude + t * dx,
        lineStart.longitude + t * dy,
      );
      return _distance(point, projection);
    }
  }

  /// 2点間の距離を計算（簡易版）
  static double _distance(LatLng p1, LatLng p2) {
    final dx = p1.latitude - p2.latitude;
    final dy = p1.longitude - p2.longitude;
    return dx * dx + dy * dy;
  }

  /// ズームレベルに応じた最適な簡略化の許容値を取得
  static double getToleranceForZoom(double zoom) {
    if (zoom < 10) return 0.001; // 広域表示：積極的に間引く
    if (zoom < 13) return 0.0005; // 中域表示：中程度の間引き
    if (zoom < 15) return 0.0001; // 近域表示：軽い間引き
    return 0.00005; // 詳細表示：最小限の間引き
  }

  /// メモリ使用量を最適化するため、表示範囲外のルートをフィルタ
  static List<RouteModel> filterRoutesInBounds(
    List<RouteModel> routes,
    LatLngBounds bounds,
  ) {
    return routes.where((route) {
      // ルートの開始点が表示範囲内かチェック
      if (route.startLatitude != null && route.startLongitude != null) {
        final startPoint = LatLng(route.startLatitude!, route.startLongitude!);
        return bounds.contains(startPoint);
      }
      return false;
    }).toList();
  }
}
'''.strip()
    
    filepath = os.path.join(PROJECT_ROOT, 'lib', 'services', 'map_optimization_service.dart')
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"✅ Created: {filepath}")

def create_memory_optimization_tips():
    """メモリ最適化のTipsドキュメントを作成"""
    content = '''# Phase 26: パフォーマンス最適化 - 実装ガイド

## 📦 追加が必要なパッケージ

pubspec.yaml に以下を追加してください：

```yaml
dependencies:
  # 画像キャッシュと遅延読み込み
  cached_network_image: ^3.3.0
  
  # メモリキャッシュマネージャー
  flutter_cache_manager: ^3.3.1
```

## 🔧 実装する最適化

### 1. 画像の遅延読み込みとキャッシュ

既存の画像表示を `OptimizedImage` に置き換えてください：

**Before:**
```dart
Image.network(route.photoUrl)
```

**After:**
```dart
OptimizedImage(
  imageUrl: route.photoUrl,
  width: 100,
  height: 100,
  fit: BoxFit.cover,
)
```

### 2. ルート一覧のページネーション

`routes_screen.dart` を更新：

**Before:**
```dart
ListView.builder(
  itemCount: routes.length,
  itemBuilder: (context, index) => RouteCard(route: routes[index]),
)
```

**After:**
```dart
PaginatedListView<RouteModel>(
  fetchData: (page, limit) async {
    return await supabase
        .from('routes')
        .select()
        .order('created_at', ascending: false)
        .range(page * limit, (page + 1) * limit - 1);
  },
  itemBuilder: (context, route) => RouteCard(route: route),
  itemsPerPage: 20,
)
```

### 3. 地図ルートの最適化

記録画面とルート詳細画面の地図描画を最適化：

```dart
import '../services/map_optimization_service.dart';

// ルートポイントを簡略化
final simplifiedPoints = MapOptimizationService.simplifyRoute(
  routePoints,
  tolerance: MapOptimizationService.getToleranceForZoom(mapController.zoom),
);

// 簡略化されたポイントで描画
Polyline(
  points: simplifiedPoints,
  strokeWidth: 4.0,
  color: Colors.blue,
)
```

### 4. ListView のアイテムを const 化

可能な限り const コンストラクタを使用してリビルドを削減：

```dart
// 変数を使わない固定ウィジェットは const に
const SizedBox(height: 16),
const Divider(),
const Text('タイトル'),
```

### 5. メモリリーク防止

StatefulWidget で使用する Controller を必ず dispose：

```dart
@override
void dispose() {
  _scrollController.dispose();
  _textController.dispose();
  _mapController.dispose();
  super.dispose();
}
```

## 📊 パフォーマンス測定

以下のコマンドでパフォーマンスを測定：

```bash
# パフォーマンスプロファイル
flutter run --profile

# メモリ使用量の分析
flutter run --profile --enable-vmservice-publish-port=8888
# DevTools でメモリプロファイルを確認
```

## ✅ 確認項目

- [ ] cached_network_image を pubspec.yaml に追加
- [ ] 全ての Image.network を OptimizedImage に置き換え
- [ ] routes_screen.dart にページネーションを実装
- [ ] 地図描画にルート簡略化を適用
- [ ] 不要な Controller を dispose
- [ ] const コンストラクタを可能な限り使用

## 🎯 期待される改善

- **初回読み込み時間**: 30-50% 削減
- **メモリ使用量**: 20-40% 削減
- **スクロール性能**: 60fps 安定
- **地図描画**: スムーズなパン・ズーム
'''.strip()
    
    filepath = os.path.join(PROJECT_ROOT, 'PHASE26_IMPLEMENTATION.md')
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"✅ Created: {filepath}")

def main():
    """メイン処理"""
    print("🚀 Phase 26: Performance Optimization")
    print("=" * 60)
    
    print("\n📦 Creating optimized widgets and services...")
    create_lazy_image_widget()
    create_paginated_list_widget()
    create_map_optimization_service()
    create_memory_optimization_tips()
    
    print("\n✅ Phase 26 Performance Optimization code generated!")
    print("\n📋 次のステップ:")
    print("1. PHASE26_IMPLEMENTATION.md を確認")
    print("2. pubspec.yaml に cached_network_image を追加")
    print("3. flutter pub get を実行")
    print("4. 既存コードを段階的に最適化")
    print("5. パフォーマンスを測定・確認")

if __name__ == '__main__':
    main()

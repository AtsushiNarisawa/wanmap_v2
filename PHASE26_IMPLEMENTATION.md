# Phase 26: パフォーマンス最適化 - 実装ガイド

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
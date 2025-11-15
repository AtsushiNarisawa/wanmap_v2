# 公開ルート画面の改善提案

## 📋 現状分析

### 現在の実装
- シンプルなリストビュー
- 公開ルートをカード形式で縦に表示
- エリアフィルタリング機能なし
- マップビューなし
- 写真表示なし

### 課題
1. **視覚的魅力の不足**: テキストのみで写真がない
2. **地理的コンテキストの欠如**: どのエリアのルートかわからない
3. **ルート位置の把握困難**: 地図上での位置が見えない
4. **検索性の低さ**: エリアでフィルタリングできない

## 🎯 改善提案

### 新しいUI構成

```
┌─────────────────────────────────────┐
│ 公開ルート                [🔍]      │
├─────────────────────────────────────┤
│ 📍 エリア選択                       │
│ ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐         │
│ │箱│ │伊│ │那│ │軽│ │全│         │
│ │根│ │豆│ │須│ │井│ │て│         │
│ └──┘ └──┘ └──┘ └──┘ └──┘         │
│  (選択中は青色ハイライト)           │
├─────────────────────────────────────┤
│ 🗺️ マップビュー           [展開▼]  │
│ ┌─────────────────────────────────┐ │
│ │                                 │ │
│ │   📍 OpenStreetMap              │ │
│ │   ━━ ルート1（青）              │ │
│ │   ━━ ルート2（緑）              │ │
│ │   ━━ ルート3（赤）              │ │
│ │                                 │ │
│ │   タップでルート詳細へ          │ │
│ └─────────────────────────────────┘ │
│ 高さ: 250px (折りたたみ可能)        │
├─────────────────────────────────────┤
│ 📸 ルート一覧                       │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ ┌───┐                           │ │
│ │ │写真│ 箱根大涌谷散策コース       │ │
│ │ │150│ 箱根町                     │ │
│ │ │x  │ 5.2km ・ 1.5時間          │ │
│ │ │150│ ⭐️ 15件のいいね           │ │
│ │ └───┘                           │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ ┌───┐                           │ │
│ │ │写真│ 箱根神社参拝ルート         │ │
│ │ └───┘ ...                       │ │
│ └─────────────────────────────────┘ │
│                                     │
│ (無限スクロール)                    │
└─────────────────────────────────────┘
```

## 🔧 必要な実装

### 1. データベース拡張（Phase A）

#### routesテーブルに追加
```sql
ALTER TABLE public.routes 
ADD COLUMN area VARCHAR(50),
ADD COLUMN prefecture VARCHAR(50),
ADD COLUMN thumbnail_url TEXT;

-- インデックス追加
CREATE INDEX idx_routes_area ON public.routes(area);
CREATE INDEX idx_routes_is_public ON public.routes(is_public);
```

#### エリアマスターデータ
```dart
class AreaInfo {
  final String id;
  final String name;
  final LatLng center; // 中心座標
  final LatLngBounds bounds; // 表示範囲
  final String prefecture;
  
  // 例: '箱根', '伊豆', '那須', '軽井沢'
}
```

### 2. RouteModel拡張（Phase B）

```dart
class RouteModel {
  // 既存フィールド
  final String? id;
  final String userId;
  final String title;
  // ...
  
  // 🆕 新規追加フィールド
  final String? area;        // 'hakone', 'izu', 'nasu'
  final String? prefecture;  // '神奈川県', '静岡県', '栃木県'
  final String? thumbnailUrl; // 代表写真のURL
}
```

### 3. UI実装（Phase C）

#### 3-1. エリア選択チップ
```dart
class AreaSelectionChips extends StatefulWidget {
  final String? selectedArea;
  final Function(String?) onAreaSelected;
  
  // 'all', 'hakone', 'izu', 'nasu', 'karuizawa'
}
```

#### 3-2. マップビュー（折りたたみ可能）
```dart
class PublicRoutesMapView extends StatefulWidget {
  final List<RouteModel> routes;
  final bool isExpanded;
  final Function(String routeId) onRouteTapped;
  
  // flutter_mapを使用
  // 複数ルートを異なる色で表示
  // タップでルート詳細へ遷移
}
```

#### 3-3. 写真付きルートカード
```dart
class PhotoRouteCard extends StatelessWidget {
  final RouteModel route;
  
  // 左: サムネイル画像 (150x150)
  // 右: タイトル、エリア、統計、いいね数
}
```

### 4. サービス拡張（Phase D）

```dart
class RouteService {
  // 🆕 エリアでフィルタリング
  Future<List<RouteModel>> getPublicRoutesByArea(
    String area, {
    int limit = 20,
    int offset = 0,
  });
  
  // 🆕 範囲内のルート取得（マップビュー用）
  Future<List<RouteModel>> getPublicRoutesInBounds(
    LatLngBounds bounds, {
    int limit = 100,
  });
  
  // 🆕 サムネイル画像取得
  Future<String?> getRouteThumbnail(String routeId);
}
```

## 📊 実装の段階的アプローチ

### Phase 1: データ準備（必須）
- [ ] データベースにarea, prefecture, thumbnail_urlカラム追加
- [ ] RouteModelにフィールド追加
- [ ] 既存ルートへのエリア情報の追加（手動/自動）

### Phase 2: エリア選択機能（中優先度）
- [ ] エリアマスターデータ作成
- [ ] エリア選択チップUI実装
- [ ] エリアフィルタリング機能実装

### Phase 3: マップビュー（高優先度）
- [ ] 折りたたみ可能なマップビュー実装
- [ ] 複数ルートの同時表示
- [ ] ルートタップでの詳細遷移

### Phase 4: 写真付きカード（高優先度）
- [ ] route_photosからサムネイル取得
- [ ] 写真付きカードUI実装
- [ ] いいね数の表示

### Phase 5: パフォーマンス最適化（低優先度）
- [ ] 無限スクロール実装
- [ ] 画像キャッシング
- [ ] マップタイルキャッシング

## 🎨 デザイン詳細

### エリアチップ
- **未選択**: 白背景、グレー枠線
- **選択中**: プライマリカラー背景、白文字
- **サイズ**: 60x60 (正方形)
- **配置**: 横スクロール可能

### マップビュー
- **デフォルト高さ**: 250px
- **展開時**: 400px
- **折りたたみボタン**: 右上に配置
- **ルート色**: 複数ルートを異なる色で表示（青、緑、赤、オレンジ）

### 写真付きカード
- **サムネイル**: 左側150x150px
- **コンテンツ**: 右側に情報表示
- **カード高さ**: 最低170px
- **余白**: カード間12px

## 🚀 推奨実装順序

Atsushiさんの要望を考慮した推奨順序：

### 最優先（今すぐ実装）
1. **写真付きルートカード** - 視覚的魅力を即座に向上
2. **マップビュー** - 地理的コンテキストを提供

### 次の優先度
3. **エリア選択機能** - 検索性向上

### 将来的に
4. パフォーマンス最適化
5. 高度なフィルタリング（距離、難易度など）

## 💡 実装上の注意点

### データの後方互換性
- 既存ルートは`area`がnullの可能性
- `area`がnullの場合は「その他」として表示
- GPS座標から自動的にエリアを推定する機能を検討

### サムネイル画像の取得
```dart
// route_photosテーブルから最初の写真を取得
SELECT storage_path 
FROM route_photos 
WHERE route_id = ? 
ORDER BY display_order ASC 
LIMIT 1;
```

### マップビューのパフォーマンス
- 表示するルート数を制限（最大20本）
- 簡略化されたポリライン（ポイント数を削減）
- 遅延読み込み

## 📝 実装確認事項

Atsushiさんへの確認事項：

1. **エリアの範囲**: 
   - 「箱根」「伊豆」「那須」以外に追加したいエリアは？
   - 「軽井沢」「富士山周辺」「鎌倉」なども候補？

2. **マップビューの優先度**:
   - 最初から表示する？それとも折りたたんでおく？
   - デフォルトで表示するルート数は？（10本？20本？）

3. **写真の優先度**:
   - サムネイルサイズは150x150で良い？
   - 写真がないルートの扱いは？（デフォルト画像？非表示？）

4. **実装順序**:
   - Phase 1（データ準備）→ Phase 3（マップ）→ Phase 4（写真）の順で良い？
   - それともPhase 4（写真）を最優先？

## 🎯 期待される効果

### ユーザー体験の向上
1. **視覚的魅力**: 写真でルートの雰囲気がわかる
2. **地理的理解**: 地図でルートの位置がわかる
3. **検索効率**: エリアでフィルタリングできる
4. **発見性**: 地図上で近くのルートを発見できる

### エンゲージメント向上
- 滞在時間の増加
- ルート閲覧数の増加
- 公開ルートの作成意欲向上
- ソーシャル機能の活用促進

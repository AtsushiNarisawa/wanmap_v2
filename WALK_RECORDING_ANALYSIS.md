# 散歩記録機能の現状分析と実装戦略
**Date**: 2025-11-27
**Purpose**: 過去の失敗を振り返り、確実な実装計画を立てる

---

## 🔍 現状分析

### ✅ 既に実装されているもの

#### 1. バックエンド（Supabase）
- ✅ `walks`テーブル: 存在確認済み
- ✅ `walk_type`: 'daily' または 'outing'
- ✅ PostGIS対応: `path_geography` カラム
- ✅ トリガー: 自動更新・速度計算

#### 2. サービス層
**File**: `lib/services/walk_save_service.dart`
- ✅ `saveDailyWalk()`: Daily Walk保存
- ✅ `saveRouteWalk()`: Outing Walk保存  
- ✅ `saveWalk()`: 自動振り分け
- ✅ `deleteWalk()`: 削除機能
- ✅ `getWalkHistory()`: 履歴取得

**Key Features**:
```dart
// GeoJSON変換
pathGeoJson = {
  'type': 'LineString',
  'coordinates': [[lng, lat], [lng, lat], ...]
};

// walks テーブルに保存
await _supabase.from('walks').insert({
  'user_id': userId,
  'walk_type': 'daily', // or 'outing'
  'route_id': officialRouteId, // outingのみ
  'start_time': startTime,
  'end_time': endTime,
  'distance_meters': distance,
  'duration_seconds': duration,
  'path_geojson': pathGeoJson,
});
```

#### 3. UI画面
**File**: `lib/screens/daily/daily_walking_screen.dart`
- ✅ GPS記録開始
- ✅ リアルタイム追跡
- ✅ 写真撮影機能
- ✅ 保存処理（WalkSaveService使用）
- ✅ 写真アップロード（PhotoService使用）

**File**: `lib/screens/outing/walking_screen.dart`
- ✅ GPS記録開始
- ✅ 公式ルート表示
- ✅ ピン投稿機能
- ⚠️ 保存処理（要確認）

#### 4. GPS Provider
**File**: `lib/providers/gps_provider_riverpod.dart`
- ✅ リアルタイム位置追跡
- ✅ 距離・時間計算
- ✅ RouteModel生成

---

## ❌ 未実装・問題のあるもの

### 問題1: Outing Walk保存が未実装？
**Status**: 要確認

**確認ポイント**:
1. `walking_screen.dart`（Outing Walk画面）で保存処理が呼ばれているか？
2. `officialRouteId`が正しく渡されているか？

### 問題2: 保存エラーハンドリング
**Status**: 不十分

**問題**:
- ネットワークエラー時の挙動
- バリデーションエラー
- GPS記録が不十分な場合（2ポイント未満）

### 問題3: 統計更新
**Status**: 未確認

**確認ポイント**:
1. 散歩保存後、`get_user_walk_statistics`が正しく更新されるか？
2. バッジ獲得チェックが動作するか？

### 問題4: テストデータ
**Status**: 不足

**問題**:
- 実際に散歩記録を保存してテストしていない
- Macでの動作検証が不十分

---

## 🎯 実装戦略（3段階アプローチ）

### Phase 1: Daily Walk完全動作確認（30分）⭐
**目標**: 既存のDaily Walk機能が動作することを確認

#### 1-1. コード確認（10分）
- [ ] `daily_walking_screen.dart`の保存処理を詳しく確認
- [ ] エラーハンドリングが十分か確認
- [ ] GPS記録が2ポイント以上あるか確認

#### 1-2. Mac実機テスト（15分）
- [ ] Daily Walk画面を開く
- [ ] GPS記録を開始
- [ ] 少なくとも2ポイント以上記録
- [ ] 保存ボタンを押す
- [ ] Supabase `walks`テーブルを確認
- [ ] Profile画面で統計が更新されているか確認

#### 1-3. エラー修正（5分）
- [ ] 発生したエラーをログから特定
- [ ] 必要な修正を実施

**成功条件**:
- ✅ `walks`テーブルに1件のdaily walkが保存される
- ✅ `total_walks`が1増える
- ✅ `distance_meters`が記録される

---

### Phase 2: Outing Walk完全動作確認（45分）⭐⭐
**目標**: Outing Walk保存機能を実装・確認

#### 2-1. コード確認（15分）
- [ ] `walking_screen.dart`（Outing Walk）を確認
- [ ] 保存処理が呼ばれているか確認
- [ ] `officialRouteId`が渡されているか確認

#### 2-2. 未実装の場合は実装（20分）
- [ ] 終了ボタンの処理を追加
- [ ] `WalkSaveService.saveWalk()`を呼び出し
- [ ] `walkMode: WalkMode.outing`を指定
- [ ] `officialRouteId`を渡す

#### 2-3. Mac実機テスト（10分）
- [ ] Outing Walk画面を開く（公式ルート選択）
- [ ] GPS記録を開始
- [ ] 2ポイント以上記録
- [ ] ピンを投稿（任意）
- [ ] 保存ボタンを押す
- [ ] Supabase `walks`テーブルを確認
- [ ] `walk_type='outing'`で保存されているか確認
- [ ] `route_id`が正しいか確認

**成功条件**:
- ✅ `walks`テーブルにouting walkが保存される
- ✅ `total_outing_walks`が1増える
- ✅ `routes_completed`が更新される

---

### Phase 3: RLS有効化（30分）⭐
**目標**: `routes`と`route_points`テーブルのセキュリティ強化

#### 3-1. 現状確認（5分）
- [ ] Supabaseダッシュボードで確認
- [ ] `routes`テーブル: RLS無効（Unprotected）
- [ ] `route_points`テーブル: RLS無効（Unprotected）

#### 3-2. RLSポリシー作成（15分）
```sql
-- routes テーブル
ALTER TABLE routes ENABLE ROW LEVEL SECURITY;

-- 全ユーザーが公式ルートを閲覧可能
CREATE POLICY "Anyone can view official routes"
  ON routes FOR SELECT
  USING (true);

-- 管理者のみが編集可能（将来のため）
CREATE POLICY "Only admins can modify routes"
  ON routes FOR ALL
  USING (auth.uid() IN (SELECT id FROM profiles WHERE is_admin = true));
```

```sql
-- route_points テーブル
ALTER TABLE route_points ENABLE ROW LEVEL SECURITY;

-- 全ユーザーがルートポイントを閲覧可能
CREATE POLICY "Anyone can view route points"
  ON route_points FOR SELECT
  USING (true);

-- 管理者のみが編集可能
CREATE POLICY "Only admins can modify route points"
  ON route_points FOR ALL
  USING (auth.uid() IN (SELECT id FROM profiles WHERE is_admin = true));
```

#### 3-3. テスト（10分）
- [ ] Mac実機でアプリ再起動
- [ ] 公式ルートが表示されるか確認
- [ ] Map上のルートマーカーが表示されるか確認
- [ ] エラーログがないか確認

**成功条件**:
- ✅ RLS有効化後もルートが表示される
- ✅ エラーログなし
- ✅ Supabaseで「Protected」表示

---

## 🚨 過去の失敗から学ぶ

### 失敗1: スキーマ確認不足
**問題**: カラム名の不一致（今日の経験）
- `route_title` vs `route_name`
- `route_area` vs `area_name`

**対策**:
```sql
-- 必ず実行
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'walks';
```

### 失敗2: Null安全性の欠如
**問題**: LEFT JOINのNULL値でクラッシュ

**対策**:
```dart
// ❌ 危険
routeId: json['route_id'] as String

// ✅ 安全
routeId: (json['route_id'] as String?) ?? ''
```

### 失敗3: テスト不足
**問題**: 実機テストせずにコミット

**対策**:
- 必ずMac実機でテスト
- Supabaseテーブルを直接確認
- エラーログを全て確認

---

## 📋 実装チェックリスト

### Phase 1: Daily Walk（30分）
- [ ] `daily_walking_screen.dart`コード確認
- [ ] Mac実機でDaily Walk記録
- [ ] Supabase `walks`テーブル確認（`walk_type='daily'`）
- [ ] 統計更新確認（`total_walks`増加）
- [ ] エラー修正（必要な場合）
- [ ] Git commit

### Phase 2: Outing Walk（45分）
- [ ] `walking_screen.dart`コード確認
- [ ] 保存処理実装（未実装の場合）
- [ ] Mac実機でOuting Walk記録
- [ ] Supabase `walks`テーブル確認（`walk_type='outing'`, `route_id`あり）
- [ ] 統計更新確認（`total_outing_walks`増加）
- [ ] エラー修正
- [ ] Git commit

### Phase 3: RLS有効化（30分）
- [ ] Supabaseで現状確認
- [ ] RLS有効化SQL実行
- [ ] ポリシー作成SQL実行
- [ ] Mac実機でルート表示確認
- [ ] エラーログ確認
- [ ] Supabaseで「Protected」確認
- [ ] Git commit（SQLファイル）

---

## 💡 推奨実装順序

### 🥇 最優先: Phase 1（Daily Walk）
**理由**:
- 既存コードがある
- 比較的シンプル
- 成功体験を得やすい

**時間**: 30分
**リスク**: 低

---

### 🥈 次優先: Phase 2（Outing Walk）
**理由**:
- Daily Walkの経験を活かせる
- ピン機能との連携が必要
- コア機能として重要

**時間**: 45分
**リスク**: 中

---

### 🥉 最後: Phase 3（RLS）
**理由**:
- 機能追加ではなくセキュリティ強化
- アプリの動作に影響しにくい
- 確実に実施できる

**時間**: 30分
**リスク**: 低

---

## 🎯 Atsushiさんへの提案

### おすすめの進め方

**今日（残り時間）: Phase 1のみ**
- Daily Walk機能の動作確認
- 実機テストで成功体験
- 確実に1つ完了させる

**次回: Phase 2 + Phase 3**
- Outing Walk実装
- RLS有効化
- 完全な散歩記録機能の完成

---

## 🚀 次のアクション

**Atsushiさん、どのPhaseから始めますか？**

### 選択肢:

**A. Phase 1（Daily Walk）** - 推奨⭐⭐⭐
- 30分で完了
- 既存コード活用
- 確実な成功

**B. Phase 2（Outing Walk）** - 挑戦⭐⭐
- 45分
- 実装が必要かも
- やりがいあり

**C. Phase 3（RLS）** - 安全⭐
- 30分
- 確実に完了
- セキュリティ向上

**D. 全体像を見てから決める**
- 各Phaseの詳細確認
- 実装コードを見る
- 慎重に判断

**どれから始めますか？（A/B/C/D）**

# 未実装機能・未対応問題 - 優先順位リスト
**Date**: 2025-11-27
**Status**: Ready for Implementation

---

## 📊 現在のアプリ状態

### ✅ 正常動作中の機能
- Home画面（エリア一覧、クイックアクション）
- Map画面（地図表示、ルートマーカー、GPS）
- エリアデータ取得（3エリア: 箱根/横浜/鎌倉）
- ルートデータ取得（18ルート: 各エリア6件）
- ピン投稿機能（写真アップロード含む）
- 認証システム

### ⚠️ 未実装・エラーが出ている機能
1. ユーザー統計表示（RPC関数未実装）
2. お出かけ散歩履歴（Nullエラー）
3. 散歩記録機能（Phase 3 未完成）
4. タイムライン機能
5. プロフィール画面の一部

---

## 🎯 優先順位付き実装リスト

### 🔥 High Priority（今すぐ取り組むべき）

#### 1. ユーザー統計RPC関数の実装 ⭐⭐⭐
**現在のエラー:**
```
Error getting user statistics: PostgrestException(
  message: Could not find the function 
  public.get_user_walk_statistics(p_user_id) in the schema cache
)
```

**影響範囲:**
- Profile画面のユーザー統計が表示されない
- レベル、総距離、散歩回数が全て0のまま

**必要な作業:**
1. Supabase SQL Editorで `get_user_walk_statistics` RPC関数を作成
2. `walks`テーブルから統計データを集計
3. Mac実機でテスト

**推定時間:** 30-45分
**難易度:** ⭐⭐ (中)
**価値:** ⭐⭐⭐ (高)

**実装SQL（予想）:**
```sql
CREATE OR REPLACE FUNCTION get_user_walk_statistics(p_user_id uuid)
RETURNS TABLE (
  total_distance_meters double precision,
  total_duration_minutes integer,
  total_walks integer,
  areas_visited integer,
  current_level integer
)
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COALESCE(SUM(w.distance_meters), 0.0) AS total_distance_meters,
    COALESCE(SUM(w.duration_minutes), 0) AS total_duration_minutes,
    COALESCE(COUNT(w.id), 0)::integer AS total_walks,
    COALESCE(COUNT(DISTINCT w.area_id), 0)::integer AS areas_visited,
    FLOOR(COALESCE(SUM(w.distance_meters), 0.0) / 10000)::integer AS current_level
  FROM walks w
  WHERE w.user_id = p_user_id;
END;
$$;
```

---

#### 2. お出かけ散歩履歴のNullエラー修正 ⭐⭐⭐
**現在のエラー:**
```
Error fetching outing walk history: 
type 'Null' is not a subtype of type 'String' in type cast
```

**影響範囲:**
- Records画面で散歩履歴が表示されない
- お出かけモードで記録した散歩が見れない

**必要な作業:**
1. `lib/services/walk_history_service.dart` のエラー箇所を特定
2. `WalkHistory.fromJson` のNull安全性を確認
3. `walks`テーブルのNULLABLEカラムを確認

**推定時間:** 20-30分
**難易度:** ⭐⭐ (中)
**価値:** ⭐⭐⭐ (高)

**調査すべきファイル:**
- `lib/services/walk_history_service.dart`
- `lib/models/walk_history.dart`
- Supabase `walks`テーブルのスキーマ

---

### 🟡 Medium Priority（次に取り組むべき）

#### 3. Daily Walk（日常散歩）記録機能の完成 ⭐⭐
**現在の状態:**
- GPS追跡: ✅ 実装済み
- ルート記録: ⚠️ 一部実装
- 保存機能: ❌ 未実装

**影響範囲:**
- Dailyモードで散歩を記録できない
- `walks`テーブルにデータが保存されない

**必要な作業:**
1. `WalkingScreen` での保存ボタン実装
2. `walks`テーブルへの保存処理
3. `walk_points`テーブルへのGPSポイント保存

**推定時間:** 1-2時間
**難易度:** ⭐⭐⭐ (高)
**価値:** ⭐⭐⭐ (高)

---

#### 4. Outing Walk（おでかけ散歩）完了後の保存 ⭐⭐
**現在の状態:**
- GPS追跡: ✅ 実装済み
- ピン投稿: ✅ 実装済み
- 散歩完了: ❌ 保存機能未実装

**影響範囲:**
- お出かけ散歩を記録できない
- バッジ獲得条件が満たされない

**必要な作業:**
1. `OutingWalkingScreen` での完了処理
2. `walks`テーブルへの保存
3. バッジチェック処理の呼び出し

**推定時間:** 1-2時間
**難易度:** ⭐⭐⭐ (高)
**価値:** ⭐⭐⭐ (高)

---

#### 5. タイムライン機能の実装 ⭐⭐
**現在の状態:**
- RPC関数: ✅ `get_following_timeline` 実装済み
- UI: ❌ 未実装

**必要な作業:**
1. `TimelineScreen` の実装
2. フォロー中ユーザーの投稿表示
3. いいね・コメント機能

**推定時間:** 2-3時間
**難易度:** ⭐⭐⭐ (高)
**価値:** ⭐⭐ (中)

---

### 🟢 Low Priority（余裕があれば）

#### 6. プロフィール編集機能 ⭐
**現在の状態:**
- プロフィール表示: ✅ 実装済み
- 編集機能: ❌ 未実装

**必要な作業:**
1. プロフィール編集画面の作成
2. アイコン画像アップロード
3. `profiles`テーブルの更新処理

**推定時間:** 1-2時間
**難易度:** ⭐⭐ (中)
**価値:** ⭐⭐ (中)

---

#### 7. 犬プロフィール登録 ⭐
**現在の状態:**
- `dogs`テーブル: ✅ 作成済み
- UI: ❌ 未実装

**必要な作業:**
1. 犬プロフィール登録画面
2. 写真アップロード
3. 複数頭対応

**推定時間:** 1-2時間
**難易度:** ⭐⭐ (中)
**価値:** ⭐⭐ (中)

---

#### 8. RLS（Row Level Security）の有効化 ⭐
**現在の状態:**
- `routes`: ❌ RLS無効（Unprotected）
- `route_points`: ❌ RLS無効（Unprotected）

**セキュリティリスク:**
- 誰でもルートデータを編集可能
- データ整合性の問題

**必要な作業:**
1. `routes`テーブルのRLS有効化
2. `route_points`テーブルのRLS有効化
3. ポリシー設定（SELECT/INSERT/UPDATE/DELETE）

**推定時間:** 30-45分
**難易度:** ⭐⭐ (中)
**価値:** ⭐⭐⭐ (高 - セキュリティ)

---

## 🎯 推奨実装順序

### Phase A: クリティカルバグ修正（今日中）
1. ✅ `get_areas_simple` RPC復旧 - **完了！**
2. ⏳ `get_user_walk_statistics` RPC実装（30-45分）
3. ⏳ お出かけ散歩履歴Nullエラー修正（20-30分）

**合計推定時間:** 50-75分

---

### Phase B: コア機能完成（今週中）
4. Daily Walk記録機能（1-2時間）
5. Outing Walk保存機能（1-2時間）
6. RLS有効化（30-45分）

**合計推定時間:** 2.5-4.5時間

---

### Phase C: ソーシャル機能（来週以降）
7. タイムライン機能（2-3時間）
8. プロフィール編集（1-2時間）
9. 犬プロフィール登録（1-2時間）

**合計推定時間:** 4-7時間

---

## 💡 Atsushiさんへの提案

### 🔥 今日のおすすめ実装
**優先度1: ユーザー統計RPC実装**
- 理由: 短時間で大きな価値が得られる
- 影響: Profile画面が完全に機能する
- 時間: 30-45分
- 難易度: 中

**優先度2: お出かけ散歩履歴エラー修正**
- 理由: Records画面を使えるようにする
- 影響: 散歩履歴が表示される
- 時間: 20-30分
- 難易度: 中

**合計: 約1時間で2つの主要問題を解決！**

---

## 📋 実装チェックリスト

### ユーザー統計RPC実装
- [ ] Supabaseで`walks`テーブル構造確認
- [ ] `get_user_walk_statistics` SQL作成
- [ ] Supabase SQL Editorで実行
- [ ] `SELECT * FROM get_user_walk_statistics('test-uuid')` でテスト
- [ ] Mac実機でアプリ再起動
- [ ] Profile画面で統計表示確認
- [ ] Git commit & push

### お出かけ散歩履歴エラー修正
- [ ] エラーログから該当箇所特定
- [ ] `lib/models/walk_history.dart` のNull安全性確認
- [ ] `lib/services/walk_history_service.dart` 修正
- [ ] Supabase `walks`テーブルスキーマ確認
- [ ] Mac実機でテスト
- [ ] Records画面で履歴表示確認
- [ ] Git commit & push

---

## 🎯 次のアクション

**Atsushiさん、どの問題から取り組みたいですか？**

### 選択肢:
**A. ユーザー統計RPC実装** (推奨⭐)
- 30-45分で完了
- Profile画面が完全動作
- 目に見える成果

**B. お出かけ散歩履歴エラー修正** (推奨⭐)
- 20-30分で完了
- Records画面が使える
- データ確認可能

**C. Daily Walk記録機能** (大きな挑戦⭐⭐⭐)
- 1-2時間
- コア機能の完成
- やりがいあり

**D. 全部見せて！** (完全リスト)
- すべての未実装機能詳細
- 優先順位付き
- 実装手順書

**どれから始めますか？（A/B/C/D）**

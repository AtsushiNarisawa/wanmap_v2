# 📋 既存ルートデータ精査ガイド

## 🎯 目的

既存のルートデータを精査し、不足している情報や誤りを修正するための完全ガイドです。

---

## 📊 ステップ1: 既存データのエクスポート

### Supabase SQL Editorでクエリ実行

1. **Supabase Dashboardにアクセス**
   ```
   https://supabase.com/dashboard/project/YOUR_PROJECT_ID/sql
   ```

2. **SQLクエリを実行**
   - `scripts/export_routes_query.sql` の内容をコピー
   - SQL Editorにペースト
   - 実行ボタンをクリック

3. **結果をCSVダウンロード**
   - 結果テーブル右上の「Download CSV」ボタンをクリック
   - ファイル名: `existing_routes_YYYYMMDD.csv` で保存

---

## ✅ ステップ2: データ精査チェックリスト

### 必須フィールドチェック

| 項目 | チェック内容 | 修正方法 |
|------|-------------|---------|
| **ルート名** | - 重複していないか<br>- 分かりやすい名称か | CSVまたはUPDATE文で修正 |
| **エリア** | - 正しいエリア名か<br>- 箱根は5サブエリアのいずれかか | 誤っている場合は正しいエリアに変更 |
| **距離km** | - 実際の距離と合っているか<br>- 0または空でないか | Google Maps等で確認・修正 |
| **所要時間分** | - 3.0km/h基準で計算されているか<br>- 計算式: `距離 ÷ 3.0 × 60` | Excelで一括再計算 |
| **難易度** | - `easy`, `moderate`, `hard` のいずれかか<br>- 実態と合っているか | 適切な値に修正 |

### ペット情報チェック

| 項目 | チェック内容 | 重要度 |
|------|-------------|--------|
| **駐車場情報** | 有無・料金が記載されているか | ⭐⭐⭐ |
| **路面状況** | 路面の種類と割合が記載されているか | ⭐⭐⭐ |
| **トイレ情報** | 場所が具体的に記載されているか | ⭐⭐⭐ |
| **水飲み場情報** | 場所が記載されているか | ⭐⭐ |
| **ペット関連施設** | 近隣施設の情報が記載されているか | ⭐⭐ |
| **その他備考** | リード着用等の注意事項が記載されているか | ⭐⭐ |

### 座標・軌跡データチェック

| 項目 | チェック内容 | 対処方法 |
|------|-------------|---------|
| **開始地点座標** | 入っているか | Google Mapsで取得・UPDATE |
| **終了地点座標** | 入っているか | Google Mapsで取得・UPDATE |
| **ルート軌跡** | `あり` になっているか | 未設定の場合は後日手動描画 |

### 画像データチェック

| 項目 | チェック内容 | 対処方法 |
|------|-------------|---------|
| **サムネイルURL** | 設定されているか | Unsplash等から取得・UPDATE |
| **写真URL1-3** | 複数枚設定されているか | ギャラリー用画像を追加 |

---

## 🔧 ステップ3: データ修正方法

### 方法A: CSV一括修正 → SQL再投入

**推奨**: 大量のルートを修正する場合

1. **エクスポートしたCSVを編集**
   ```
   existing_routes_YYYYMMDD.csv を Excel/Sheets で開く
   ```

2. **修正すべき項目を編集**
   - エリア名を正しいものに修正
   - 所要時間を再計算（`=距離km / 3.0 * 60`）
   - pet_info情報を充実させる

3. **CSV→SQL変換**
   ```bash
   python scripts/csv_to_sql.py fixed_routes.csv update_routes.sql
   ```

4. **生成されたSQLを確認・実行**
   - 座標情報を手動追加
   - Supabase SQL Editorで実行

### 方法B: Supabase SQL EditorでUPDATE文実行

**推奨**: 少数のルートを修正する場合

```sql
-- 例1: エリアを修正（箱根親エリア → 箱根・仙石原サブエリア）
UPDATE official_routes
SET area_id = 'a1111111-1111-1111-1111-111111111115'::uuid
WHERE id = '8d0b7773-cac3-4f5b-938b-f21e92b4c0fe'::uuid;

-- 例2: 所要時間を再計算（距離 ÷ 3.0 × 60）
UPDATE official_routes
SET estimated_duration_minutes = ROUND((distance_km / 3.0) * 60)
WHERE estimated_duration_minutes IS NULL OR estimated_duration_minutes = 0;

-- 例3: pet_infoを更新
UPDATE official_routes
SET pet_info = jsonb_set(
  COALESCE(pet_info, '{}'::jsonb),
  '{parking}',
  '"あり（DogHub駐車場・無料）"'
)
WHERE id = '8d0b7773-cac3-4f5b-938b-f21e92b4c0fe'::uuid;

-- 例4: サムネイルURLを設定
UPDATE official_routes
SET thumbnail_url = 'https://images.unsplash.com/photo-1528127269322-539801943592?w=800'
WHERE id = '8d0b7773-cac3-4f5b-938b-f21e92b4c0fe'::uuid
  AND thumbnail_url IS NULL;
```

---

## 📝 ステップ4: エリア再割り当て作業

### 箱根エリアの再割り当て

現在 `area_id = 'a1111111-1111-1111-1111-111111111111'`（箱根親エリア）になっているルートを、適切なサブエリアに再割り当てします。

| ルート名 | 現状エリア | 正しいエリア | 新しいarea_id |
|---------|-----------|-------------|--------------|
| DogHub周遊コース | 箱根（親） | **箱根・仙石原** | a1111111-1111-1111-1111-111111111115 |
| 芦ノ湖湖畔散歩コース | 箱根（親） | **箱根・芦ノ湖** | a1111111-1111-1111-1111-111111111116 |
| 箱根旧街道散歩道 | 箱根（親） | **箱根・湯本** | a1111111-1111-1111-1111-111111111112 |
| 芦ノ湖畔ロングウォーク | 箱根（親） | **箱根・芦ノ湖** | a1111111-1111-1111-1111-111111111116 |

**一括UPDATE SQL**:
```sql
-- DogHub周遊コース → 箱根・仙石原
UPDATE official_routes
SET area_id = 'a1111111-1111-1111-1111-111111111115'::uuid
WHERE title = 'DogHub周遊コース';

-- 芦ノ湖湖畔散歩コース → 箱根・芦ノ湖
UPDATE official_routes
SET area_id = 'a1111111-1111-1111-1111-111111111116'::uuid
WHERE title = '芦ノ湖湖畔散歩コース（元箱根港〜箱根公園）';

-- 箱根旧街道散歩道 → 箱根・湯本
UPDATE official_routes
SET area_id = 'a1111111-1111-1111-1111-111111111112'::uuid
WHERE title = '箱根旧街道散歩道';

-- 芦ノ湖畔ロングウォーク → 箱根・芦ノ湖
UPDATE official_routes
SET area_id = 'a1111111-1111-1111-1111-111111111116'::uuid
WHERE title = '芦ノ湖畔ロングウォーク';
```

---

## 🚨 よくある問題と対処法

### 問題1: 所要時間が不正確

**症状**: 距離に対して所要時間が短すぎる/長すぎる

**対処法**:
```sql
-- 全ルートの所要時間を3.0km/h基準で再計算
UPDATE official_routes
SET estimated_duration_minutes = ROUND((distance_km / 3.0) * 60);
```

### 問題2: pet_infoが空またはNULL

**症状**: ペット情報が何も入っていない

**対処法**:
```sql
-- 基本的なpet_info構造を追加
UPDATE official_routes
SET pet_info = '{
  "parking": "要確認",
  "surface": "要確認",
  "restroom": "要確認",
  "water_station": "要確認",
  "pet_facilities": "",
  "others": "リード着用必須"
}'::jsonb
WHERE pet_info IS NULL OR pet_info = '{}'::jsonb;
```

### 問題3: 座標データが未設定

**症状**: start_location / end_location が NULL

**対処法**:
1. Google Mapsで開始地点・終了地点の住所を検索
2. 座標を取得（右クリック → 座標をコピー）
3. UPDATE文で追加:
```sql
UPDATE official_routes
SET 
  start_location = ST_SetSRID(ST_MakePoint(139.1071, 35.2328), 4326)::geography,
  end_location = ST_SetSRID(ST_MakePoint(139.1071, 35.2328), 4326)::geography
WHERE id = '8d0b7773-cac3-4f5b-938b-f21e92b4c0fe'::uuid;
```

### 問題4: route_lineが未設定

**症状**: ルート軌跡が「なし」

**対処法**:
- これは正常です。route_lineは後日手動で描画します
- 緊急度: 低（表示には影響しません）

---

## 📊 精査後の確認クエリ

```sql
-- 1. エリアごとのルート数を確認
SELECT 
  a.name AS エリア名,
  COUNT(r.id) AS ルート数
FROM areas a
LEFT JOIN official_routes r ON r.area_id = a.id
GROUP BY a.id, a.name
ORDER BY a.name;

-- 2. pet_info未設定ルートを確認
SELECT 
  title AS ルート名,
  CASE 
    WHEN pet_info IS NULL THEN 'NULL'
    WHEN pet_info = '{}'::jsonb THEN '空オブジェクト'
    ELSE 'あり'
  END AS pet_info状態
FROM official_routes
WHERE pet_info IS NULL OR pet_info = '{}'::jsonb;

-- 3. 座標未設定ルートを確認
SELECT 
  title AS ルート名,
  CASE WHEN start_location IS NULL THEN '未設定' ELSE '設定済' END AS 開始地点,
  CASE WHEN end_location IS NULL THEN '未設定' ELSE '設定済' END AS 終了地点,
  CASE WHEN route_line IS NULL THEN '未設定' ELSE '設定済' END AS ルート軌跡
FROM official_routes;

-- 4. サムネイル未設定ルートを確認
SELECT 
  title AS ルート名,
  CASE WHEN thumbnail_url IS NULL OR thumbnail_url = '' THEN '未設定' ELSE '設定済' END AS サムネイル
FROM official_routes;
```

---

## 📅 作業スケジュール例

| フェーズ | 作業内容 | 所要時間 |
|---------|---------|---------|
| **Phase 1** | データエクスポート | 5分 |
| **Phase 2** | CSV精査（エリア・基本情報） | 30分 |
| **Phase 3** | pet_info情報の充実 | 1時間 |
| **Phase 4** | 座標データ追加 | 1時間 |
| **Phase 5** | サムネイル・画像追加 | 30分 |
| **Phase 6** | route_line描画（後日） | 2-3時間 |

**合計**: 約3-4時間（route_line除く）

---

## 🎯 完了基準

すべてのルートについて、以下の項目が満たされていること：

- ✅ エリアが正しく設定されている（箱根は5サブエリアのいずれか）
- ✅ 距離・所要時間が正確（3.0km/h基準）
- ✅ pet_info情報が充実している（最低限6項目すべて記入）
- ✅ 開始地点・終了地点の座標が設定されている
- ✅ サムネイルURLが設定されている
- ⚪ ギャラリー画像が1枚以上設定されている（推奨）
- ⚪ route_lineが設定されている（後日対応可）

---

**最終更新日**: 2024-12-22  
**作成者**: WanWalk開発チーム

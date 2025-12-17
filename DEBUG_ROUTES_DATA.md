# ルートデータのデバッグ手順

## 問題: 「近くのおすすめルート」が0件

現在地: `35.25241577122233,139.13942730090932` (神奈川県小田原市付近)
- 全ルート数: 13件
- 50km以内のルート: 0件

## 原因調査

### 1️⃣ ルートのstart_locationデータを確認

Supabase SQL Editorで以下のクエリを実行:

```sql
-- ルートの座標データを確認
SELECT 
  id,
  title,
  start_location,
  ST_AsText(start_location::geometry) as start_location_wkt,
  ST_Y(start_location::geometry) as start_lat,
  ST_X(start_location::geometry) as start_lon
FROM official_routes
WHERE is_active = TRUE
ORDER BY title;
```

### 2️⃣ 現在地からの距離を計算

```sql
-- 現在地から各ルートまでの距離を計算
WITH current_location AS (
  SELECT ST_SetSRID(ST_MakePoint(139.13942730090932, 35.25241577122233), 4326)::geography as point
)
SELECT 
  r.id,
  r.title,
  ST_Y(r.start_location::geometry) as start_lat,
  ST_X(r.start_location::geometry) as start_lon,
  ROUND(
    ST_Distance(
      r.start_location,
      (SELECT point FROM current_location)
    )::numeric / 1000,
    2
  ) as distance_km
FROM official_routes r
WHERE r.is_active = TRUE
ORDER BY distance_km ASC
LIMIT 20;
```

### 3️⃣ 50km以内のルートを抽出

```sql
-- 50km以内のルートを確認
WITH current_location AS (
  SELECT ST_SetSRID(ST_MakePoint(139.13942730090932, 35.25241577122233), 4326)::geography as point
)
SELECT 
  r.id,
  r.title,
  r.prefecture,
  r.area_name,
  ROUND(
    ST_Distance(
      r.start_location,
      (SELECT point FROM current_location)
    )::numeric / 1000,
    2
  ) as distance_km
FROM official_routes r
CROSS JOIN areas a ON a.id = r.area_id
WHERE r.is_active = TRUE
  AND ST_Distance(
    r.start_location,
    (SELECT point FROM current_location)
  ) <= 50000  -- 50km = 50,000m
ORDER BY distance_km ASC;
```

## 🔍 チェックポイント

### ケース1: start_locationがNULL
- **原因**: データ登録時に座標が設定されていない
- **解決策**: ルートデータを再登録

### ケース2: 座標が逆（緯度・経度の順序間違い）
- **症状**: start_lat, start_lonの値が逆になっている
- **解決策**: マイグレーションで座標を修正

### ケース3: 全てのルートが50km以上離れている
- **症状**: 最も近いルートでも50km以上
- **解決策**: 検索範囲を100kmに拡大

### ケース4: SRID（座標系）の問題
- **症状**: ST_Distance計算がおかしい
- **解決策**: GEOGRAPHY型を使用（すでに対応済み）

---

## 🛠️ 想定される修正案

### 修正1: 検索範囲を100kmに拡大

**map_tab.dart (line 856)**
```dart
// 現在: 50km
if (distance <= 50.0) {

// 修正案: 100km
if (distance <= 100.0) {
```

### 修正2: 座標の順序を修正（もし逆だった場合）

```sql
-- start_locationの座標を入れ替える
UPDATE official_routes
SET start_location = ST_SetSRID(
  ST_MakePoint(
    ST_Y(start_location::geometry),
    ST_X(start_location::geometry)
  ),
  4326
)::geography
WHERE is_active = TRUE;
```

### 修正3: デフォルトルートを追加

箱根エリア（現在地付近）にデフォルトルートを追加:

```sql
-- 箱根エリアIDを確認
SELECT id, name FROM areas WHERE prefecture = '神奈川県' AND name LIKE '%箱根%';

-- 新しいルートを追加（例: 箱根湯本周辺の散歩コース）
INSERT INTO official_routes (
  id,
  area_id,
  title,
  description,
  start_location,
  end_location,
  distance_meters,
  estimated_minutes,
  difficulty_level,
  is_official,
  is_active
) VALUES (
  gen_random_uuid(),
  'YOUR_AREA_ID_HERE',
  '箱根湯本駅周辺散策コース',
  '箱根湯本駅から早川沿いを歩く定番コース',
  ST_SetSRID(ST_MakePoint(139.1071, 35.2328), 4326)::geography,
  ST_SetSRID(ST_MakePoint(139.1071, 35.2328), 4326)::geography,
  2500,
  30,
  'easy',
  true,
  true
);
```

---

## 📊 予想される結果

### 正常な場合
- 13件のルートすべてで座標が正しく設定されている
- 現在地から最も近いルートの距離が表示される
- 50km以内に何件かのルートが存在する

### 異常な場合（現状）
- すべてのルートが50km以上離れている
- または座標データがNULL/不正

---

## ⚙️ デバッグログの追加（すでに実装済み）

**map_tab.dart**では以下のログが出力されます:

```dart
🔵 _getRecommendedRoutes: currentLocation=35.25241,139.13942
🔵 Total routes: 13
🔵 Route: ○○コース at XX.XXX,XXX.XXX - XX.Xkm  // 100km以内のルートのみ
✅ Found nearby route: ○○コース (XX.Xkm)          // 50km以内のルート
🔵 Total nearby routes (<=50km): 0
```

**期待されるログ:**
```
🔵 Route: 箱根湯本散策コース at 35.2328,139.1071 - 2.8km
✅ Found nearby route: 箱根湯本散策コース (2.8km)
🔵 Total nearby routes (<=50km): 1
```

---

## 📝 次のステップ

1. **上記SQLクエリを実行してルートデータを確認**
2. **結果をこのチャットに貼り付け**
3. **問題の原因を特定**
4. **適切な修正を実施**

---

**このファイルの場所**: `/home/user/webapp/wanmap_v2/DEBUG_ROUTES_DATA.md`

# 芦ノ湖畔ロングウォークを今月の人気1位にする手順（正しいテーブル構造版）

## ⚠️ 重要な修正

このスクリプトは、実際のデータベース構造（`walks`テーブル）に合わせて修正されたバージョンです。

### データベース構造の確認結果

✅ **実際のテーブル構造:**
- テーブル名: `walks`
- walk_type: `'outing'` または `'daily'`
- route_id: 公式ルートのID（outingの場合）

❌ **存在しないテーブル:**
- `route_walks` テーブルは存在しません

## 📋 実行手順

### ステップ1: RPC関数の修正（最初に1回だけ実行）

RPC関数が古い構造を参照している場合、まず修正が必要です。

**ファイル:** `fix_monthly_popular_routes_rpc_correct.sql`

1. Supabase SQL Editorを開く
2. 以下のSQLを実行：

```sql
CREATE OR REPLACE FUNCTION get_monthly_popular_official_routes(
  p_limit INT DEFAULT 10,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  route_id UUID,
  route_name TEXT,
  description TEXT,
  area_id UUID,
  area_name TEXT,
  prefecture TEXT,
  distance_meters NUMERIC,
  estimated_minutes INT,
  difficulty_level TEXT,
  total_walks INT,
  monthly_walks BIGINT,
  thumbnail_url TEXT,
  created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    r.id AS route_id,
    r.title AS route_name,
    r.description,
    r.area_id,
    a.name AS area_name,
    a.prefecture,
    r.distance_meters,
    r.estimated_minutes,
    r.difficulty AS difficulty_level,
    r.total_walks,
    COALESCE(COUNT(w.id) FILTER (WHERE w.start_time >= NOW() - INTERVAL '1 month'), 0) AS monthly_walks,
    r.thumbnail_url,
    r.created_at
  FROM official_routes r
  JOIN areas a ON a.id = r.area_id
  LEFT JOIN walks w ON w.route_id = r.id AND w.walk_type = 'outing'
  GROUP BY r.id, r.title, r.description, r.area_id, a.name, a.prefecture, 
           r.distance_meters, r.estimated_minutes, r.difficulty, r.total_walks, 
           r.thumbnail_url, r.created_at
  ORDER BY monthly_walks DESC, r.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;
```

### ステップ2: 芦ノ湖畔ロングウォークに散歩データを追加

**ファイル:** `make_ashinoko_route_top1_correct.sql`

1. Supabase SQL Editorで新しいクエリを作成
2. 以下の完全なSQLをコピー＆ペースト
3. 「Run」をクリック

```sql
-- =====================================================
-- 前提確認
-- =====================================================
DO $$
DECLARE
  v_route_id UUID := '6ae42d51-4221-4075-a2c7-cb8572e17cf7';
  v_route_name TEXT;
  v_user_id UUID;
  v_area_id UUID;
BEGIN
  SELECT title, area_id INTO v_route_name, v_area_id 
  FROM official_routes 
  WHERE id = v_route_id;
  
  IF v_route_name IS NULL THEN
    RAISE EXCEPTION 'ルートID % が見つかりません', v_route_id;
  END IF;
  
  SELECT id INTO v_user_id FROM auth.users ORDER BY created_at LIMIT 1;
  
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'ユーザーが見つかりません';
  END IF;
  
  RAISE NOTICE '✅ ルート確認: % (area_id: %)', v_route_name, v_area_id;
  RAISE NOTICE '✅ ユーザー確認: %', v_user_id;
END $$;

-- =====================================================
-- 30回の散歩データ追加
-- =====================================================
DO $$
DECLARE
  v_route_id UUID := '6ae42d51-4221-4075-a2c7-cb8572e17cf7';
  v_user_id UUID;
  v_area_id UUID;
  v_distance_meters NUMERIC;
  v_estimated_minutes INT;
  v_duration_seconds INT;
  i INT;
  v_days_ago INT;
  v_start_time TIMESTAMPTZ;
  v_end_time TIMESTAMPTZ;
BEGIN
  SELECT id INTO v_user_id FROM auth.users ORDER BY created_at LIMIT 1;
  
  SELECT area_id, distance_meters, estimated_minutes 
  INTO v_area_id, v_distance_meters, v_estimated_minutes
  FROM official_routes 
  WHERE id = v_route_id;
  
  v_duration_seconds := v_estimated_minutes * 60;
  
  IF v_user_id IS NOT NULL AND v_area_id IS NOT NULL THEN
    FOR i IN 1..30 LOOP
      v_days_ago := (i - 1);
      v_start_time := NOW() - (INTERVAL '1 day' * v_days_ago) + (INTERVAL '1 hour' * ((i % 12) + 8));
      v_end_time := v_start_time + (INTERVAL '1 second' * v_duration_seconds);
      
      INSERT INTO walks (
        user_id,
        walk_type,
        route_id,
        start_time,
        end_time,
        distance_meters,
        duration_seconds,
        path_geojson
      ) VALUES (
        v_user_id,
        'outing',
        v_route_id,
        v_start_time,
        v_end_time,
        v_distance_meters + (RANDOM() * 100)::INT - 50,
        v_duration_seconds + (RANDOM() * 600)::INT - 300,
        '{"type":"LineString","coordinates":[[139.0315,35.2034],[139.0325,35.2044]]}'
      );
    END LOOP;
    
    RAISE NOTICE '✅ 芦ノ湖畔ロングウォークに30回の散歩データを追加しました';
  ELSE
    RAISE EXCEPTION 'ユーザーまたはルートが見つかりません';
  END IF;
END $$;

-- =====================================================
-- 確認クエリ: 今月の人気ルートランキング
-- =====================================================
SELECT 
  r.title AS route_name,
  a.name AS area_name,
  COUNT(w.id) FILTER (WHERE w.start_time >= NOW() - INTERVAL '1 month') AS monthly_walks,
  r.distance_meters / 1000.0 AS distance_km,
  r.estimated_minutes
FROM official_routes r
JOIN areas a ON a.id = r.area_id
LEFT JOIN walks w ON w.route_id = r.id AND w.walk_type = 'outing'
GROUP BY r.id, r.title, a.name, r.distance_meters, r.estimated_minutes
ORDER BY monthly_walks DESC
LIMIT 10;
```

## 🔍 期待される実行結果

### ① 前提確認の通知
```
NOTICE: ✅ ルート確認: 芦ノ湖畔ロングウォーク (area_id: xxx-xxx-xxx)
NOTICE: ✅ ユーザー確認: xxx-xxx-xxx
```

### ② データ追加の通知
```
NOTICE: ✅ 芦ノ湖畔ロングウォークに30回の散歩データを追加しました
```

### ③ ランキング結果
```
route_name              | area_name | monthly_walks | distance_km | estimated_minutes
------------------------|-----------|---------------|-------------|------------------
芦ノ湖畔ロングウォーク  | 箱根      | 30            | 5.2         | 75
[他のルート...]         | ...       | <30           | ...         | ...
```

## 📱 アプリでの確認

1. Flutter アプリを起動
2. **ホーム画面**の「人気急上昇ルート」セクションを確認
3. **芦ノ湖畔ロングウォークが1位**に表示される

## 🔧 トラブルシューティング

### エラー: "ルートID xxx が見つかりません"

**原因:** 芦ノ湖畔ロングウォークが登録されていない

**解決方法:** `insert_ashinoko_lakeside_route.sql`を先に実行

### エラー: "ユーザーが見つかりません"

**原因:** auth.usersテーブルにユーザーが存在しない

**解決方法:** アプリでユーザー登録を行う

### エラー: "relation walks does not exist"

**原因:** walksテーブルが存在しない

**解決方法:** データベースのマイグレーションを実行

## 📊 テーブル構造の確認

現在のデータベース構造を確認するには：

```sql
-- walksテーブルの構造
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'walks' 
ORDER BY ordinal_position;

-- 散歩データの確認
SELECT 
  walk_type,
  COUNT(*) as count
FROM walks
GROUP BY walk_type;
```

## 📝 データのリセット

芦ノ湖畔ロングウォークのデータをリセットする場合：

```sql
DELETE FROM walks 
WHERE route_id = '6ae42d51-4221-4075-a2c7-cb8572e17cf7'
  AND walk_type = 'outing';
```

## 🔄 関連ファイル

- `make_ashinoko_route_top1_correct.sql` - 散歩データ追加スクリプト（正しい版）
- `fix_monthly_popular_routes_rpc_correct.sql` - RPC関数修正スクリプト（正しい版）
- `insert_ashinoko_lakeside_route.sql` - ルート作成スクリプト
- `insert_test_outing_walk_correct.sql` - テストデータ作成の参考例

## ✨ 完了

これで芦ノ湖畔ロングウォークが今月の人気1位になります！

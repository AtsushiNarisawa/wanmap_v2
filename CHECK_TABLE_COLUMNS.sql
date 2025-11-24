-- ============================================================
-- テーブルのカラム構造を正確に確認するクエリ
-- ============================================================
-- まず、どんなカラムが存在するのか確認します
-- ============================================================

-- areasテーブルのカラム一覧
SELECT 
    column_name,
    data_type,
    udt_name,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'areas'
ORDER BY ordinal_position;

-- official_routesテーブルのカラム一覧
SELECT 
    column_name,
    data_type,
    udt_name,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'official_routes'
ORDER BY ordinal_position;

-- official_route_pointsテーブルのカラム一覧
SELECT 
    column_name,
    data_type,
    udt_name,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'official_route_points'
ORDER BY ordinal_position;

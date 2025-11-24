-- routesテーブルのカラム構造を確認
SELECT 
    column_name,
    data_type,
    udt_name,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'routes'
ORDER BY ordinal_position;

-- routesテーブルのデータ件数を確認
SELECT COUNT(*) as total_routes FROM routes;

-- routesテーブルの最初の5件を確認
SELECT 
    id,
    title,
    area_id,
    distance_meters,
    duration_seconds,
    difficulty,
    is_public
FROM routes
LIMIT 5;

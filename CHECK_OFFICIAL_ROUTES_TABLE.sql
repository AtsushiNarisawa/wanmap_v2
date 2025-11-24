-- official_routesテーブルのカラム構造を確認
SELECT 
    column_name,
    data_type,
    udt_name,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'official_routes'
ORDER BY ordinal_position;

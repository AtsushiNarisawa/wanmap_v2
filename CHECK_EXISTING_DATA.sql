-- 現在のデータベースの状態を確認

-- 1. areasテーブルの既存データ
SELECT 
    id,
    name,
    prefecture,
    description,
    ST_AsText(center_point::geometry) as center_point_wkt
FROM areas
ORDER BY name;

-- 2. official_routesテーブルの既存データ
SELECT 
    id,
    area_id,
    name,
    description,
    distance_meters,
    estimated_minutes,
    difficulty_level
FROM official_routes
ORDER BY name;

-- 3. official_route_pointsテーブルの既存データ
SELECT 
    id,
    official_route_id,
    sequence,
    ST_AsText(point::geometry) as point_wkt,
    elevation
FROM official_route_points
ORDER BY official_route_id, sequence
LIMIT 20;

-- 4. データ件数サマリー
SELECT 
    'areas' as table_name,
    COUNT(*) as count
FROM areas
UNION ALL
SELECT 
    'official_routes' as table_name,
    COUNT(*) as count
FROM official_routes
UNION ALL
SELECT 
    'official_route_points' as table_name,
    COUNT(*) as count
FROM official_route_points;

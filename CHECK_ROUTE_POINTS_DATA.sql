-- official_route_pointsテーブルの既存データを確認
SELECT 
    id,
    official_route_id,
    sequence,
    ST_AsText(point::geometry) as point_wkt,
    elevation,
    created_at
FROM official_route_points
ORDER BY official_route_id, sequence
LIMIT 20;

-- データ件数も確認
SELECT COUNT(*) as total_points FROM official_route_points;

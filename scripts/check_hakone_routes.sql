-- =====================================================
-- 箱根エリアのコース一覧を確認
-- =====================================================

-- 箱根エリアのIDを確認
SELECT id, name AS area_name
FROM areas
WHERE name LIKE '%箱根%';

-- 箱根エリアのコース一覧
SELECT 
  r.id,
  r.name AS route_name,
  r.description,
  r.thumbnail_url,
  r.distance_meters / 1000.0 AS distance_km,
  r.estimated_minutes,
  r.difficulty_level,
  a.name AS area_name
FROM official_routes r
JOIN areas a ON a.id = r.area_id
WHERE a.name LIKE '%箱根%'
ORDER BY r.name;

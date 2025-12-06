-- ========================================
-- スキーママイグレーション事前確認
-- 実行日: 2025-12-06
-- ========================================

-- 全エリアのルート数とピン数を確認
SELECT 
  a.name AS エリア名,
  COUNT(DISTINCT r.id) AS ルート数,
  COUNT(DISTINCT p.id) AS ピン数,
  COUNT(DISTINCT ph.id) AS 写真数
FROM areas a
LEFT JOIN official_routes r ON a.id = r.area_id
LEFT JOIN route_pins p ON r.id = p.route_id
LEFT JOIN route_pin_photos ph ON p.id = ph.pin_id
GROUP BY a.id, a.name
HAVING COUNT(DISTINCT r.id) > 0
ORDER BY a.name;

-- 箱根エリアの詳細データを確認
SELECT 
  id,
  name,
  distance_meters,
  estimated_minutes,
  difficulty_level,
  elevation_gain_meters,
  thumbnail_url IS NOT NULL AS has_thumbnail,
  array_length(gallery_images, 1) AS gallery_count,
  pet_info IS NOT NULL AS has_pet_info
FROM official_routes
WHERE area_id = 'a1111111-1111-1111-1111-111111111111'
ORDER BY distance_meters;

SELECT 'データ確認完了' AS status;

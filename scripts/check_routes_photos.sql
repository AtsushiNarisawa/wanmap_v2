-- =====================================================
-- 現状のコース一覧と写真の有無を確認
-- =====================================================

SELECT 
  id,
  title AS route_name,
  area_id,
  thumbnail_url,
  CASE 
    WHEN thumbnail_url IS NULL OR thumbnail_url = '' THEN '❌ 写真なし'
    ELSE '✅ 写真あり'
  END AS photo_status,
  distance_meters / 1000.0 AS distance_km,
  estimated_minutes,
  difficulty
FROM official_routes
ORDER BY 
  CASE 
    WHEN thumbnail_url IS NULL OR thumbnail_url = '' THEN 0
    ELSE 1
  END,
  title;

-- ========================================
-- 箱根エリア再割り当てスクリプト
-- 実行日: 2024-12-22
-- 目的: 箱根親エリアのルートを適切なサブエリアに再割り当て
-- ========================================

-- 現状確認
SELECT 
  r.id,
  r.title AS ルート名,
  a.name AS 現在のエリア,
  r.distance_km AS 距離km,
  r.estimated_duration_minutes AS 所要時間分
FROM official_routes r
LEFT JOIN areas a ON r.area_id = a.id
WHERE a.name LIKE '箱根%'
ORDER BY r.title;

-- ========================================
-- Phase 1: DogHub周遊コース → 箱根・仙石原
-- ========================================

UPDATE official_routes
SET 
  area_id = 'a1111111-1111-1111-1111-111111111115'::uuid,
  updated_at = now()
WHERE title = 'DogHub周遊コース'
  AND area_id = 'a1111111-1111-1111-1111-111111111111'::uuid;

-- ========================================
-- Phase 2: 芦ノ湖湖畔散歩コース → 箱根・芦ノ湖
-- ========================================

UPDATE official_routes
SET 
  area_id = 'a1111111-1111-1111-1111-111111111116'::uuid,
  updated_at = now()
WHERE title LIKE '芦ノ湖湖畔散歩コース%'
  AND area_id = 'a1111111-1111-1111-1111-111111111111'::uuid;

-- ========================================
-- Phase 3: 箱根旧街道散歩道 → 箱根・湯本
-- ========================================

UPDATE official_routes
SET 
  area_id = 'a1111111-1111-1111-1111-111111111112'::uuid,
  updated_at = now()
WHERE title = '箱根旧街道散歩道'
  AND area_id = 'a1111111-1111-1111-1111-111111111111'::uuid;

-- ========================================
-- Phase 4: 芦ノ湖畔ロングウォーク → 箱根・芦ノ湖
-- ========================================

UPDATE official_routes
SET 
  area_id = 'a1111111-1111-1111-1111-111111111116'::uuid,
  updated_at = now()
WHERE title = '芦ノ湖畔ロングウォーク'
  AND area_id = 'a1111111-1111-1111-1111-111111111111'::uuid;

-- ========================================
-- 結果確認
-- ========================================

SELECT 
  r.id,
  r.title AS ルート名,
  a.name AS 更新後エリア,
  r.distance_km AS 距離km,
  r.estimated_duration_minutes AS 所要時間分,
  r.updated_at AS 更新日時
FROM official_routes r
LEFT JOIN areas a ON r.area_id = a.id
WHERE a.name LIKE '箱根%'
ORDER BY a.name, r.title;

-- ========================================
-- エリアごとのルート数確認
-- ========================================

SELECT 
  a.name AS エリア名,
  COUNT(r.id) AS ルート数
FROM areas a
LEFT JOIN official_routes r ON r.area_id = a.id
WHERE a.name LIKE '箱根%'
GROUP BY a.id, a.name
ORDER BY a.name;

-- ========================================
-- 完了メッセージ
-- ========================================

SELECT '箱根エリア再割り当て完了' AS status;

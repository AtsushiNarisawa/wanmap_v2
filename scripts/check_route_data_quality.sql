-- ========================================
-- 既存ルートデータ精査用SQLクエリ集
-- 実行日: 2024-12-22
-- 目的: データの不足・誤りを一覧で確認
-- ========================================

-- ========================================
-- 1. 全体サマリー
-- ========================================

SELECT 
  '全ルート数' AS 項目,
  COUNT(*) AS 件数
FROM official_routes
UNION ALL
SELECT 
  'エリア未設定',
  COUNT(*)
FROM official_routes
WHERE area_id IS NULL
UNION ALL
SELECT 
  '座標未設定（開始地点）',
  COUNT(*)
FROM official_routes
WHERE start_location IS NULL
UNION ALL
SELECT 
  '座標未設定（終了地点）',
  COUNT(*)
FROM official_routes
WHERE end_location IS NULL
UNION ALL
SELECT 
  'route_line未設定',
  COUNT(*)
FROM official_routes
WHERE route_line IS NULL
UNION ALL
SELECT 
  'pet_info未設定',
  COUNT(*)
FROM official_routes
WHERE pet_info IS NULL OR pet_info = '{}'::jsonb
UNION ALL
SELECT 
  'サムネイル未設定',
  COUNT(*)
FROM official_routes
WHERE thumbnail_url IS NULL OR thumbnail_url = '';

-- ========================================
-- 2. エリア別ルート数
-- ========================================

SELECT 
  COALESCE(a.name, '未設定') AS エリア名,
  a.prefecture AS 都道府県,
  COUNT(r.id) AS ルート数
FROM areas a
LEFT JOIN official_routes r ON r.area_id = a.id
GROUP BY a.id, a.name, a.prefecture
ORDER BY 
  CASE 
    WHEN a.name LIKE '箱根%' THEN 1
    ELSE 2
  END,
  a.name;

-- ========================================
-- 3. 必須フィールド不足チェック
-- ========================================

SELECT 
  r.id,
  r.title AS ルート名,
  a.name AS エリア,
  CASE WHEN r.distance_km IS NULL OR r.distance_km = 0 THEN '❌ 未設定' ELSE '✅' END AS 距離,
  CASE WHEN r.estimated_duration_minutes IS NULL OR r.estimated_duration_minutes = 0 THEN '❌ 未設定' ELSE '✅' END AS 所要時間,
  CASE WHEN r.difficulty IS NULL OR r.difficulty = '' THEN '❌ 未設定' ELSE '✅' END AS 難易度,
  CASE WHEN r.description IS NULL OR r.description = '' THEN '❌ 未設定' ELSE '✅' END AS 説明
FROM official_routes r
LEFT JOIN areas a ON r.area_id = a.id
ORDER BY a.name, r.title;

-- ========================================
-- 4. pet_info詳細チェック
-- ========================================

SELECT 
  r.title AS ルート名,
  a.name AS エリア,
  CASE 
    WHEN r.pet_info IS NULL THEN '❌ NULL'
    WHEN r.pet_info = '{}'::jsonb THEN '❌ 空'
    WHEN r.pet_info->>'parking' IS NULL OR r.pet_info->>'parking' = '' THEN '⚠️ 駐車場情報なし'
    ELSE '✅ あり'
  END AS pet_info状態,
  CASE WHEN r.pet_info->>'parking' IS NOT NULL THEN '✅' ELSE '❌' END AS 駐車場,
  CASE WHEN r.pet_info->>'surface' IS NOT NULL THEN '✅' ELSE '❌' END AS 路面,
  CASE WHEN r.pet_info->>'restroom' IS NOT NULL THEN '✅' ELSE '❌' END AS トイレ,
  CASE WHEN r.pet_info->>'water_station' IS NOT NULL THEN '✅' ELSE '❌' END AS 水飲み場,
  CASE WHEN r.pet_info->>'pet_facilities' IS NOT NULL THEN '✅' ELSE '❌' END AS ペット施設,
  CASE WHEN r.pet_info->>'others' IS NOT NULL THEN '✅' ELSE '❌' END AS 備考
FROM official_routes r
LEFT JOIN areas a ON r.area_id = a.id
ORDER BY a.name, r.title;

-- ========================================
-- 5. 座標・軌跡データチェック
-- ========================================

SELECT 
  r.title AS ルート名,
  a.name AS エリア,
  CASE WHEN r.start_location IS NOT NULL THEN '✅' ELSE '❌ 未設定' END AS 開始地点,
  CASE WHEN r.end_location IS NOT NULL THEN '✅' ELSE '❌ 未設定' END AS 終了地点,
  CASE WHEN r.route_line IS NOT NULL THEN '✅' ELSE '⚪ 未設定（後日対応可）' END AS ルート軌跡
FROM official_routes r
LEFT JOIN areas a ON r.area_id = a.id
ORDER BY a.name, r.title;

-- ========================================
-- 6. 画像データチェック
-- ========================================

SELECT 
  r.title AS ルート名,
  a.name AS エリア,
  CASE WHEN r.thumbnail_url IS NOT NULL AND r.thumbnail_url != '' THEN '✅' ELSE '❌ 未設定' END AS サムネイル,
  CASE 
    WHEN array_length(r.gallery_images, 1) IS NULL THEN '❌ 0枚'
    WHEN array_length(r.gallery_images, 1) >= 3 THEN '✅ ' || array_length(r.gallery_images, 1) || '枚'
    ELSE '⚠️ ' || array_length(r.gallery_images, 1) || '枚（推奨3枚以上）'
  END AS ギャラリー画像
FROM official_routes r
LEFT JOIN areas a ON r.area_id = a.id
ORDER BY a.name, r.title;

-- ========================================
-- 7. 所要時間整合性チェック（3.0km/h基準）
-- ========================================

SELECT 
  r.title AS ルート名,
  a.name AS エリア,
  r.distance_km AS 距離km,
  r.estimated_duration_minutes AS 現在の所要時間分,
  ROUND((r.distance_km / 3.0) * 60) AS 正しい所要時間分,
  CASE 
    WHEN r.estimated_duration_minutes IS NULL THEN '❌ 未設定'
    WHEN ABS(r.estimated_duration_minutes - ROUND((r.distance_km / 3.0) * 60)) <= 5 THEN '✅ 正確'
    ELSE '⚠️ 要修正（差: ' || ABS(r.estimated_duration_minutes - ROUND((r.distance_km / 3.0) * 60))::text || '分）'
  END AS 整合性
FROM official_routes r
LEFT JOIN areas a ON r.area_id = a.id
WHERE r.distance_km IS NOT NULL AND r.distance_km > 0
ORDER BY a.name, r.title;

-- ========================================
-- 8. 箱根親エリア使用チェック
-- ========================================

SELECT 
  r.id,
  r.title AS ルート名,
  a.name AS 現在のエリア,
  '⚠️ サブエリアに再割り当て推奨' AS 推奨アクション
FROM official_routes r
LEFT JOIN areas a ON r.area_id = a.id
WHERE a.id = 'a1111111-1111-1111-1111-111111111111'::uuid;

-- ========================================
-- 9. 優先度別修正タスクリスト
-- ========================================

-- 優先度HIGH: 必須フィールド不足
SELECT 
  'HIGH: 必須フィールド不足' AS 優先度,
  r.title AS ルート名,
  '距離・所要時間・難易度のいずれかが未設定' AS 問題
FROM official_routes r
WHERE 
  r.distance_km IS NULL OR r.distance_km = 0
  OR r.estimated_duration_minutes IS NULL OR r.estimated_duration_minutes = 0
  OR r.difficulty IS NULL OR r.difficulty = ''

UNION ALL

-- 優先度MEDIUM: pet_info不足
SELECT 
  'MEDIUM: pet_info不足',
  r.title,
  'ペット情報が未設定または不完全'
FROM official_routes r
WHERE r.pet_info IS NULL 
  OR r.pet_info = '{}'::jsonb
  OR r.pet_info->>'parking' IS NULL

UNION ALL

-- 優先度MEDIUM: 座標未設定
SELECT 
  'MEDIUM: 座標未設定',
  r.title,
  '開始地点または終了地点の座標が未設定'
FROM official_routes r
WHERE r.start_location IS NULL OR r.end_location IS NULL

UNION ALL

-- 優先度LOW: サムネイル未設定
SELECT 
  'LOW: サムネイル未設定',
  r.title,
  'サムネイル画像が未設定'
FROM official_routes r
WHERE r.thumbnail_url IS NULL OR r.thumbnail_url = ''

ORDER BY 
  CASE 
    WHEN 優先度 = 'HIGH: 必須フィールド不足' THEN 1
    WHEN 優先度 = 'MEDIUM: pet_info不足' THEN 2
    WHEN 優先度 = 'MEDIUM: 座標未設定' THEN 3
    ELSE 4
  END,
  ルート名;

-- ========================================
-- 完了メッセージ
-- ========================================

SELECT '精査クエリ実行完了' AS status;

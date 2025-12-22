-- ========================================
-- WanWalk 既存ルートデータ取得クエリ
-- 生成日時: 2025-12-22 02:48:35
-- ========================================


-- 既存ルートデータを取得（CSV出力用）
SELECT 
  r.id AS ルートID,
  r.title AS ルート名,
  a.name AS エリア,
  a.prefecture AS 都道府県,
  r.description AS ルート説明,
  r.distance_km AS 距離km,
  r.estimated_duration_minutes AS 所要時間分,
  r.difficulty AS 難易度,
  r.elevation_gain_m AS 標高差m,
  
  -- pet_infoからJSON展開
  r.pet_info->>'parking' AS 駐車場情報,
  r.pet_info->>'surface' AS 路面状況,
  r.pet_info->>'restroom' AS トイレ情報,
  r.pet_info->>'water_station' AS 水飲み場情報,
  r.pet_info->>'pet_facilities' AS ペット関連施設,
  r.pet_info->>'others' AS その他備考,
  
  -- 座標情報
  CASE 
    WHEN r.start_location IS NOT NULL THEN 
      ST_Y(r.start_location::geometry) || ',' || ST_X(r.start_location::geometry)
    ELSE NULL
  END AS 開始地点座標,
  
  CASE 
    WHEN r.end_location IS NOT NULL THEN 
      ST_Y(r.end_location::geometry) || ',' || ST_X(r.end_location::geometry)
    ELSE NULL
  END AS 終了地点座標,
  
  -- route_line存在チェック
  CASE WHEN r.route_line IS NOT NULL THEN 'あり' ELSE 'なし' END AS ルート軌跡,
  
  -- サムネイル・ギャラリー
  r.thumbnail_url AS サムネイルURL,
  CASE 
    WHEN array_length(r.gallery_images, 1) > 0 THEN r.gallery_images[1]
    ELSE NULL
  END AS 写真URL1,
  CASE 
    WHEN array_length(r.gallery_images, 1) > 1 THEN r.gallery_images[2]
    ELSE NULL
  END AS 写真URL2,
  CASE 
    WHEN array_length(r.gallery_images, 1) > 2 THEN r.gallery_images[3]
    ELSE NULL
  END AS 写真URL3,
  
  -- 統計情報
  r.total_pins AS ピン数,
  r.total_walks AS 散歩回数,
  
  -- タイムスタンプ
  r.created_at AS 作成日時,
  r.updated_at AS 更新日時

FROM official_routes r
LEFT JOIN areas a ON r.area_id = a.id
ORDER BY a.name, r.title;

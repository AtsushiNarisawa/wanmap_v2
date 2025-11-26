-- =====================================================
-- Missing RPC Functions
-- =====================================================
-- 実行日: 2025-11-26
-- 目的: Flutter側で使用されているが未実装のRPC関数を追加

-- =====================================================
-- 1. check_spot_duplicate: スポット重複チェック
-- =====================================================
CREATE OR REPLACE FUNCTION check_spot_duplicate(
  spot_name TEXT,
  spot_lat FLOAT,
  spot_lng FLOAT,
  radius_meters FLOAT DEFAULT 50.0
)
RETURNS TABLE (
  id UUID,
  name TEXT,
  category TEXT,
  location JSONB,
  distance_meters FLOAT
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    s.id,
    s.name,
    s.category,
    jsonb_build_object(
      'type', 'Point',
      'coordinates', ARRAY[ST_X(s.location::geometry), ST_Y(s.location::geometry)]
    ) AS location,
    ST_Distance(
      s.location::geography,
      ST_MakePoint(spot_lng, spot_lat)::geography
    ) AS distance_meters
  FROM spots s
  WHERE s.is_active = TRUE
    AND s.name ILIKE '%' || spot_name || '%'
    AND ST_DWithin(
      s.location::geography,
      ST_MakePoint(spot_lng, spot_lat)::geography,
      radius_meters
    )
  ORDER BY distance_meters ASC
  LIMIT 10;
END;
$$;

COMMENT ON FUNCTION check_spot_duplicate IS 'スポット重複チェック（近隣50m以内の類似名称スポットを検索）';

-- =====================================================
-- 2. search_nearby_spots: 近隣スポット検索
-- =====================================================
CREATE OR REPLACE FUNCTION search_nearby_spots(
  user_lat FLOAT,
  user_lng FLOAT,
  search_radius_km FLOAT DEFAULT 10.0,
  category_filter TEXT DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  name TEXT,
  description TEXT,
  category TEXT,
  address TEXT,
  phone_number TEXT,
  website_url TEXT,
  opening_hours JSONB,
  location JSONB,
  distance_km FLOAT,
  photo_urls TEXT[],
  created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    s.id,
    s.name,
    s.description,
    s.category,
    s.address,
    s.phone_number,
    s.website_url,
    s.opening_hours,
    jsonb_build_object(
      'type', 'Point',
      'coordinates', ARRAY[ST_X(s.location::geometry), ST_Y(s.location::geometry)]
    ) AS location,
    ST_Distance(
      s.location::geography,
      ST_MakePoint(user_lng, user_lat)::geography
    ) / 1000.0 AS distance_km,
    s.photo_urls,
    s.created_at
  FROM spots s
  WHERE s.is_active = TRUE
    AND ST_DWithin(
      s.location::geography,
      ST_MakePoint(user_lng, user_lat)::geography,
      search_radius_km * 1000
    )
    AND (category_filter IS NULL OR s.category = category_filter)
  ORDER BY distance_km ASC
  LIMIT 50;
END;
$$;

COMMENT ON FUNCTION search_nearby_spots IS '近隣スポット検索（カテゴリフィルター対応）';

-- =====================================================
-- 3. get_user_walk_statistics: ユーザー散歩統計
-- =====================================================
CREATE OR REPLACE FUNCTION get_user_walk_statistics(
  p_user_id UUID
)
RETURNS TABLE (
  total_distance_km FLOAT,
  total_walks INT,
  total_duration_minutes INT,
  areas_visited INT,
  pins_created INT,
  routes_completed INT,
  current_level INT,
  level_progress FLOAT,
  badges_earned INT
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_total_distance FLOAT;
  v_total_walks INT;
  v_total_duration INT;
  v_areas_visited INT;
  v_pins_created INT;
  v_routes_completed INT;
  v_current_level INT;
  v_level_progress FLOAT;
  v_badges_earned INT;
BEGIN
  -- 総距離と総散歩回数（daily + outing）
  SELECT 
    COALESCE(SUM(distance_meters), 0) / 1000.0,
    COUNT(*)
  INTO v_total_distance, v_total_walks
  FROM (
    SELECT distance_meters FROM daily_walks WHERE user_id = p_user_id AND is_active = TRUE
    UNION ALL
    SELECT distance_meters FROM outing_walks WHERE user_id = p_user_id AND is_active = TRUE
  ) AS all_walks;

  -- 総所要時間
  SELECT COALESCE(SUM(duration_minutes), 0)
  INTO v_total_duration
  FROM (
    SELECT duration_minutes FROM daily_walks WHERE user_id = p_user_id AND is_active = TRUE
    UNION ALL
    SELECT duration_minutes FROM outing_walks WHERE user_id = p_user_id AND is_active = TRUE
  ) AS all_walks;

  -- 訪問エリア数
  SELECT COUNT(DISTINCT area_id)
  INTO v_areas_visited
  FROM outing_walks
  WHERE user_id = p_user_id AND is_active = TRUE;

  -- 作成ピン数
  SELECT COUNT(*)
  INTO v_pins_created
  FROM route_pins
  WHERE user_id = p_user_id AND is_active = TRUE;

  -- 完了ルート数
  SELECT COUNT(*)
  INTO v_routes_completed
  FROM outing_walks
  WHERE user_id = p_user_id AND is_active = TRUE;

  -- レベル計算（10kmごとに1レベル）
  v_current_level := FLOOR(v_total_distance / 10.0)::INT;
  v_level_progress := (v_total_distance - (v_current_level * 10.0)) / 10.0;

  -- 獲得バッジ数
  SELECT COUNT(*)
  INTO v_badges_earned
  FROM user_badges
  WHERE user_id = p_user_id;

  -- 結果を返す
  RETURN QUERY
  SELECT 
    v_total_distance,
    v_total_walks,
    v_total_duration,
    v_areas_visited,
    v_pins_created,
    v_routes_completed,
    v_current_level,
    v_level_progress,
    v_badges_earned;
END;
$$;

COMMENT ON FUNCTION get_user_walk_statistics IS 'ユーザーの散歩統計情報を集計（距離、回数、エリア、ピン、レベル等）';

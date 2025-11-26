-- =====================================================
-- Update search_routes function to use official_routes.thumbnail_url
-- =====================================================
-- 実行日: 2025-11-26
-- 目的: search_routes 関数で official_routes.thumbnail_url を使用

CREATE OR REPLACE FUNCTION search_routes(
  p_user_id UUID,
  p_query TEXT DEFAULT NULL,
  p_area_ids UUID[] DEFAULT NULL,
  p_difficulties TEXT[] DEFAULT NULL,
  p_min_distance_km DECIMAL DEFAULT NULL,
  p_max_distance_km DECIMAL DEFAULT NULL,
  p_min_duration_min INT DEFAULT NULL,
  p_max_duration_min INT DEFAULT NULL,
  p_features TEXT[] DEFAULT NULL,
  p_best_seasons TEXT[] DEFAULT NULL,
  p_sort_by TEXT DEFAULT 'popularity',
  p_limit INT DEFAULT 20,
  p_offset INT DEFAULT 0,
  p_user_lat FLOAT DEFAULT NULL,
  p_user_lon FLOAT DEFAULT NULL
)
RETURNS TABLE (
  route_id UUID,
  area_id UUID,
  area_name TEXT,
  route_name TEXT,
  description TEXT,
  difficulty TEXT,
  distance_km DECIMAL,
  estimated_duration_minutes INT,
  elevation_gain_m INT,
  features TEXT[],
  best_seasons TEXT[],
  total_walks INT,
  total_pins INT,
  average_rating DECIMAL,
  is_favorited BOOLEAN,
  thumbnail_url TEXT,
  start_location JSONB,
  distance_from_user_km DECIMAL
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    r.id AS route_id,
    r.area_id,
    a.display_name AS area_name,
    r.title AS route_name,
    r.description,
    r.difficulty,
    r.distance_km,
    r.estimated_duration_minutes,
    r.elevation_gain_m,
    r.features,
    r.best_seasons,
    r.total_walks,
    r.total_pins,
    r.average_rating,
    EXISTS(
      SELECT 1 FROM route_favorites rf 
      WHERE rf.route_id = r.id AND rf.user_id = p_user_id
    ) AS is_favorited,
    r.thumbnail_url,
    jsonb_build_object(
      'type', 'Point',
      'coordinates', ARRAY[ST_X(r.start_location::geometry), ST_Y(r.start_location::geometry)]
    ) AS start_location,
    CASE 
      WHEN p_user_lat IS NOT NULL AND p_user_lon IS NOT NULL THEN
        ST_Distance(
          r.start_location::geography,
          ST_MakePoint(p_user_lon, p_user_lat)::geography
        ) / 1000.0
      ELSE NULL
    END AS distance_from_user_km
  FROM official_routes r
  JOIN areas a ON a.id = r.area_id
  WHERE r.is_active = TRUE
    AND (
      p_query IS NULL OR
      r.title ILIKE '%' || p_query || '%' OR
      r.description ILIKE '%' || p_query || '%'
    )
    AND (p_area_ids IS NULL OR r.area_id = ANY(p_area_ids))
    AND (p_difficulties IS NULL OR r.difficulty = ANY(p_difficulties))
    AND (p_min_distance_km IS NULL OR r.distance_km >= p_min_distance_km)
    AND (p_max_distance_km IS NULL OR r.distance_km <= p_max_distance_km)
    AND (p_min_duration_min IS NULL OR r.estimated_duration_minutes >= p_min_duration_min)
    AND (p_max_duration_min IS NULL OR r.estimated_duration_minutes <= p_max_duration_min)
    AND (p_features IS NULL OR r.features && p_features)
    AND (p_best_seasons IS NULL OR r.best_seasons && p_best_seasons)
  ORDER BY 
    CASE 
      WHEN p_sort_by = 'nearby_first' AND p_user_lat IS NOT NULL AND p_user_lon IS NOT NULL THEN
        ST_Distance(
          r.start_location::geography,
          ST_MakePoint(p_user_lon, p_user_lat)::geography
        )
      ELSE NULL
    END ASC NULLS LAST,
    CASE 
      WHEN p_sort_by = 'popularity' THEN r.total_walks
      WHEN p_sort_by = 'rating' THEN COALESCE(r.average_rating, 0)::INT
      WHEN p_sort_by = 'newest' THEN EXTRACT(EPOCH FROM r.created_at)::INT
      ELSE 0
    END DESC,
    CASE 
      WHEN p_sort_by = 'distance_asc' THEN r.distance_km
      ELSE NULL
    END ASC,
    CASE 
      WHEN p_sort_by = 'distance_desc' THEN r.distance_km
      ELSE NULL
    END DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;

COMMENT ON FUNCTION search_routes IS '高度なルート検索（現在地からの距離、thumbnail_url対応）';

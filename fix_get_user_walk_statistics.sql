-- ============================================================================
-- Fix: Create get_user_walk_statistics RPC Function
-- ============================================================================
-- Date: 2025-11-27
-- Purpose: Restore missing get_user_walk_statistics function
-- Based on: database_migrations/001_walks_table_v4.sql (lines 270-348)
-- ============================================================================

-- Helper function: Calculate walk statistics from walks table
CREATE OR REPLACE FUNCTION calculate_walk_statistics(p_user_id UUID)
RETURNS TABLE(
  total_walks INTEGER,
  total_outing_walks INTEGER,
  total_distance_km DECIMAL,
  total_duration_hours DECIMAL,
  areas_visited INTEGER,
  routes_completed INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*)::INTEGER AS total_walks,
    COUNT(*) FILTER (WHERE walk_type = 'outing')::INTEGER AS total_outing_walks,
    COALESCE(SUM(distance_meters) / 1000.0, 0)::DECIMAL AS total_distance_km,
    COALESCE(SUM(duration_seconds) / 3600.0, 0)::DECIMAL AS total_duration_hours,
    -- Count unique areas from routes table (TEXT type)
    COUNT(DISTINCT r.area) FILTER (WHERE walk_type = 'outing' AND r.area IS NOT NULL)::INTEGER AS areas_visited,
    COUNT(DISTINCT route_id) FILTER (WHERE walk_type = 'outing')::INTEGER AS routes_completed
  FROM walks w
  LEFT JOIN routes r ON w.route_id = r.id
  WHERE w.user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Main function: Get user walk statistics
DROP FUNCTION IF EXISTS get_user_walk_statistics(UUID);

CREATE OR REPLACE FUNCTION get_user_walk_statistics(p_user_id UUID)
RETURNS TABLE(
  total_walks INTEGER,
  total_outing_walks INTEGER,
  total_distance_km DECIMAL,
  total_duration_hours DECIMAL,
  areas_visited INTEGER,
  routes_completed INTEGER,
  pins_created INTEGER,
  pins_liked_count INTEGER,
  followers_count INTEGER,
  following_count INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    -- Walk statistics (from walks table)
    ws.total_walks,
    ws.total_outing_walks,
    ws.total_distance_km,
    ws.total_duration_hours,
    ws.areas_visited,
    ws.routes_completed,
    -- Pin statistics (0 until pins table is created - Phase 1-2)
    0::INTEGER AS pins_created,
    0::INTEGER AS pins_liked_count,
    -- Social statistics (from existing user_follows table)
    COALESCE(follower_stats.followers_count, 0)::INTEGER AS followers_count,
    COALESCE(following_stats.following_count, 0)::INTEGER AS following_count
  FROM calculate_walk_statistics(p_user_id) ws
  -- Follower statistics
  LEFT JOIN LATERAL (
    SELECT COUNT(*)::INTEGER AS followers_count
    FROM user_follows
    WHERE following_id = p_user_id
  ) follower_stats ON TRUE
  -- Following statistics
  LEFT JOIN LATERAL (
    SELECT COUNT(*)::INTEGER AS following_count
    FROM user_follows
    WHERE follower_id = p_user_id
  ) following_stats ON TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION calculate_walk_statistics(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_walk_statistics(UUID) TO anon;
GRANT EXECUTE ON FUNCTION get_user_walk_statistics(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_walk_statistics(UUID) TO anon;

-- ============================================================================
-- Verification Query
-- ============================================================================
-- Test with your user ID:
-- SELECT * FROM get_user_walk_statistics('e09b6a6b-fb41-44ff-853e-7cc437836c77');
-- 
-- Expected result (if no walks exist yet):
-- total_walks: 0
-- total_outing_walks: 0
-- total_distance_km: 0.00
-- total_duration_hours: 0.00
-- areas_visited: 0
-- routes_completed: 0
-- pins_created: 0
-- pins_liked_count: 0
-- followers_count: 0 (or actual count)
-- following_count: 0 (or actual count)
-- ============================================================================

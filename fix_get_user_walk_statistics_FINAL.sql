-- ============================================================================
-- Fix: Update get_user_walk_statistics RPC Function
-- ============================================================================
-- Date: 2025-11-27
-- Issue: Argument name mismatch
--   - Current: user_id
--   - Expected by app: p_user_id
-- Solution: Recreate function with correct argument name and return type
-- ============================================================================

-- Step 1: Drop old version
DROP FUNCTION IF EXISTS get_user_walk_statistics(UUID);

-- Step 2: Create helper function (if not exists)
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
    COUNT(DISTINCT r.area) FILTER (WHERE walk_type = 'outing' AND r.area IS NOT NULL)::INTEGER AS areas_visited,
    COUNT(DISTINCT route_id) FILTER (WHERE walk_type = 'outing')::INTEGER AS routes_completed
  FROM walks w
  LEFT JOIN routes r ON w.route_id = r.id
  WHERE w.user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 3: Create main function with correct argument name
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
    -- Walk statistics from walks table
    ws.total_walks,
    ws.total_outing_walks,
    ws.total_distance_km,
    ws.total_duration_hours,
    ws.areas_visited,
    ws.routes_completed,
    
    -- Pin statistics (placeholder until route_pins fully implemented)
    COALESCE(pin_stats.pins_created, 0)::INTEGER AS pins_created,
    COALESCE(pin_stats.pins_liked_count, 0)::INTEGER AS pins_liked_count,
    
    -- Social statistics from user_follows table
    COALESCE(follower_stats.followers_count, 0)::INTEGER AS followers_count,
    COALESCE(following_stats.following_count, 0)::INTEGER AS following_count
    
  FROM calculate_walk_statistics(p_user_id) ws
  
  -- Pin statistics
  LEFT JOIN LATERAL (
    SELECT 
      COUNT(*)::INTEGER AS pins_created,
      COALESCE(SUM(likes_count), 0)::INTEGER AS pins_liked_count
    FROM route_pins
    WHERE user_id = p_user_id
  ) pin_stats ON TRUE
  
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

-- Step 4: Grant permissions
GRANT EXECUTE ON FUNCTION calculate_walk_statistics(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_walk_statistics(UUID) TO anon;
GRANT EXECUTE ON FUNCTION get_user_walk_statistics(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_walk_statistics(UUID) TO anon;

-- ============================================================================
-- Verification
-- ============================================================================
-- Test with your user ID:
-- SELECT * FROM get_user_walk_statistics('e09b6a6b-fb41-44ff-853e-7cc437836c77');
--
-- Expected columns (10 total):
-- 1. total_walks (INTEGER)
-- 2. total_outing_walks (INTEGER)
-- 3. total_distance_km (DECIMAL)
-- 4. total_duration_hours (DECIMAL)
-- 5. areas_visited (INTEGER)
-- 6. routes_completed (INTEGER)
-- 7. pins_created (INTEGER)
-- 8. pins_liked_count (INTEGER)
-- 9. followers_count (INTEGER)
-- 10. following_count (INTEGER)
-- ============================================================================

COMMENT ON FUNCTION get_user_walk_statistics(UUID) IS 
'Returns comprehensive user statistics including walks, pins, and social counts. 
Argument: p_user_id (UUID) - User ID to get statistics for.
Updated: 2025-11-27 - Fixed argument name from user_id to p_user_id';

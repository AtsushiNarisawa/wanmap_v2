-- Restore get_areas_simple RPC function (Version 3 - FINAL)
-- This function retrieves all areas with their coordinates
-- Fixed: Using correct column name 'center_point' instead of 'location'

CREATE OR REPLACE FUNCTION get_areas_simple()
RETURNS TABLE (
  id uuid,
  name text,
  prefecture text,
  description text,
  latitude double precision,
  longitude double precision,
  created_at timestamp with time zone
)
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    a.id,
    a.name,
    a.prefecture,
    COALESCE(a.description, '') AS description,
    ST_Y(a.center_point::geometry) AS latitude,
    ST_X(a.center_point::geometry) AS longitude,
    a.created_at
  FROM areas a
  ORDER BY a.created_at DESC;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_areas_simple() TO authenticated;
GRANT EXECUTE ON FUNCTION get_areas_simple() TO anon;

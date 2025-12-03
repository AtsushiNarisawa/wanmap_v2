-- Restore get_areas_simple RPC function
-- This function retrieves all areas with their coordinates

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
    a.description,
    ST_Y(a.location::geometry) AS latitude,
    ST_X(a.location::geometry) AS longitude,
    a.created_at
  FROM areas a
  ORDER BY a.created_at DESC;
END;
$$;

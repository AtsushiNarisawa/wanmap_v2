-- Restore get_all_routes_geojson RPC function (Version 2)
-- This function retrieves all official routes with their route points
-- Returns JSON array of routes with embedded route_points

CREATE OR REPLACE FUNCTION get_all_routes_geojson()
RETURNS json
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
  result json;
BEGIN
  SELECT json_agg(
    json_build_object(
      'id', r.id,
      'area_id', r.area_id,
      'name', r.name,
      'description', COALESCE(r.description, ''),
      'start_location', r.start_location,
      'end_location', r.end_location,
      'route_line', r.route_line,
      'distance_meters', r.distance_meters,
      'estimated_minutes', r.estimated_minutes,
      'difficulty_level', COALESCE(r.difficulty_level, 'easy'),
      'total_pins', COALESCE(r.total_pins, 0),
      'thumbnail_url', r.thumbnail_url,
      'gallery_images', r.gallery_images,
      'created_at', r.created_at,
      'updated_at', r.updated_at,
      'route_points', (
        SELECT json_agg(
          json_build_object(
            'latitude', ST_Y(rp.location::geometry),
            'longitude', ST_X(rp.location::geometry),
            'elevation', rp.elevation,
            'sequence', rp.sequence
          ) ORDER BY rp.sequence
        )
        FROM official_route_points rp
        WHERE rp.route_id = r.id
      )
    )
  ) INTO result
  FROM routes r
  ORDER BY r.created_at DESC;
  
  RETURN COALESCE(result, '[]'::json);
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_all_routes_geojson() TO authenticated;
GRANT EXECUTE ON FUNCTION get_all_routes_geojson() TO anon;

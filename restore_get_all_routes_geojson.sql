-- Restore get_all_routes_geojson RPC function
-- This function retrieves all official routes in GeoJSON format

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
      'title', r.title,
      'description', r.description,
      'area_id', r.area_id,
      'difficulty_level', r.difficulty_level,
      'estimated_duration_minutes', r.estimated_duration_minutes,
      'distance_meters', r.distance_meters,
      'elevation_gain_meters', r.elevation_gain_meters,
      'thumbnail_url', r.thumbnail_url,
      'gpx_data', r.gpx_data,
      'created_at', r.created_at,
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
  FROM routes r;
  
  RETURN COALESCE(result, '[]'::json);
END;
$$;

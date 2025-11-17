-- ====================================================================
-- Update area detection ranges to include more cities
-- ====================================================================
-- Purpose: Expand Hakone area to include Odawara city
-- ====================================================================

-- Update existing routes with expanded Hakone area detection
-- Hakone area now includes Odawara: lat 35.15-35.35, lng 138.95-139.15
UPDATE public.routes r
SET area = 'hakone', 
    prefecture = '神奈川県'
WHERE EXISTS (
  SELECT 1 FROM public.route_points rp
  WHERE rp.route_id = r.id
  AND rp.latitude BETWEEN 35.15 AND 35.35  -- Expanded to include Odawara
  AND rp.longitude BETWEEN 138.95 AND 139.15
  LIMIT 1
) 
AND area IS NULL;

-- Verify the update
SELECT 
    area,
    prefecture,
    COUNT(*) as route_count
FROM public.routes
WHERE area IS NOT NULL
GROUP BY area, prefecture
ORDER BY area;

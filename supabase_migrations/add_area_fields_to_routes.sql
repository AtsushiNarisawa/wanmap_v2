-- ================================================================
-- Phase: 公開ルート画面改善 - エリア情報追加
-- 作成日: 2025-11-15
-- 説明: routesテーブルにエリア、都道府県、サムネイルURL情報を追加
-- ================================================================

-- 1. routesテーブルにカラム追加
ALTER TABLE public.routes 
ADD COLUMN IF NOT EXISTS area VARCHAR(50),
ADD COLUMN IF NOT EXISTS prefecture VARCHAR(50),
ADD COLUMN IF NOT EXISTS thumbnail_url TEXT;

-- 2. インデックス追加（検索パフォーマンス向上）
CREATE INDEX IF NOT EXISTS idx_routes_area 
ON public.routes(area) 
WHERE is_public = true;

CREATE INDEX IF NOT EXISTS idx_routes_prefecture 
ON public.routes(prefecture) 
WHERE is_public = true;

-- 3. コメント追加
COMMENT ON COLUMN public.routes.area IS 'エリア識別子 (hakone, izu, nasu, karuizawa, fuji, kamakura)';
COMMENT ON COLUMN public.routes.prefecture IS '都道府県名 (神奈川県、静岡県、etc.)';
COMMENT ON COLUMN public.routes.thumbnail_url IS 'ルートの代表写真URL (route_photosの最初の画像)';

-- 4. 既存データへのエリア情報追加（GPS座標ベース）
-- 箱根エリア: 緯度35.2-35.3, 経度139.0-139.1
UPDATE public.routes r
SET 
  area = 'hakone',
  prefecture = '神奈川県'
WHERE EXISTS (
  SELECT 1 FROM public.route_points rp
  WHERE rp.route_id = r.id
  AND rp.latitude BETWEEN 35.2 AND 35.3
  AND rp.longitude BETWEEN 139.0 AND 139.1
  LIMIT 1
)
AND area IS NULL;

-- 伊豆エリア: 緯度34.8-35.1, 経度138.8-139.2
UPDATE public.routes r
SET 
  area = 'izu',
  prefecture = '静岡県'
WHERE EXISTS (
  SELECT 1 FROM public.route_points rp
  WHERE rp.route_id = r.id
  AND rp.latitude BETWEEN 34.8 AND 35.1
  AND rp.longitude BETWEEN 138.8 AND 139.2
  LIMIT 1
)
AND area IS NULL;

-- 那須エリア: 緯度37.0-37.2, 経度139.9-140.1
UPDATE public.routes r
SET 
  area = 'nasu',
  prefecture = '栃木県'
WHERE EXISTS (
  SELECT 1 FROM public.route_points rp
  WHERE rp.route_id = r.id
  AND rp.latitude BETWEEN 37.0 AND 37.2
  AND rp.longitude BETWEEN 139.9 AND 140.1
  LIMIT 1
)
AND area IS NULL;

-- 軽井沢エリア: 緯度36.3-36.5, 経度138.5-138.7
UPDATE public.routes r
SET 
  area = 'karuizawa',
  prefecture = '長野県'
WHERE EXISTS (
  SELECT 1 FROM public.route_points rp
  WHERE rp.route_id = r.id
  AND rp.latitude BETWEEN 36.3 AND 36.5
  AND rp.longitude BETWEEN 138.5 AND 138.7
  LIMIT 1
)
AND area IS NULL;

-- 富士山周辺エリア: 緯度35.3-35.5, 経度138.6-138.9
UPDATE public.routes r
SET 
  area = 'fuji',
  prefecture = '山梨県'
WHERE EXISTS (
  SELECT 1 FROM public.route_points rp
  WHERE rp.route_id = r.id
  AND rp.latitude BETWEEN 35.3 AND 35.5
  AND rp.longitude BETWEEN 138.6 AND 138.9
  LIMIT 1
)
AND area IS NULL;

-- 鎌倉エリア: 緯度35.3-35.4, 経度139.5-139.6
UPDATE public.routes r
SET 
  area = 'kamakura',
  prefecture = '神奈川県'
WHERE EXISTS (
  SELECT 1 FROM public.route_points rp
  WHERE rp.route_id = r.id
  AND rp.latitude BETWEEN 35.3 AND 35.4
  AND rp.longitude BETWEEN 139.5 AND 139.6
  LIMIT 1
)
AND area IS NULL;

-- 5. サムネイル自動生成（route_photosの最初の画像を使用）
UPDATE public.routes r
SET thumbnail_url = (
  SELECT rp.storage_path
  FROM public.route_photos rp
  WHERE rp.route_id = r.id
  ORDER BY rp.display_order ASC, rp.created_at ASC
  LIMIT 1
)
WHERE thumbnail_url IS NULL
AND EXISTS (
  SELECT 1 FROM public.route_photos rp2
  WHERE rp2.route_id = r.id
);

-- 6. 検証クエリ（確認用 - コメントアウト）
-- SELECT 
--   area,
--   prefecture,
--   COUNT(*) as route_count,
--   COUNT(thumbnail_url) as with_thumbnail
-- FROM public.routes
-- WHERE is_public = true
-- GROUP BY area, prefecture
-- ORDER BY route_count DESC;

-- =====================================================
-- Update Hakone route images
-- =====================================================
-- 箱根の公式ルートにサムネイルとギャラリー画像を追加

-- 芦ノ湖湖畔コース
UPDATE official_routes
SET 
  thumbnail_url = 'https://images.unsplash.com/photo-1590559899731-a382839e5549?w=800',
  gallery_images = ARRAY[
    'https://images.unsplash.com/photo-1590559899731-a382839e5549?w=800',
    'https://images.unsplash.com/photo-1528127269322-539801943592?w=800',
    'https://images.unsplash.com/photo-1493780474015-ba834fd0ce2f?w=800'
  ]
WHERE title = '芦ノ湖湖畔コース';

-- 箱根神社参道コース
UPDATE official_routes
SET 
  thumbnail_url = 'https://images.unsplash.com/photo-1528127269322-539801943592?w=800',
  gallery_images = ARRAY[
    'https://images.unsplash.com/photo-1528127269322-539801943592?w=800',
    'https://images.unsplash.com/photo-1493780474015-ba834fd0ce2f?w=800',
    'https://images.unsplash.com/photo-1590559899731-a382839e5549?w=800'
  ]
WHERE title = '箱根神社参道コース';

-- 仙石原すすき草原コース
UPDATE official_routes
SET 
  thumbnail_url = 'https://images.unsplash.com/photo-1493780474015-ba834fd0ce2f?w=800',
  gallery_images = ARRAY[
    'https://images.unsplash.com/photo-1493780474015-ba834fd0ce2f?w=800',
    'https://images.unsplash.com/photo-1590559899731-a382839e5549?w=800',
    'https://images.unsplash.com/photo-1528127269322-539801943592?w=800'
  ]
WHERE title = '仙石原すすき草原コース';

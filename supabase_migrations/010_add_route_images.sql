-- =====================================================
-- Add thumbnail and gallery images to official_routes
-- =====================================================
-- 実行日: 2025-11-26
-- 目的: ルート検索で表示する画像を official_routes テーブルに追加

-- thumbnail_url と gallery_images カラムを追加
ALTER TABLE official_routes
ADD COLUMN IF NOT EXISTS thumbnail_url TEXT,
ADD COLUMN IF NOT EXISTS gallery_images TEXT[];

COMMENT ON COLUMN official_routes.thumbnail_url IS 'ルート検索で表示するサムネイル画像URL';
COMMENT ON COLUMN official_routes.gallery_images IS 'ルート詳細で表示するギャラリー画像URL配列';

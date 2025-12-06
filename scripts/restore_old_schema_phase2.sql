-- ========================================
-- Phase 2: Supabase official_routesテーブル完全復元
-- 実行日: 2025-12-06
-- 目的: 新スキーマから旧スキーマへの完全復元
-- ========================================

-- ============================================
-- Step 1: テーブル削除（CASCADE）
-- ============================================
DROP TABLE IF EXISTS official_routes CASCADE;

-- ============================================
-- Step 2: 旧スキーマでテーブル再作成
-- ============================================
CREATE TABLE official_routes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  area_id UUID REFERENCES areas NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  start_location GEOGRAPHY(Point, 4326) NOT NULL,
  end_location GEOGRAPHY(Point, 4326) NOT NULL,
  route_line GEOGRAPHY(LineString, 4326),
  distance_meters NUMERIC(10, 2) NOT NULL,
  estimated_minutes INTEGER NOT NULL,
  difficulty_level TEXT CHECK (difficulty_level IN ('easy', 'moderate', 'hard')) NOT NULL,
  elevation_gain_meters NUMERIC(10, 2),
  thumbnail_url TEXT,
  gallery_images TEXT[],
  pet_info JSONB,
  total_pins INTEGER DEFAULT 0,
  total_walks INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- インデックス作成
CREATE INDEX idx_official_routes_area ON official_routes (area_id);
CREATE INDEX idx_official_routes_difficulty ON official_routes (difficulty_level);
CREATE INDEX idx_official_routes_start_location ON official_routes USING GIST (start_location);

-- ============================================
-- Step 3: route_pinsテーブル再作成
-- ============================================
CREATE TABLE route_pins (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  route_id UUID REFERENCES official_routes NOT NULL,
  user_id UUID REFERENCES auth.users NOT NULL,
  location GEOGRAPHY(Point, 4326) NOT NULL,
  pin_type TEXT CHECK (pin_type IN ('scenery', 'shop', 'encounter', 'other')) NOT NULL,
  title TEXT NOT NULL,
  comment TEXT,
  likes_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX route_pins_route_idx ON route_pins (route_id);
CREATE INDEX route_pins_location_idx ON route_pins USING GIST (location);
CREATE INDEX route_pins_created_at_idx ON route_pins (created_at DESC);

-- ============================================
-- Step 4: route_pin_photosテーブル再作成
-- ============================================
CREATE TABLE route_pin_photos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  pin_id UUID REFERENCES route_pins ON DELETE CASCADE NOT NULL,
  photo_url TEXT NOT NULL,
  display_order INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (pin_id, display_order)
);

CREATE INDEX route_pin_photos_pin_idx ON route_pin_photos (pin_id, display_order);

SELECT 'テーブル再作成完了' AS status;

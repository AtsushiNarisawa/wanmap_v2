-- ============================================================
-- official_routes テーブルの作成（既存データクリーンアップ版）
-- ============================================================
-- Phase 5のテストデータをクリーンアップしてから作成します
-- ============================================================

-- ステップ1: 既存のofficial_route_pointsデータを削除
TRUNCATE TABLE official_route_points CASCADE;

-- 確認メッセージ
DO $$
BEGIN
  RAISE NOTICE '✅ official_route_points の既存データを削除しました';
END $$;

-- ステップ2: PostGIS拡張を有効化（念のため）
CREATE EXTENSION IF NOT EXISTS postgis;

-- ステップ3: official_routes テーブル作成
CREATE TABLE IF NOT EXISTS official_routes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  area_id UUID REFERENCES areas(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  start_location GEOGRAPHY(Point, 4326) NOT NULL,
  end_location GEOGRAPHY(Point, 4326) NOT NULL,
  route_line GEOGRAPHY(LineString, 4326),
  distance_meters DECIMAL(10, 2) NOT NULL,
  estimated_minutes INTEGER NOT NULL,
  difficulty_level TEXT CHECK (difficulty_level IN ('easy', 'moderate', 'hard')) NOT NULL,
  elevation_gain_meters DECIMAL(8, 2),
  total_pins INTEGER DEFAULT 0,
  total_walks INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ステップ4: インデックス作成
CREATE INDEX IF NOT EXISTS idx_official_routes_area_id ON official_routes(area_id);
CREATE INDEX IF NOT EXISTS idx_official_routes_start_location ON official_routes USING GIST(start_location);
CREATE INDEX IF NOT EXISTS idx_official_routes_difficulty ON official_routes(difficulty_level);

-- ステップ5: RLS（Row Level Security）有効化
ALTER TABLE official_routes ENABLE ROW LEVEL SECURITY;

-- RLSポリシー: 全員が閲覧可能
DROP POLICY IF EXISTS "Anyone can view official routes" ON official_routes;
CREATE POLICY "Anyone can view official routes"
  ON official_routes FOR SELECT
  USING (true);

-- RLSポリシー: 認証ユーザーが挿入可能
DROP POLICY IF EXISTS "Authenticated users can insert official routes" ON official_routes;
CREATE POLICY "Authenticated users can insert official routes"
  ON official_routes FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

-- ステップ6: official_route_points との外部キー制約を追加
ALTER TABLE official_route_points
  DROP CONSTRAINT IF EXISTS official_route_points_official_route_id_fkey;

ALTER TABLE official_route_points
  ADD CONSTRAINT official_route_points_official_route_id_fkey
  FOREIGN KEY (official_route_id)
  REFERENCES official_routes(id)
  ON DELETE CASCADE;

-- 完了メッセージ
DO $$
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE '✅ official_routes テーブル作成完了';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'テーブル構造:';
  RAISE NOTICE '  - id: UUID';
  RAISE NOTICE '  - area_id: UUID (areas参照)';
  RAISE NOTICE '  - name: TEXT';
  RAISE NOTICE '  - description: TEXT';
  RAISE NOTICE '  - start_location: GEOGRAPHY(Point)';
  RAISE NOTICE '  - end_location: GEOGRAPHY(Point)';
  RAISE NOTICE '  - route_line: GEOGRAPHY(LineString)';
  RAISE NOTICE '  - distance_meters: DECIMAL';
  RAISE NOTICE '  - estimated_minutes: INTEGER';
  RAISE NOTICE '  - difficulty_level: TEXT (easy/moderate/hard)';
  RAISE NOTICE '========================================';
  RAISE NOTICE '次のステップ:';
  RAISE NOTICE '  INSERT_TEST_DATA_FINAL.sql を実行してデータ投入';
  RAISE NOTICE '========================================';
END $$;

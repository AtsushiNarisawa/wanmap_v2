-- ============================================================
-- official_route_pointsの古いデータを削除してから
-- official_routesテーブルを作成
-- ============================================================

-- ステップ1: 古いテストデータを削除
DELETE FROM official_route_points;

-- 確認メッセージ
DO $$
BEGIN
  RAISE NOTICE '✅ official_route_pointsの古いデータを削除しました';
END $$;

-- ステップ2: PostGIS拡張を有効化
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

-- ステップ5: RLS有効化
ALTER TABLE official_routes ENABLE ROW LEVEL SECURITY;

-- ステップ6: RLSポリシー作成
DO $$
BEGIN
  -- ポリシーが既に存在する場合はスキップ
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'official_routes' 
    AND policyname = 'Anyone can view official routes'
  ) THEN
    EXECUTE 'CREATE POLICY "Anyone can view official routes"
      ON official_routes FOR SELECT
      USING (true)';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'official_routes' 
    AND policyname = 'Authenticated users can insert official routes'
  ) THEN
    EXECUTE 'CREATE POLICY "Authenticated users can insert official routes"
      ON official_routes FOR INSERT
      WITH CHECK (auth.role() = ''authenticated'')';
  END IF;
END $$;

-- ステップ7: 外部キー制約を追加
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

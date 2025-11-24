-- ============================================================
-- 公式ルートと経路ポイントを投入（正しいarea_idを使用）
-- ============================================================

-- ■■■ ステップ1: 既存データの確認 ■■■
DO $$
DECLARE
    area_count INTEGER;
    route_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO area_count FROM areas;
    SELECT COUNT(*) INTO route_count FROM official_routes;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE '現在のデータ状況:';
    RAISE NOTICE '  - areas: % 件', area_count;
    RAISE NOTICE '  - official_routes: % 件', route_count;
    RAISE NOTICE '========================================';
END $$;

-- ■■■ ステップ2: 公式ルートの投入 ■■■
-- ルート1: DogHub周遊コース（初心者向け）
INSERT INTO official_routes (
  id,
  area_id,
  name,
  description,
  start_location,
  end_location,
  route_line,
  distance_meters,
  estimated_minutes,
  difficulty_level,
  elevation_gain_meters,
  total_pins,
  total_walks,
  created_at
)
VALUES (
  '10000000-0000-0000-0000-000000000001'::UUID,
  'a1111111-1111-1111-1111-111111111111'::UUID,
  'DogHub周遊コース',
  'DogHubを起点とした短距離の散歩コース。初めての方や小型犬におすすめ。途中、箱根の自然を感じられる緑道を通ります。',
  ST_SetSRID(ST_MakePoint(139.1071, 35.2328), 4326)::geography,
  ST_SetSRID(ST_MakePoint(139.1071, 35.2328), 4326)::geography,
  NULL,
  1200.0,
  20,
  'easy',
  50.0,
  0,
  0,
  NOW()
);

-- ルート2: 箱根旧街道コース（中級者向け）
INSERT INTO official_routes (
  id,
  area_id,
  name,
  description,
  start_location,
  end_location,
  route_line,
  distance_meters,
  estimated_minutes,
  difficulty_level,
  elevation_gain_meters,
  total_pins,
  total_walks,
  created_at
)
VALUES (
  '10000000-0000-0000-0000-000000000002'::UUID,
  'a1111111-1111-1111-1111-111111111111'::UUID,
  '箱根旧街道散歩道',
  '歴史ある箱根旧街道の一部を歩くコース。石畳の道と杉並木が美しい。坂道あり。',
  ST_SetSRID(ST_MakePoint(139.1071, 35.2328), 4326)::geography,
  ST_SetSRID(ST_MakePoint(139.1100, 35.2380), 4326)::geography,
  NULL,
  3500.0,
  60,
  'moderate',
  150.0,
  0,
  0,
  NOW()
);

-- ルート3: 芦ノ湖畔コース（上級者向け）
INSERT INTO official_routes (
  id,
  area_id,
  name,
  description,
  start_location,
  end_location,
  route_line,
  distance_meters,
  estimated_minutes,
  difficulty_level,
  elevation_gain_meters,
  total_pins,
  total_walks,
  created_at
)
VALUES (
  '10000000-0000-0000-0000-000000000003'::UUID,
  'a1111111-1111-1111-1111-111111111111'::UUID,
  '芦ノ湖畔ロングウォーク',
  '芦ノ湖の美しい景色を楽しみながら歩く長距離コース。体力のある犬と飼い主向け。',
  ST_SetSRID(ST_MakePoint(139.0264, 35.2044), 4326)::geography,
  ST_SetSRID(ST_MakePoint(139.0350, 35.2100), 4326)::geography,
  NULL,
  6800.0,
  120,
  'hard',
  200.0,
  0,
  0,
  NOW()
);

-- ■■■ ステップ3: 経路ポイントの投入 ■■■
-- DogHub周遊コースの経路ポイント
INSERT INTO official_route_points (id, official_route_id, sequence, point, elevation)
VALUES
  (
    uuid_generate_v4(),
    '10000000-0000-0000-0000-000000000001'::UUID,
    1,
    ST_SetSRID(ST_MakePoint(139.1071, 35.2328), 4326)::geography,
    100.0
  ),
  (
    uuid_generate_v4(),
    '10000000-0000-0000-0000-000000000001'::UUID,
    2,
    ST_SetSRID(ST_MakePoint(139.1080, 35.2335), 4326)::geography,
    120.0
  ),
  (
    uuid_generate_v4(),
    '10000000-0000-0000-0000-000000000001'::UUID,
    3,
    ST_SetSRID(ST_MakePoint(139.1075, 35.2340), 4326)::geography,
    140.0
  ),
  (
    uuid_generate_v4(),
    '10000000-0000-0000-0000-000000000001'::UUID,
    4,
    ST_SetSRID(ST_MakePoint(139.1071, 35.2328), 4326)::geography,
    100.0
  );

-- ■■■ ステップ4: 結果確認 ■■■
DO $$
DECLARE
    area_count INTEGER;
    route_count INTEGER;
    point_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO area_count FROM areas;
    SELECT COUNT(*) INTO route_count FROM official_routes;
    SELECT COUNT(*) INTO point_count FROM official_route_points;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ データ投入完了！';
    RAISE NOTICE '========================================';
    RAISE NOTICE '投入後のデータ状況:';
    RAISE NOTICE '  - areas: % 件', area_count;
    RAISE NOTICE '  - official_routes: % 件', route_count;
    RAISE NOTICE '  - official_route_points: % 件', point_count;
    RAISE NOTICE '========================================';
    RAISE NOTICE '次のステップ:';
    RAISE NOTICE '1. アプリを起動';
    RAISE NOTICE '2. ホーム画面で「エリアを探す」をタップ';
    RAISE NOTICE '3. 「箱根」エリアが表示されることを確認';
    RAISE NOTICE '4. 「DogHub周遊コース」を選択して散歩開始';
    RAISE NOTICE '========================================';
END $$;

-- ========================================
-- Phase 2-2: official_routesデータ復元
-- 実行日: 2025-12-06
-- 目的: 24ルートデータの復元（旧スキーマ）
-- ========================================

-- 箱根エリア（4ルート）
INSERT INTO official_routes (
  id, area_id, name, description, 
  start_location, end_location, route_line,
  distance_meters, estimated_minutes, difficulty_level, elevation_gain_meters,
  thumbnail_url, gallery_images, pet_info, total_pins, total_walks, created_at, updated_at
) VALUES
(
  '8d0b7773-cac3-4f5b-938b-f21e92b4c0fe'::UUID,
  'a1111111-1111-1111-1111-111111111111'::UUID,
  'DogHub周遊コース',
  'DogHubを起点とした短距離の散歩コース。初めての方や小型犬におすすめ。途中、箱根の自然を感じられる緑道を通ります。',
  ST_GeomFromText('POINT(139.1071 35.2328)', 4326)::geography,
  ST_GeomFromText('POINT(139.1071 35.2328)', 4326)::geography,
  NULL,
  1200.0,
  25,
  'easy',
  NULL,
  'https://images.unsplash.com/photo-1528127269322-539801943592?w=800',
  ARRAY[
    'https://images.unsplash.com/photo-1528127269322-539801943592?w=1200',
    'https://images.unsplash.com/photo-1519904981063-b0cf448d479e?w=1200',
    'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1200'
  ],
  '{"others": "リード着用必須。小型犬・初心者に最適な短距離コース。DogHubで休憩可能。", "parking": "あり（DogHub駐車場・無料）", "surface": "アスファルト 60% / 土・砂利 40%", "restroom": "あり（DogHub施設内）", "water_station": "あり（DogHub施設内、コース途中1箇所）", "pet_facilities": "DogHub（ドッグカフェ、ドッグホテル併設）"}'::jsonb,
  0,
  0,
  '2025-12-06 00:09:08.524614+00'::timestamptz,
  '2025-12-06 01:09:39.456533+00'::timestamptz
),
(
  'd2a04103-3868-4e44-8fdb-eb3433d4e695'::UUID,
  'a1111111-1111-1111-1111-111111111111'::UUID,
  '芦ノ湖湖畔散歩コース（元箱根港〜箱根公園）',
  '元箱根港を起点に、箱根恩賜公園を経由して湖畔を散歩するコース。舗装された歩きやすい道が続き、愛犬との散歩に最適。湖の景観を楽しみながら、箱根神社の赤い鳥居や箱根関所跡などの観光スポットにも立ち寄れます。往復コースのため、体力に合わせて距離調整も可能。',
  ST_GeomFromText('POINT(139.024526 35.189992)', 4326)::geography,
  ST_GeomFromText('POINT(139.024526 35.189992)', 4326)::geography,
  NULL,
  2500.0,
  50,
  'easy',
  30.0,
  'https://images.unsplash.com/photo-1501594907352-04cda38ebc29?w=800',
  ARRAY[
    'https://images.unsplash.com/photo-1501594907352-04cda38ebc29?w=1200',
    'https://images.unsplash.com/photo-1528127269322-539801943592?w=1200',
    'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1200'
  ],
  '{"others": "リード着用必須。観光シーズン（GW・紅葉期）は混雑するため早朝散歩推奨。小型犬でも歩きやすい平坦なコース。", "parking": "あり（元箱根港駐車場・有料500円/日）", "surface": "コンクリート 80% / 土・砂利 20%", "restroom": "あり（元箱根港、箱根公園内）", "water_station": "あり（箱根公園入口、湖畔複数箇所）", "pet_facilities": "周辺にペット同伴可カフェあり、箱根神社は境内ペット同伴可（リード着用必須）"}'::jsonb,
  0,
  0,
  '2025-12-06 00:09:08.524614+00'::timestamptz,
  '2025-12-06 01:09:39.456533+00'::timestamptz
),
(
  'ad904fb6-f2bd-423c-b7b6-a6abd44b054f'::UUID,
  'a1111111-1111-1111-1111-111111111111'::UUID,
  '箱根旧街道散歩道',
  '歴史ある箱根旧街道の一部を歩くコース。石畳の道と杉並木が美しい。坂道あり。',
  ST_GeomFromText('POINT(139.1071 35.2328)', 4326)::geography,
  ST_GeomFromText('POINT(139.11 35.238)', 4326)::geography,
  NULL,
  3500.0,
  75,
  'moderate',
  NULL,
  'https://images.unsplash.com/photo-1528127269322-539801943592?w=800',
  ARRAY[
    'https://images.unsplash.com/photo-1528127269322-539801943592?w=1200',
    'https://images.unsplash.com/photo-1511593358241-7eea1f3c84e5?w=1200',
    'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1200'
  ],
  '{"others": "リード着用必須。石畳で滑りやすいため注意。坂道多く中級者向け。歴史的な杉並木が美しい。", "parking": "あり（箱根旧街道入口・無料/箱根町営駐車場・有料300円/時）", "surface": "石畳 70% / 土・砂利 30%", "restroom": "あり（旧街道入口、甘酒茶屋）", "water_station": "あり（甘酒茶屋、休憩所2箇所）", "pet_facilities": "甘酒茶屋（ペット同伴可、テラス席のみ）"}'::jsonb,
  0,
  0,
  '2025-12-06 00:09:08.524614+00'::timestamptz,
  '2025-12-06 01:09:39.456533+00'::timestamptz
),
(
  '6ae42d51-4221-4075-a2c7-cb8572e17cf7'::UUID,
  'a1111111-1111-1111-1111-111111111111'::UUID,
  '芦ノ湖畔ロングウォーク',
  '芦ノ湖の湖畔を長距離歩くコース。体力に自信のある方向け。絶景ポイント多数。',
  ST_GeomFromText('POINT(139.0245 35.19)', 4326)::geography,
  ST_GeomFromText('POINT(139.04 35.2)', 4326)::geography,
  NULL,
  6800.0,
  150,
  'hard',
  NULL,
  'https://images.unsplash.com/photo-1501594907352-04cda38ebc29?w=800',
  ARRAY[
    'https://images.unsplash.com/photo-1501594907352-04cda38ebc29?w=1200',
    'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1200',
    'https://images.unsplash.com/photo-1519904981063-b0cf448d479e?w=1200'
  ],
  '{"others": "リード着用必須。長距離のため体力が必要。休憩ポイント多数。芦ノ湖の絶景を楽しめる上級者向けコース。", "parking": "あり（湖尻駐車場・無料、桃源台駐車場・有料500円/日）", "surface": "アスファルト 50% / 土・砂利 50%", "restroom": "あり（湖尻、桃源台、箱根園）", "water_station": "あり（湖尻、桃源台、箱根園、コース途中複数箇所）", "pet_facilities": "湖畔にペット同伴可レストラン・カフェ複数あり"}'::jsonb,
  0,
  0,
  '2025-12-06 00:09:08.524614+00'::timestamptz,
  '2025-12-06 01:09:39.456533+00'::timestamptz
);

-- 横浜エリア（2ルート）
INSERT INTO official_routes (
  id, area_id, name, description,
  start_location, end_location, route_line,
  distance_meters, estimated_minutes, difficulty_level, elevation_gain_meters,
  thumbnail_url, gallery_images, pet_info, total_pins, total_walks, created_at, updated_at
) VALUES
(
  '20000000-0000-0000-0000-000000000001'::UUID,
  'a2222222-2222-2222-2222-222222222222'::UUID,
  '山下公園散歩コース',
  '横浜の代表的な海沿い公園。海風を感じながら愛犬とゆったり散歩できます。芝生エリアもあり小型犬にもおすすめ。',
  ST_GeomFromText('POINT(139.6507 35.4437)', 4326)::geography,
  ST_GeomFromText('POINT(139.6507 35.4437)', 4326)::geography,
  ST_GeomFromText('LINESTRING(139.6507 35.4437,139.652 35.4445,139.6535 35.444,139.652 35.4432,139.6507 35.4437)', 4326)::geography,
  1500.0,
  25,
  'easy',
  NULL,
  'https://images.unsplash.com/photo-1570168007204-dfb528c6958f?w=400',
  ARRAY[
    'https://images.unsplash.com/photo-1570168007204-dfb528c6958f?w=800',
    'https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=800',
    'https://images.unsplash.com/photo-1568515387631-8b650bbcdb90?w=800'
  ],
  NULL,
  0,
  0,
  '2025-11-26 19:31:42.670673+00'::timestamptz,
  '2025-12-06 01:09:39.456533+00'::timestamptz
),
(
  '779d1816-0c24-4d91-b5b2-2fbfc3292024'::UUID,
  'a2222222-2222-2222-2222-222222222222'::UUID,
  '山下公園・港の見える丘公園コース',
  '横浜を代表する海沿いの公園を巡るコース。氷川丸や港の景色を楽しみながら歩けます。',
  ST_GeomFromText('POINT(139.65 35.4437)', 4326)::geography,
  ST_GeomFromText('POINT(139.648 35.447)', 4326)::geography,
  ST_GeomFromText('LINESTRING(139.63 35.44,139.631 35.441,139.6325 35.442,139.634 35.4425,139.635 35.443)', 4326)::geography,
  4500.0,
  55,
  'easy',
  30.0,
  NULL,
  NULL,
  NULL,
  0,
  0,
  '2025-11-25 06:14:27.377442+00'::timestamptz,
  '2025-12-06 01:09:39.456533+00'::timestamptz
);

-- 鎌倉エリア（2ルート）
INSERT INTO official_routes (
  id, area_id, name, description,
  start_location, end_location, route_line,
  distance_meters, estimated_minutes, difficulty_level, elevation_gain_meters,
  thumbnail_url, gallery_images, pet_info, total_pins, total_walks, created_at, updated_at
) VALUES
(
  '8037d1b7-9451-482f-b0c8-4ddc8960cb54'::UUID,
  'a3333333-3333-3333-3333-333333333333'::UUID,
  '北鎌倉・円覚寺コース',
  '静かな北鎌倉エリアの古刹を巡るコース。落ち着いた雰囲気で心が癒されます。',
  ST_GeomFromText('POINT(139.547 35.337)', 4326)::geography,
  ST_GeomFromText('POINT(139.548 35.338)', 4326)::geography,
  ST_GeomFromText('LINESTRING(139.547 35.337,139.548 35.338)', 4326)::geography,
  1800.0,
  25,
  'easy',
  10.0,
  'https://sspark.genspark.ai/cfimages?u1=xX%2BdjU0gZEeIHkmeX5ZlbL2D0ngSnwaE80fsuCeO7xbrHX5M%2F%2B%2FMtN11AKMg0MQ96sCpTJEXSNaXtpGx1Ffh53YOcjOHyztAc5q4hc31%2BjVVvPIzXpJ1PqgSeZxO1ulBbQ%3D%3D&u2=gtNyo6PxxxsCvDvo&width=2560',
  NULL,
  NULL,
  0,
  90,
  '2025-11-25 06:14:27.377442+00'::timestamptz,
  '2025-12-06 01:09:39.456533+00'::timestamptz
),
(
  '36ed0efb-087a-4401-a6d6-b4f35e1cadbd'::UUID,
  'a3333333-3333-3333-3333-333333333333'::UUID,
  '長谷寺・大仏コース',
  '鎌倉大仏と美しい長谷寺を巡る定番コース。由比ヶ浜も近く海を眺めることもできます。',
  ST_GeomFromText('POINT(139.533 35.313)', 4326)::geography,
  ST_GeomFromText('POINT(139.534 35.315)', 4326)::geography,
  ST_GeomFromText('LINESTRING(139.533 35.313,139.534 35.315)', 4326)::geography,
  2600.0,
  35,
  'moderate',
  40.0,
  'https://sspark.genspark.ai/cfimages?u1=OA9CR8A8VxKCvMeg0PXIpQ4qfHxn%2B3W%2FftfTboFOmhywoIMJE9m69ubpGLyel7r1%2FmMaxbRfp5nY4bwQMLbgPZqMEHuxtW1tMFIyik83NF5%2BoCQtMq4%3D&u2=18llJZehti%2F2A5tL&width=2560',
  NULL,
  NULL,
  0,
  100,
  '2025-11-25 06:14:27.377442+00'::timestamptz,
  '2025-12-06 01:09:39.456533+00'::timestamptz
);

SELECT '箱根・横浜・鎌倉エリアのルートデータ復元完了（8ルート）' AS status;

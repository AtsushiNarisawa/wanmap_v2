-- スポット評価・レビュー機能 テストデータ投入
-- 作成日: 2025-12-14
-- 目的: 開発・デバッグ用のサンプルレビューを作成

-- ============================================================
-- 既存データの確認
-- ============================================================
-- user_id: 00c7e152-bfae-4773-93b5-bab65e64faf2 (Momo)
-- route_id: 6ae42d51-4221-4075-a2c7-cb8572e17cf7 (芦ノ湖畔ロングウォーク)
-- spot_id (pin_id): 2491ff81-9003-4548-98c6-a35d5a2a574e (芦ノ湖ビューポイント)
-- spot_id (pin_id): e1345e3b-e6f5-4a10-b54f-699fcb9e66d9 (ランチ休憩スポット)
-- ============================================================

-- ============================================================
-- 1. 芦ノ湖ビューポイントへのレビュー（高評価）
-- ============================================================
INSERT INTO spot_reviews (
  user_id,
  spot_id,
  rating,
  review_text,
  has_water_fountain,
  has_dog_run,
  has_shade,
  has_toilet,
  has_parking,
  has_dog_waste_bin,
  leash_required,
  dog_friendly_cafe,
  dog_size_suitable,
  seasonal_info,
  photo_urls
)
VALUES (
  '00c7e152-bfae-4773-93b5-bab65e64faf2'::UUID, -- Momoユーザー
  '2491ff81-9003-4548-98c6-a35d5a2a574e'::UUID, -- 芦ノ湖ビューポイント
  5, -- 星5つ（最高評価）
  '絶景スポット！芦ノ湖の全景が一望でき、富士山も見えました。愛犬のぱんちもムックも大興奮でした。写真映えする場所なので、カメラは必須です。風が強い日もあるので、上着があると良いです。',
  false, -- 水飲み場なし
  false, -- ドッグランなし
  true,  -- 日陰あり（木陰）
  false, -- トイレなし
  true,  -- 駐車場あり
  true,  -- 犬用ゴミ箱あり
  true,  -- リード必須
  false, -- カフェなし
  'all', -- 全サイズの犬に適している
  '春は桜、秋は紅葉が美しい。冬は雪景色も楽しめます。',
  ARRAY[
    'https://picsum.photos/seed/hakone1/800/600',
    'https://picsum.photos/seed/hakone2/800/600',
    'https://picsum.photos/seed/hakone3/800/600'
  ]::TEXT[]
)
ON CONFLICT (user_id, spot_id) DO UPDATE SET
  rating = EXCLUDED.rating,
  review_text = EXCLUDED.review_text,
  has_water_fountain = EXCLUDED.has_water_fountain,
  has_dog_run = EXCLUDED.has_dog_run,
  has_shade = EXCLUDED.has_shade,
  has_toilet = EXCLUDED.has_toilet,
  has_parking = EXCLUDED.has_parking,
  has_dog_waste_bin = EXCLUDED.has_dog_waste_bin,
  leash_required = EXCLUDED.leash_required,
  dog_friendly_cafe = EXCLUDED.dog_friendly_cafe,
  dog_size_suitable = EXCLUDED.dog_size_suitable,
  seasonal_info = EXCLUDED.seasonal_info,
  photo_urls = EXCLUDED.photo_urls,
  updated_at = CURRENT_TIMESTAMP;

-- ============================================================
-- 2. ランチ休憩スポットへのレビュー（中評価）
-- ============================================================
INSERT INTO spot_reviews (
  user_id,
  spot_id,
  rating,
  review_text,
  has_water_fountain,
  has_dog_run,
  has_shade,
  has_toilet,
  has_parking,
  has_dog_waste_bin,
  leash_required,
  dog_friendly_cafe,
  dog_size_suitable,
  seasonal_info,
  photo_urls
)
VALUES (
  '00c7e152-bfae-4773-93b5-bab65e64faf2'::UUID, -- Momoユーザー
  'e1345e3b-e6f5-4a10-b54f-699fcb9e66d9'::UUID, -- ランチ休憩スポット
  4, -- 星4つ（良い評価）
  'ランチ休憩に最適な場所です。ベンチもあり、愛犬と一緒にゆっくり食事ができました。水飲み場はありませんが、近くにコンビニがあるので水は調達できます。トイレも近くにあって便利です。ただし、日差しが強い日は日陰が少ないので、パラソルがあると良いかもしれません。',
  false, -- 水飲み場なし
  false, -- ドッグランなし
  false, -- 日陰少ない
  true,  -- トイレあり（近く）
  true,  -- 駐車場あり
  true,  -- 犬用ゴミ箱あり
  true,  -- リード必須
  true,  -- 犬同伴可能なカフェ近くにあり
  'medium', -- 中型犬まで
  '夏は暑いので早朝か夕方がおすすめ。春秋は快適です。',
  ARRAY[
    'https://picsum.photos/seed/lunch1/800/600',
    'https://picsum.photos/seed/lunch2/800/600'
  ]::TEXT[]
)
ON CONFLICT (user_id, spot_id) DO UPDATE SET
  rating = EXCLUDED.rating,
  review_text = EXCLUDED.review_text,
  has_water_fountain = EXCLUDED.has_water_fountain,
  has_dog_run = EXCLUDED.has_dog_run,
  has_shade = EXCLUDED.has_shade,
  has_toilet = EXCLUDED.has_toilet,
  has_parking = EXCLUDED.has_parking,
  has_dog_waste_bin = EXCLUDED.has_dog_waste_bin,
  leash_required = EXCLUDED.leash_required,
  dog_friendly_cafe = EXCLUDED.dog_friendly_cafe,
  dog_size_suitable = EXCLUDED.dog_size_suitable,
  seasonal_info = EXCLUDED.seasonal_info,
  photo_urls = EXCLUDED.photo_urls,
  updated_at = CURRENT_TIMESTAMP;

-- ============================================================
-- データ投入完了の確認クエリ
-- ============================================================
-- 以下のクエリで投入したレビューを確認できます：
--
-- SELECT 
--   sr.id,
--   sr.rating,
--   sr.review_text,
--   sr.has_water_fountain,
--   sr.has_dog_run,
--   sr.has_shade,
--   sr.has_toilet,
--   sr.has_parking,
--   sr.dog_size_suitable,
--   sr.created_at
-- FROM spot_reviews sr
-- WHERE sr.user_id = '00c7e152-bfae-4773-93b5-bab65e64faf2'::UUID
-- ORDER BY sr.created_at DESC;
--
-- 平均評価を確認：
-- SELECT 
--   spot_id,
--   COUNT(*) as review_count,
--   AVG(rating) as average_rating
-- FROM spot_reviews
-- GROUP BY spot_id;

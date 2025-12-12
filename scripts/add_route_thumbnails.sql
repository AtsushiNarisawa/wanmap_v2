-- =====================================================
-- 写真が欠けているコースに写真を追加
-- =====================================================
-- 実行日: 2025-12-10
-- 目的: 6つのコースにWeb検索で見つけた適切な写真を追加

-- 1. お台場海浜公園・豊洲ぐるり公園コース（レインボーブリッジと犬）
UPDATE official_routes
SET thumbnail_url = 'https://sspark.genspark.ai/cfimages?u1=%2B72Xby3jKvEMb%2BTR5DCQJ4eidYootibYvz7BsJnmPTgsrtAGvCIvCcItH2zhB3rYC1NY8Xh7OH8kDgc61ho7L81Dq6Hes%2BYSUn%2FAGmcnmK%2FLORY%2F9%2FDiR78Zr5g3KfJf1OM%2FW8Ry0E7b&u2=dseCIuZHLg6AJ405&width=2560'
WHERE id = 'e0a16a0f-9d5c-4e0b-8b5f-4c3d7e8f9a0b';

-- 2. 井の頭池周遊コース（井の頭公園 池とボート）
UPDATE official_routes
SET thumbnail_url = 'https://sspark.genspark.ai/cfimages?u1=45DGi3Zz82LiIfb2%2FavlCLB8i%2FGVLvWNRHAqVy0afEa1t%2F7%2BYhwffZN57y69Q6ZpSs3bHRznOV4NgUZ6lxTaM0a29lm1ekvrJ4DafHB%2F9AoMPadbHNlyyV0RukpNZ02HrJcSUknJsj2qhDo%3D&u2=bHJMXs5WRN4WPTGQ&width=2560'
WHERE id = '0728410d-a5b1-4576-8b07-cc03bc6a0ed9';

-- 3. 代官山・中目黒おしゃれ散歩（おしゃれな街並み）
UPDATE official_routes
SET thumbnail_url = 'https://sspark.genspark.ai/cfimages?u1=XfuJaWJtJeEoDaXlfpLe1ykOa3085PUws2JVqXjcwkOOd%2B1VhwiZsm7tKyYxNzv3MnpOUYgJlBm4E%2BTvNEUSh0Wk%2BLjgi%2BiZeej4jsrncXNRzB7h7FxlAwW2M8SvuSmGXktGdNSNe8zFAJnipA%3D%3D&u2=CAZgP2aL9nqU659O&width=2560'
WHERE id = 'f1b27b1a-0e6d-4b1c-9c6a-5d4e8f9a0b1c';

-- 4. 多摩川河川敷サイクリングロード散歩（多摩川と犬）
UPDATE official_routes
SET thumbnail_url = 'https://sspark.genspark.ai/cfimages?u1=tKUikEBPlUnZCmEpdmgJezGG5Smu47nT0r31Yk5cuc%2Ff3236nRGt3h3Z8kui6vZZSkjW2pLoLG1oF3aTdunu%2FyeEf2HoVwKgq%2BMIYZ0%2FhA%3D%3D&u2=T5T2%2BjmWbW0WNBP1&width=2560'
WHERE id = 'c8e94e8d-7b3a-4e8f-9f3d-2a1b5c6d7e8f';

-- 5. 山下公園・港の見える丘公園コース（横浜ベイブリッジ）
UPDATE official_routes
SET thumbnail_url = 'https://sspark.genspark.ai/cfimages?u1=zlCv7RsDIEz9A08RpJr8ZrSI8k6omxFOkOtYcNVM%2BiLdqQtSPfaI90xPjI7TZlfNF8r0u76oH9NydSDofjydZhQg46qtxOykgrEc%2FOVS%2FyNdLLrskXVSr3kQQUU%3D&u2=hSTYUpii0cBd7198&width=2560'
WHERE id = '779d1816-0c24-4d91-b5b2-2fbfc3292024';

-- 6. 葛西臨海公園一周コース（観覧車と犬）
UPDATE official_routes
SET thumbnail_url = 'https://sspark.genspark.ai/cfimages?u1=ykjzdwaBwBuIBJBX6lFf8%2BVyoQqL4MaQyLACFZ4Bda0PCdyv2yAlGpTVpPn3bRDWKgP1PqcBIC920GwEXBO%2FrkjM%2F3KW7RaS4aWWDhppIqI13s9IP99MHlNCH8hSYdx9RDzniSaEAndlJ5d1v3amCuHt5%2Bs%3D&u2=BQAdB9RMbO0Yw02j&width=2560'
WHERE id = 'a2c38c2b-1f7e-4c2d-ad7b-6e5f9a0b1c2d';

-- 確認クエリ: 更新された写真を確認
SELECT 
  name AS route_name,
  CASE 
    WHEN thumbnail_url IS NULL OR thumbnail_url = '' THEN '❌ 写真なし'
    ELSE '✅ 写真あり'
  END AS photo_status,
  distance_meters / 1000.0 AS distance_km
FROM official_routes
WHERE id IN (
  'e0a16a0f-9d5c-4e0b-8b5f-4c3d7e8f9a0b',
  '0728410d-a5b1-4576-8b07-cc03bc6a0ed9',
  'f1b27b1a-0e6d-4b1c-9c6a-5d4e8f9a0b1c',
  'c8e94e8d-7b3a-4e8f-9f3d-2a1b5c6d7e8f',
  '779d1816-0c24-4d91-b5b2-2fbfc3292024',
  'a2c38c2b-1f7e-4c2d-ad7b-6e5f9a0b1c2d'
)
ORDER BY name;

-- 全コースの写真ステータスを確認
SELECT 
  COUNT(*) AS total_routes,
  COUNT(thumbnail_url) FILTER (WHERE thumbnail_url IS NOT NULL AND thumbnail_url != '') AS routes_with_photos,
  COUNT(*) FILTER (WHERE thumbnail_url IS NULL OR thumbnail_url = '') AS routes_without_photos
FROM official_routes;

-- 完了メッセージ
SELECT '✅ 6つのコースに写真を追加しました' AS status;

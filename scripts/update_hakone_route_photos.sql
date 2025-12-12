-- =====================================================
-- 箱根エリアのコース写真を正しいものに変更
-- =====================================================
-- 実行日: 2025-12-10
-- 目的: 箱根エリアの4つのコースに適切な実際の写真を設定

-- 1. DogHub周遊コース（DogHubの実際の施設写真）
UPDATE official_routes
SET thumbnail_url = 'https://sspark.genspark.ai/cfimages?u1=D%2BR3ij86PEBsQ7yzmtwrnh7XfXQ78YFfB38i634v1tHwjomHQSg%2BiEzGSao2fs3Y7LrzKt9lavu8DPkcwdSHRj2lwinFze3V1Vd7jzurlATRjz0dM%2F28%2BuSwefOYZUHdHFwRwEM%2BYuZdmvJjzMk81tJT%2FKCvFTY6C%2FXTENKoVGY2Q0N%2FQyrSSyDGUxTxoHIVKwrScM8%2Fm6YTRiIgWn%2F2Jz8G2QS9vOVLIx7JFoX6rWg8iOijOLOpqRiif7MSjkPmdg%3D%3D&u2=BOyHvBxmuLdF71lA&width=2560'
WHERE id = '8d0b7773-cac3-4f5b-938b-f21e92b4c0fe';

-- 2. 箱根旧街道散歩道（石畳と杉並木）
UPDATE official_routes
SET thumbnail_url = 'https://sspark.genspark.ai/cfimages?u1=8s9t3yV%2F%2Fd%2BfaR1z2n5C%2FZp9QNBJlajdLeWnkhyNvmJ658jHDyh%2FWNuSoKEpf3QEJzjz18wnlkzSaW8fxhxn%2Bn9dJSU2xqtIygQMKw%3D%3D&u2=H%2BijUVWfP5%2BzfYFI&width=2560'
WHERE id = 'ad904fb6-f2bd-423c-b7b6-a6abd44b054f';

-- 3. 芦ノ湖湖畔散歩コース（元箱根港〜箱根公園）（箱根神社平和の鳥居と犬）
UPDATE official_routes
SET thumbnail_url = 'https://sspark.genspark.ai/cfimages?u1=aEj9ymgTUhLZUyyT8oEOECMg3mWDZEpj4QWWZxE%2BHftwYt40CStypQbGR5CXRl7wel%2BtNDFhRHYEjcJxjUszeQ0bFIDxmfHWD9uPSopbJMn8cXHTdk%2BQEaF%2FFWI%3D&u2=RJTJ62LKS6PtBMUl&width=2560'
WHERE id = 'd2a04103-3868-4e44-8fdb-eb3433d4e695';

-- 4. 芦ノ湖畔ロングウォーク（芦ノ湖遊覧船と犬）
UPDATE official_routes
SET thumbnail_url = 'https://sspark.genspark.ai/cfimages?u1=RC9ynyZxlPftHzzz4bPjkMK4mdVokpqUrVHJ%2Bi%2BDLZfA69mOthWIhw4PwMCTNYpGlJn3N%2B4CE%2FALGC%2FDwD5PTgsTkoE%2BsCBl9CazZNfQY7CWRMoYYazuLfuYECqFjx23EZruPAZNqptxrcApDGYZ8DbtMfJQDTU5G6%2FhDj6DrYfVdJYpp%2B6FsPfWPzOws%2B12gtASSWzkROt79556uUU%3D&u2=AUp8qSerBgCYiXYd&width=2560'
WHERE id = '6ae42d51-4221-4075-a2c7-cb8572e17cf7';

-- 確認クエリ: 更新された箱根エリアのコースを確認
SELECT 
  r.name AS route_name,
  r.thumbnail_url,
  r.distance_meters / 1000.0 AS distance_km,
  r.estimated_minutes,
  r.difficulty_level,
  a.name AS area_name
FROM official_routes r
JOIN areas a ON a.id = r.area_id
WHERE a.name LIKE '%箱根%'
ORDER BY r.name;

-- 完了メッセージ
SELECT '✅ 箱根エリアの4つのコースの写真を正しいものに変更しました' AS status;

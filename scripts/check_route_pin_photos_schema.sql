-- route_pin_photosテーブルのスキーマを確認
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_schema = 'public'
  AND table_name = 'route_pin_photos'
ORDER BY ordinal_position;

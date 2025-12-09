-- walksテーブルのデータサンプルを確認
SELECT 
  id,
  user_id,
  walk_type,
  route_id,
  start_time,
  created_at
FROM walks
ORDER BY created_at DESC
LIMIT 5;

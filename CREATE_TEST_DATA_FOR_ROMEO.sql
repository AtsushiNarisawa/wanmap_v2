-- ============================================================
-- romeo07302002@gmail.com ユーザー用テストデータ作成
-- ============================================================

-- ステップ1: ユーザーIDを確認
SELECT id, email, display_name FROM public.profiles WHERE email = 'romeo07302002@gmail.com';

-- ステップ2: 上記のクエリ結果からuser_idをコピーして、以下の[USER_ID]を置き換えてください

-- ============================================================
-- テストルート1: 箱根大涌谷散策コース（写真付き）
-- ============================================================

INSERT INTO public.routes (
  id,
  user_id,
  title,
  description,
  distance,
  duration,
  started_at,
  ended_at,
  is_public,
  created_at
) VALUES (
  '11111111-aaaa-aaaa-aaaa-111111111111',
  '[USER_ID]',  -- ここにユーザーIDを入れてください
  '箱根大涌谷散策コース',
  '硫黄の香りと迫力の噴煙を見ながらの散歩。愛犬も興味津々でした！',
  2800,
  2100,
  NOW() - INTERVAL '2 days' - INTERVAL '35 minutes',
  NOW() - INTERVAL '2 days',
  true,
  NOW() - INTERVAL '2 days'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO public.route_points (route_id, latitude, longitude, altitude, timestamp, sequence_number)
SELECT 
  '11111111-aaaa-aaaa-aaaa-111111111111',
  35.2440 + (random() * 0.012 - 0.006),
  139.0230 + (random() * 0.012 - 0.006),
  1000 + (random() * 50),
  NOW() - INTERVAL '2 days' - INTERVAL '35 minutes' + (n || ' seconds')::INTERVAL,
  n
FROM generate_series(0, 209, 1) AS n;

-- 写真4枚を追加（犬と景色の写真）
INSERT INTO public.route_photos (route_id, user_id, storage_path, display_order, caption, created_at) VALUES
('11111111-aaaa-aaaa-aaaa-111111111111', '[USER_ID]', 'https://images.unsplash.com/photo-1568572933382-74d440642117?w=800', 1, '大涌谷の噴煙をバックに', NOW() - INTERVAL '2 days'),
('11111111-aaaa-aaaa-aaaa-111111111111', '[USER_ID]', 'https://images.unsplash.com/photo-1477884213360-7e9d7dcc1e48?w=800', 2, '愛犬も興味津々！', NOW() - INTERVAL '2 days'),
('11111111-aaaa-aaaa-aaaa-111111111111', '[USER_ID]', 'https://images.unsplash.com/photo-1537151608828-ea2b11777ee8?w=800', 3, '休憩中の一枚', NOW() - INTERVAL '2 days'),
('11111111-aaaa-aaaa-aaaa-111111111111', '[USER_ID]', 'https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=800', 4, '絶景ポイントで記念撮影', NOW() - INTERVAL '2 days')
ON CONFLICT DO NOTHING;

-- ============================================================
-- テストルート2: 箱根神社参拝コース（写真付き）
-- ============================================================

INSERT INTO public.routes (
  id,
  user_id,
  title,
  description,
  distance,
  duration,
  started_at,
  ended_at,
  is_public,
  created_at
) VALUES (
  '22222222-bbbb-bbbb-bbbb-222222222222',
  '[USER_ID]',  -- ここにユーザーIDを入れてください
  '箱根神社参拝コース',
  'パワースポットとして有名な箱根神社へ。湖畔の鳥居が美しかったです。',
  3500,
  2700,
  NOW() - INTERVAL '4 days' - INTERVAL '45 minutes',
  NOW() - INTERVAL '4 days',
  true,
  NOW() - INTERVAL '4 days'
) VALUES (
  '22222222-bbbb-bbbb-bbbb-222222222222',
  '[USER_ID]',
  '箱根神社参拝コース',
  'パワースポットとして有名な箱根神社へ。湖畔の鳥居が美しかったです。',
  3500,
  2700,
  NOW() - INTERVAL '4 days' - INTERVAL '45 minutes',
  NOW() - INTERVAL '4 days',
  true,
  NOW() - INTERVAL '4 days'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO public.route_points (route_id, latitude, longitude, altitude, timestamp, sequence_number)
SELECT 
  '22222222-bbbb-bbbb-bbbb-222222222222',
  35.2070 + (random() * 0.014 - 0.007),
  139.0240 + (random() * 0.014 - 0.007),
  730 + (random() * 40),
  NOW() - INTERVAL '4 days' - INTERVAL '45 minutes' + (n || ' seconds')::INTERVAL,
  n
FROM generate_series(0, 269, 1) AS n;

-- 写真3枚を追加
INSERT INTO public.route_photos (route_id, user_id, storage_path, display_order, caption, created_at) VALUES
('22222222-bbbb-bbbb-bbbb-222222222222', '[USER_ID]', 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?w=800', 1, '箱根神社の鳥居', NOW() - INTERVAL '4 days'),
('22222222-bbbb-bbbb-bbbb-222222222222', '[USER_ID]', 'https://images.unsplash.com/photo-1450778869180-41d0601e046e?w=800', 2, '愛犬と一緒に参拝', NOW() - INTERVAL '4 days'),
('22222222-bbbb-bbbb-bbbb-222222222222', '[USER_ID]', 'https://images.unsplash.com/photo-1576201836106-db1758fd1c97?w=800', 3, '湖畔でリフレッシュ', NOW() - INTERVAL '4 days')
ON CONFLICT DO NOTHING;

-- ============================================================
-- 確認用クエリ
-- ============================================================

-- 作成されたルート一覧
SELECT 
  id,
  title,
  distance,
  duration,
  is_public,
  created_at
FROM public.routes
WHERE user_id = '[USER_ID]'
ORDER BY created_at DESC;

-- 各ルートの写真数
SELECT 
  r.title,
  COUNT(p.id) AS photo_count
FROM public.routes r
LEFT JOIN public.route_photos p ON r.id = p.route_id
WHERE r.user_id = '[USER_ID]'
GROUP BY r.id, r.title
ORDER BY r.created_at DESC;

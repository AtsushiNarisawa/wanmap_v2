# 🚀 テストデータ作成 - クイックガイド

## 📝 3ステップで完了

### **ステップ1: Supabaseダッシュボードを開く**

```
https://supabase.com/dashboard
```

1. ログイン
2. プロジェクト「wanmap-v2」を選択
3. 左サイドバー「SQL Editor」をクリック
4. 「New query」をクリック

---

### **ステップ2: 以下のSQLをコピー＆ペースト＆実行**

```sql
-- テストルート1
INSERT INTO public.routes (id, user_id, title, description, distance, duration, started_at, ended_at, is_public, created_at) 
VALUES ('aaaaaaaa-1111-1111-1111-000000000001', 'da43ce7b-8161-4eb6-a8c5-a7ac14178b1d', '芦ノ湖畔の朝散歩コース', '芦ノ湖の美しい景色を眺めながらの爽やかな朝の散歩。愛犬も大喜びでした！', 2500, 1800, NOW() - INTERVAL '5 days' - INTERVAL '30 minutes', NOW() - INTERVAL '5 days', true, NOW() - INTERVAL '5 days') 
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.route_points (route_id, latitude, longitude, altitude, timestamp, sequence_number)
SELECT 'aaaaaaaa-1111-1111-1111-000000000001', 35.2050 + (random() * 0.01 - 0.005), 139.0250 + (random() * 0.01 - 0.005), 120 + (random() * 30), NOW() - INTERVAL '5 days' - INTERVAL '30 minutes' + (n || ' seconds')::INTERVAL, n
FROM generate_series(0, 179, 1) AS n;

INSERT INTO public.route_photos (route_id, user_id, storage_path, public_url, caption, created_at) VALUES
('aaaaaaaa-1111-1111-1111-000000000001', 'da43ce7b-8161-4eb6-a8c5-a7ac14178b1d', 'test/route1/1.jpg', 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?w=800', '芦ノ湖の美しい景色', NOW() - INTERVAL '5 days'),
('aaaaaaaa-1111-1111-1111-000000000001', 'da43ce7b-8161-4eb6-a8c5-a7ac14178b1d', 'test/route1/2.jpg', 'https://images.unsplash.com/photo-1587300003388-59208cc962cb?w=800', '愛犬も大喜び！', NOW() - INTERVAL '5 days'),
('aaaaaaaa-1111-1111-1111-000000000001', 'da43ce7b-8161-4eb6-a8c5-a7ac14178b1d', 'test/route1/3.jpg', 'https://images.unsplash.com/photo-1552053831-71594a27632d?w=800', '湖畔で休憩', NOW() - INTERVAL '5 days')
ON CONFLICT DO NOTHING;

-- テストルート2
INSERT INTO public.routes (id, user_id, title, description, distance, duration, started_at, ended_at, is_public, created_at) 
VALUES ('bbbbbbbb-2222-2222-2222-000000000002', 'da43ce7b-8161-4eb6-a8c5-a7ac14178b1d', '箱根旧街道 歴史散歩', '石畳の旧街道を歩く歴史ロマン溢れる散歩コース。杉並木が素晴らしかったです。', 3200, 2400, NOW() - INTERVAL '3 days' - INTERVAL '40 minutes', NOW() - INTERVAL '3 days', true, NOW() - INTERVAL '3 days') 
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.route_points (route_id, latitude, longitude, altitude, timestamp, sequence_number)
SELECT 'bbbbbbbb-2222-2222-2222-000000000002', 35.2150 + (random() * 0.015 - 0.0075), 139.0320 + (random() * 0.015 - 0.0075), 150 + (random() * 50), NOW() - INTERVAL '3 days' - INTERVAL '40 minutes' + (n || ' seconds')::INTERVAL, n
FROM generate_series(0, 239, 1) AS n;

INSERT INTO public.route_photos (route_id, user_id, storage_path, public_url, caption, created_at) VALUES
('bbbbbbbb-2222-2222-2222-000000000002', 'da43ce7b-8161-4eb6-a8c5-a7ac14178b1d', 'test/route2/1.jpg', 'https://images.unsplash.com/photo-1517849845537-4d257902454a?w=800', '石畳の旧街道', NOW() - INTERVAL '3 days'),
('bbbbbbbb-2222-2222-2222-000000000002', 'da43ce7b-8161-4eb6-a8c5-a7ac14178b1d', 'test/route2/2.jpg', 'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?w=800', '杉並木の中を散歩', NOW() - INTERVAL '3 days')
ON CONFLICT DO NOTHING;

-- テストルート3
INSERT INTO public.routes (id, user_id, title, description, distance, duration, started_at, ended_at, is_public, created_at) 
VALUES ('cccccccc-3333-3333-3333-000000000003', 'da43ce7b-8161-4eb6-a8c5-a7ac14178b1d', '仙石原すすき草原 夕焼けコース', '黄金色に輝くすすき草原での夕方散歩。愛犬も走り回って楽しそうでした！', 1800, 1500, NOW() - INTERVAL '1 day' - INTERVAL '25 minutes', NOW() - INTERVAL '1 day', true, NOW() - INTERVAL '1 day') 
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.route_points (route_id, latitude, longitude, altitude, timestamp, sequence_number)
SELECT 'cccccccc-3333-3333-3333-000000000003', 35.2400 + (random() * 0.008 - 0.004), 139.0150 + (random() * 0.008 - 0.004), 140 + (random() * 20), NOW() - INTERVAL '1 day' - INTERVAL '25 minutes' + (n || ' seconds')::INTERVAL, n
FROM generate_series(0, 149, 1) AS n;

INSERT INTO public.route_photos (route_id, user_id, storage_path, public_url, caption, created_at) VALUES
('cccccccc-3333-3333-3333-000000000003', 'da43ce7b-8161-4eb6-a8c5-a7ac14178b1d', 'test/route3/1.jpg', 'https://images.unsplash.com/photo-1530281700549-e82e7bf110d6?w=800', '夕焼けのすすき草原', NOW() - INTERVAL '1 day'),
('cccccccc-3333-3333-3333-000000000003', 'da43ce7b-8161-4eb6-a8c5-a7ac14178b1d', 'test/route3/2.jpg', 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?w=800', '愛犬も大はしゃぎ', NOW() - INTERVAL '1 day'),
('cccccccc-3333-3333-3333-000000000003', 'da43ce7b-8161-4eb6-a8c5-a7ac14178b1d', 'test/route3/3.jpg', 'https://images.unsplash.com/photo-1558788353-f76d92427f16?w=800', 'すすき草原で記念撮影', NOW() - INTERVAL '1 day')
ON CONFLICT DO NOTHING;

-- 確認用
SELECT id, title, distance, duration FROM public.routes WHERE user_id = 'da43ce7b-8161-4eb6-a8c5-a7ac14178b1d' ORDER BY created_at DESC;
```

**右下の「RUN」ボタンをクリック**

**成功の確認**: 3件のルートが表示される

---

### **ステップ3: iPhoneアプリで確認**

1. **アプリを再起動**
2. **ホーム画面**: 3件のルートが表示される
3. **各ルートをタップ**: 地図＋写真が表示される
4. **「写真を追加」ボタン**: タップしてテスト

---

## ✅ 確認項目

- [ ] ホーム画面に3件のルート表示
- [ ] 地図上にルートが赤線で描画
- [ ] スタート/ゴール地点にアイコン表示
- [ ] 合計8枚の写真が表示（3+2+3枚）
- [ ] 「写真を追加」ボタンが機能

---

## 📋 作成されるデータ

| ルート | 距離 | 時間 | 写真 | ポイント |
|--------|------|------|------|---------|
| 芦ノ湖畔 | 2.5km | 30分 | 3枚 | 180個 |
| 箱根旧街道 | 3.2km | 40分 | 2枚 | 240個 |
| すすき草原 | 1.8km | 25分 | 3枚 | 150個 |

---

**詳細な手順は `TEST_DATA_CREATION_GUIDE.md` を参照してください。**

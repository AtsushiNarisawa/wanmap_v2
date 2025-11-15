# WanMap テストデータ セットアップガイド

## 📋 概要

このガイドでは、WanMapアプリにテストデータ（散歩ルート3件 + 写真8枚）を追加する手順を説明します。

---

## 🚀 **方法1: Supabase SQL Editor で実行（推奨）**

### **手順：**

1. **Supabaseダッシュボードにアクセス**
   - https://supabase.com/dashboard にアクセス
   - プロジェクト「jkpenklhrlbctebkpvax」を開く

2. **SQL Editorを開く**
   - 左サイドバーの「SQL Editor」をクリック
   - 「New query」をクリック

3. **SQLスクリプトを実行**
   - 下記のSQLスクリプトをコピー&ペースト
   - 「RUN」ボタンをクリック

4. **iPhoneアプリで確認**
   - アプリを再起動
   - ホーム画面でルート一覧を確認
   - ルートをタップして詳細画面を確認

---

## 📝 **SQLスクリプト（コピーしてSupabase SQL Editorで実行）**

```sql
-- WanMap テストデータ挿入スクリプト
-- 既存のユーザー(da43ce7b-8161-4eb6-a8c5-a7ac14178b1d)を使用

-- ============================================================
-- テストルート1: 芦ノ湖畔の朝散歩コース
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
  'aaaaaaaa-1111-1111-1111-000000000001',
  'da43ce7b-8161-4eb6-a8c5-a7ac14178b1d',
  '芦ノ湖畔の朝散歩コース',
  '芦ノ湖の美しい景色を眺めながらの爽やかな朝の散歩。愛犬も大喜びでした！',
  2500,
  1800,
  NOW() - INTERVAL '5 days' - INTERVAL '30 minutes',
  NOW() - INTERVAL '5 days',
  true,
  NOW() - INTERVAL '5 days'
) ON CONFLICT (id) DO NOTHING;

-- GPSポイント（スタート地点から徐々に移動）
INSERT INTO public.route_points (route_id, latitude, longitude, altitude, timestamp, sequence_number)
SELECT 
  'aaaaaaaa-1111-1111-1111-000000000001',
  35.2050 + (random() * 0.01 - 0.005),
  139.0250 + (random() * 0.01 - 0.005),
  120 + (random() * 30),
  NOW() - INTERVAL '5 days' - INTERVAL '30 minutes' + (n || ' seconds')::INTERVAL,
  n
FROM generate_series(0, 179, 1) AS n;

-- 写真3枚
INSERT INTO public.route_photos (route_id, user_id, storage_path, public_url, caption, created_at) VALUES
('aaaaaaaa-1111-1111-1111-000000000001', 'da43ce7b-8161-4eb6-a8c5-a7ac14178b1d', 'test/route1/1.jpg', 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?w=800', '芦ノ湖の美しい景色', NOW() - INTERVAL '5 days'),
('aaaaaaaa-1111-1111-1111-000000000001', 'da43ce7b-8161-4eb6-a8c5-a7ac14178b1d', 'test/route1/2.jpg', 'https://images.unsplash.com/photo-1587300003388-59208cc962cb?w=800', '愛犬も大喜び！', NOW() - INTERVAL '5 days'),
('aaaaaaaa-1111-1111-1111-000000000001', 'da43ce7b-8161-4eb6-a8c5-a7ac14178b1d', 'test/route1/3.jpg', 'https://images.unsplash.com/photo-1552053831-71594a27632d?w=800', '湖畔で休憩', NOW() - INTERVAL '5 days')
ON CONFLICT DO NOTHING;

-- ============================================================
-- テストルート2: 箱根旧街道 歴史散歩
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
  'bbbbbbbb-2222-2222-2222-000000000002',
  'da43ce7b-8161-4eb6-a8c5-a7ac14178b1d',
  '箱根旧街道 歴史散歩',
  '石畳の旧街道を歩く歴史ロマン溢れる散歩コース。杉並木が素晴らしかったです。',
  3200,
  2400,
  NOW() - INTERVAL '3 days' - INTERVAL '40 minutes',
  NOW() - INTERVAL '3 days',
  true,
  NOW() - INTERVAL '3 days'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO public.route_points (route_id, latitude, longitude, altitude, timestamp, sequence_number)
SELECT 
  'bbbbbbbb-2222-2222-2222-000000000002',
  35.2150 + (random() * 0.015 - 0.0075),
  139.0320 + (random() * 0.015 - 0.0075),
  150 + (random() * 50),
  NOW() - INTERVAL '3 days' - INTERVAL '40 minutes' + (n || ' seconds')::INTERVAL,
  n
FROM generate_series(0, 239, 1) AS n;

INSERT INTO public.route_photos (route_id, user_id, storage_path, public_url, caption, created_at) VALUES
('bbbbbbbb-2222-2222-2222-000000000002', 'da43ce7b-8161-4eb6-a8c5-a7ac14178b1d', 'test/route2/1.jpg', 'https://images.unsplash.com/photo-1517849845537-4d257902454a?w=800', '石畳の旧街道', NOW() - INTERVAL '3 days'),
('bbbbbbbb-2222-2222-2222-000000000002', 'da43ce7b-8161-4eb6-a8c5-a7ac14178b1d', 'test/route2/2.jpg', 'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?w=800', '杉並木の中を散歩', NOW() - INTERVAL '3 days')
ON CONFLICT DO NOTHING;

-- ============================================================
-- テストルート3: 仙石原すすき草原 夕焼けコース
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
  'cccccccc-3333-3333-3333-000000000003',
  'da43ce7b-8161-4eb6-a8c5-a7ac14178b1d',
  '仙石原すすき草原 夕焼けコース',
  '黄金色に輝くすすき草原での夕方散歩。愛犬も走り回って楽しそうでした！',
  1800,
  1500,
  NOW() - INTERVAL '1 day' - INTERVAL '25 minutes',
  NOW() - INTERVAL '1 day',
  true,
  NOW() - INTERVAL '1 day'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO public.route_points (route_id, latitude, longitude, altitude, timestamp, sequence_number)
SELECT 
  'cccccccc-3333-3333-3333-000000000003',
  35.2400 + (random() * 0.008 - 0.004),
  139.0150 + (random() * 0.008 - 0.004),
  140 + (random() * 20),
  NOW() - INTERVAL '1 day' - INTERVAL '25 minutes' + (n || ' seconds')::INTERVAL,
  n
FROM generate_series(0, 149, 1) AS n;

INSERT INTO public.route_photos (route_id, user_id, storage_path, public_url, caption, created_at) VALUES
('cccccccc-3333-3333-3333-000000000003', 'da43ce7b-8161-4eb6-a8c5-a7ac14178b1d', 'test/route3/1.jpg', 'https://images.unsplash.com/photo-1530281700549-e82e7bf110d6?w=800', '夕焼けのすすき草原', NOW() - INTERVAL '1 day'),
('cccccccc-3333-3333-3333-000000000003', 'da43ce7b-8161-4eb6-a8c5-a7ac14178b1d', 'test/route3/2.jpg', 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?w=800', '愛犬も大はしゃぎ', NOW() - INTERVAL '1 day'),
('cccccccc-3333-3333-3333-000000000003', 'da43ce7b-8161-4eb6-a8c5-a7ac14178b1d', 'test/route3/3.jpg', 'https://images.unsplash.com/photo-1558788353-f76d92427f16?w=800', 'すすき草原で記念撮影', NOW() - INTERVAL '1 day')
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
WHERE user_id = 'da43ce7b-8161-4eb6-a8c5-a7ac14178b1d'
ORDER BY created_at DESC;

-- 各ルートのポイント数
SELECT 
  r.title,
  COUNT(rp.id) AS point_count
FROM public.routes r
LEFT JOIN public.route_points rp ON r.id = rp.route_id
WHERE r.user_id = 'da43ce7b-8161-4eb6-a8c5-a7ac14178b1d'
GROUP BY r.id, r.title
ORDER BY r.created_at DESC;

-- 各ルートの写真数
SELECT 
  r.title,
  COUNT(p.id) AS photo_count
FROM public.routes r
LEFT JOIN public.route_photos p ON r.id = p.route_id
WHERE r.user_id = 'da43ce7b-8161-4eb6-a8c5-a7ac14178b1d'
GROUP BY r.id, r.title
ORDER BY r.created_at DESC;
```

---

## ✅ **作成されるテストデータ**

### **ルート1: 芦ノ湖畔の朝散歩コース**
- 📍 距離: 2.5km
- ⏱️ 時間: 30分
- 📸 写真: 3枚
- 📍 GPSポイント: 180件

### **ルート2: 箱根旧街道 歴史散歩**
- 📍 距離: 3.2km
- ⏱️ 時間: 40分
- 📸 写真: 2枚
- 📍 GPSポイント: 240件

### **ルート3: 仙石原すすき草原 夕焼けコース**
- 📍 距離: 1.8km
- ⏱️ 時間: 25分
- 📸 写真: 3枚
- 📍 GPSポイント: 150件

---

## 📱 **iPhoneアプリでの確認方法**

### **1. ホーム画面**
- アプリを再起動
- ホーム画面で3件のルートが表示されることを確認
- 各ルートカードに距離、時間、タイトルが表示されることを確認

### **2. ルート詳細画面**
各ルートをタップして以下を確認：

#### ✅ **地図表示**
- 地図が正しく表示される
- 赤い線でルートが描画される
- スタート地点（緑の再生アイコン）が表示される
- ゴール地点（赤の停止アイコン）が表示される
- ダークモード切り替えでマップタイルが変更される

#### ✅ **統計情報**
- 距離（例: 2.5km）
- 時間（例: 30分）
- 日付

#### ✅ **写真ギャラリー**
- 写真が3列のグリッド表示される
- 各写真にキャプションが表示される
- 「写真を追加」ボタンが表示される（自分のルートのみ）

#### ✅ **写真追加機能のテスト**
1. 「写真を追加」ボタンをタップ
2. ダイアログが表示される
   - 「ギャラリーから選択」
   - 「カメラで撮影」
3. どちらかを選択して写真をアップロード
4. 新しい写真がギャラリーに追加される

---

## 🗑️ **テストデータの削除（必要に応じて）**

テストデータを削除する場合は、以下のSQLを実行してください：

```sql
-- テストルートの写真を削除
DELETE FROM public.route_photos 
WHERE route_id IN (
  'aaaaaaaa-1111-1111-1111-000000000001',
  'bbbbbbbb-2222-2222-2222-000000000002',
  'cccccccc-3333-3333-3333-000000000003'
);

-- テストルートのGPSポイントを削除
DELETE FROM public.route_points 
WHERE route_id IN (
  'aaaaaaaa-1111-1111-1111-000000000001',
  'bbbbbbbb-2222-2222-2222-000000000002',
  'cccccccc-3333-3333-3333-000000000003'
);

-- テストルートを削除
DELETE FROM public.routes 
WHERE id IN (
  'aaaaaaaa-1111-1111-1111-000000000001',
  'bbbbbbbb-2222-2222-2222-000000000002',
  'cccccccc-3333-3333-3333-000000000003'
);
```

---

## 📝 **注意事項**

1. **ユーザーID**: このスクリプトは既存のユーザーID `da43ce7b-8161-4eb6-a8c5-a7ac14178b1d` を使用しています
2. **写真URL**: Unsplash APIから犬の写真を使用しています（インターネット接続が必要）
3. **公開ルート**: 全てのルートは `is_public = true` で作成されます
4. **GPSポイント**: ランダムに生成された箱根周辺の座標を使用しています

---

## 🆘 **トラブルシューティング**

### **Q: SQLエラーが発生する**
A: ユーザーIDが存在しない可能性があります。以下のクエリで確認してください：
```sql
SELECT id, display_name FROM public.profiles LIMIT 5;
```

### **Q: アプリにルートが表示されない**
A: 
1. アプリを完全に再起動してください
2. ログアウト→ログインを試してください
3. SupabaseダッシュボードでデータがINSERTされているか確認してください

### **Q: 写真が表示されない**
A: 
1. インターネット接続を確認してください
2. Unsplash URLにアクセスできるか確認してください

---

**テストデータ作成後、必ずiPhoneアプリで動作確認してください！** 🐕✨

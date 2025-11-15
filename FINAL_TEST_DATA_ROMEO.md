# 📱 romeo07302002@gmail.com 用テストデータ作成手順

## 🎯 目的
現在ログイン中のユーザー（romeo07302002@gmail.com）で写真付きテストルートを作成し、「写真を追加」ボタンの動作を確認します。

---

## 📝 手順

### **ステップ1: Supabase SQL Editorで以下を実行**

```sql
-- ユーザーIDを確認
SELECT id, email, display_name FROM public.profiles WHERE email = 'romeo07302002@gmail.com';
```

**結果をメモ**: `id` の値（UUIDの長い文字列）をコピーしてください

---

### **ステップ2: 以下のSQLの `[USER_ID]` を上記のIDに置き換えて実行**

**重要**: 以下のSQL内の **`[USER_ID]`** の部分を、ステップ1で取得したIDに置き換えてください。

```sql
-- ============================================================
-- テストルート1: 箱根大涌谷散策コース（写真4枚付き）
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
  '[USER_ID]',
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

INSERT INTO public.route_photos (route_id, user_id, storage_path, display_order, caption, created_at) VALUES
('11111111-aaaa-aaaa-aaaa-111111111111', '[USER_ID]', 'https://images.unsplash.com/photo-1568572933382-74d440642117?w=800', 1, '大涌谷の噴煙をバックに', NOW() - INTERVAL '2 days'),
('11111111-aaaa-aaaa-aaaa-111111111111', '[USER_ID]', 'https://images.unsplash.com/photo-1477884213360-7e9d7dcc1e48?w=800', 2, '愛犬も興味津々！', NOW() - INTERVAL '2 days'),
('11111111-aaaa-aaaa-aaaa-111111111111', '[USER_ID]', 'https://images.unsplash.com/photo-1537151608828-ea2b11777ee8?w=800', 3, '休憩中の一枚', NOW() - INTERVAL '2 days'),
('11111111-aaaa-aaaa-aaaa-111111111111', '[USER_ID]', 'https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=800', 4, '絶景ポイントで記念撮影', NOW() - INTERVAL '2 days')
ON CONFLICT DO NOTHING;

-- ============================================================
-- テストルート2: 箱根神社参拝コース（写真3枚付き）
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

INSERT INTO public.route_photos (route_id, user_id, storage_path, display_order, caption, created_at) VALUES
('22222222-bbbb-bbbb-bbbb-222222222222', '[USER_ID]', 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?w=800', 1, '箱根神社の鳥居', NOW() - INTERVAL '4 days'),
('22222222-bbbb-bbbb-bbbb-222222222222', '[USER_ID]', 'https://images.unsplash.com/photo-1450778869180-41d0601e046e?w=800', 2, '愛犬と一緒に参拝', NOW() - INTERVAL '4 days'),
('22222222-bbbb-bbbb-bbbb-222222222222', '[USER_ID]', 'https://images.unsplash.com/photo-1576201836106-db1758fd1c97?w=800', 3, '湖畔でリフレッシュ', NOW() - INTERVAL '4 days')
ON CONFLICT DO NOTHING;

-- 確認用クエリ
SELECT 
  r.id,
  r.title,
  r.distance,
  r.duration,
  COUNT(p.id) AS photo_count
FROM public.routes r
LEFT JOIN public.route_photos p ON r.id = p.route_id
WHERE r.user_id = '[USER_ID]'
GROUP BY r.id, r.title, r.distance, r.duration
ORDER BY r.created_at DESC;
```

---

## ✅ 成功の確認

SQL実行後、以下が表示されればOK：

```
title                    | distance | duration | photo_count
-------------------------|----------|----------|-------------
箱根神社参拝コース        | 3500     | 2700     | 3
箱根大涌谷散策コース      | 2800     | 2100     | 4
```

---

## 📱 iPhoneアプリで確認

### **1. アプリを再起動**

### **2. ホーム画面で確認**
- [ ] 新しく2件のルートが表示される
  - 箱根大涌谷散策コース
  - 箱根神社参拝コース

### **3. ルート詳細画面で確認**

#### **箱根大涌谷散策コース**
- [ ] ルートカードをタップ
- [ ] 地図にルートが描画される
- [ ] **写真ギャラリーに4枚の写真が表示される**
  - 大涌谷の噴煙をバックに
  - 愛犬も興味津々！
  - 休憩中の一枚
  - 絶景ポイントで記念撮影
- [ ] **「写真を追加」ボタンが表示される** ← 重要！

#### **箱根神社参拝コース**
- [ ] ルートカードをタップ
- [ ] 地図にルートが描画される
- [ ] **写真ギャラリーに3枚の写真が表示される**
  - 箱根神社の鳥居
  - 愛犬と一緒に参拝
  - 湖畔でリフレッシュ
- [ ] **「写真を追加」ボタンが表示される** ← 重要！

### **4. 写真追加機能をテスト**

1. 「写真を追加」ボタンをタップ
2. ダイアログが表示される
   - [ ] 「ギャラリーから選択」
   - [ ] 「カメラで撮影」
3. どちらかを選択
4. 写真を選択/撮影
5. 写真がアップロードされる
6. 新しい写真がギャラリーに追加される

---

## 🎯 確認ポイント

### **今回確認したいこと**
- ✅ 自分のルートには「写真を追加」ボタンが表示される
- ✅ 写真が3列グリッドで表示される（4枚と3枚）
- ✅ 「写真を追加」ボタンをタップすると写真を追加できる
- ✅ 地図上にルートが正常に描画される

---

## 📊 作成されるデータ

| ルート名 | 距離 | 時間 | 写真枚数 | GPSポイント |
|---------|------|------|---------|------------|
| 箱根大涌谷散策コース | 2.8km | 35分 | 4枚 | 210個 |
| 箱根神社参拝コース | 3.5km | 45分 | 3枚 | 270個 |
| **合計** | **6.3km** | **80分** | **7枚** | **480個** |

---

## 🗑️ テストデータの削除（必要に応じて）

```sql
-- テストルートの写真を削除
DELETE FROM public.route_photos 
WHERE route_id IN (
  '11111111-aaaa-aaaa-aaaa-111111111111',
  '22222222-bbbb-bbbb-bbbb-222222222222'
);

-- テストルートのGPSポイントを削除
DELETE FROM public.route_points 
WHERE route_id IN (
  '11111111-aaaa-aaaa-aaaa-111111111111',
  '22222222-bbbb-bbbb-bbbb-222222222222'
);

-- テストルートを削除
DELETE FROM public.routes 
WHERE id IN (
  '11111111-aaaa-aaaa-aaaa-111111111111',
  '22222222-bbbb-bbbb-bbbb-222222222222'
);
```

---

**この手順に従って、テストデータを作成してください！** 🚀

特に「写真を追加」ボタンが表示されて、実際に写真を追加できるかどうかを確認してください！

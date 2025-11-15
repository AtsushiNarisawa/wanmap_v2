# 🐕 WanMap テストデータ作成ガイド

## 📋 目的

iPhone 12 SEでルート詳細画面の機能（地図表示・写真ギャラリー）を確認するため、テストデータを作成します。

---

## ✅ 前提条件の確認

### **Supabaseプロジェクト情報**
- **プロジェクト名**: wanmap-v2
- **プロジェクトID**: jkpenklhrlbctebkpvax
- **URL**: https://jkpenklhrlbctebkpvax.supabase.co
- ✅ 既に`env.dart`に設定済み

### **現在のユーザー**
- **ユーザーID**: da43ce7b-8161-4eb6-a8c5-a7ac14178b1d
- **表示名**: newuser

---

## 🚀 ステップ1: Supabaseダッシュボードにアクセス

1. ブラウザで以下のURLを開く
   ```
   https://supabase.com/dashboard
   ```

2. ログインする（既にログイン済みの場合はスキップ）

3. プロジェクト一覧から **「wanmap-v2」** をクリック
   - プロジェクトIDが `jkpenklhrlbctebkpvax` であることを確認

---

## 🚀 ステップ2: SQL Editorを開く

1. 左サイドバーから **「SQL Editor」** をクリック

2. 右上の **「New query」** ボタンをクリック

3. 空のSQLエディタが開く

---

## 🚀 ステップ3: SQLスクリプトをコピー

以下のSQLスクリプト全体をコピーしてください：

```sql
-- ============================================================
-- WanMap テストデータ挿入スクリプト
-- ユーザーID: da43ce7b-8161-4eb6-a8c5-a7ac14178b1d
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

INSERT INTO public.route_points (route_id, latitude, longitude, altitude, timestamp, sequence_number)
SELECT 
  'aaaaaaaa-1111-1111-1111-000000000001',
  35.2050 + (random() * 0.01 - 0.005),
  139.0250 + (random() * 0.01 - 0.005),
  120 + (random() * 30),
  NOW() - INTERVAL '5 days' - INTERVAL '30 minutes' + (n || ' seconds')::INTERVAL,
  n
FROM generate_series(0, 179, 1) AS n;

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
-- 確認用クエリ（実行結果を確認）
-- ============================================================

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
```

---

## 🚀 ステップ4: SQLスクリプトを実行

1. コピーしたSQLスクリプトを **SQL Editorにペースト**

2. 右下の **「RUN」ボタン** をクリック

3. **実行結果を確認**
   - 成功メッセージが表示される
   - 最後の確認用クエリで **3件のルート** が表示される

**期待される結果:**
```
title                          | distance | duration | is_public
-------------------------------|----------|----------|----------
仙石原すすき草原 夕焼けコース    | 1800     | 1500     | true
箱根旧街道 歴史散歩            | 3200     | 2400     | true
芦ノ湖畔の朝散歩コース          | 2500     | 1800     | true
```

---

## 🚀 ステップ5: iPhoneアプリで確認

### **5-1. アプリを再起動**

1. iPhone 12 SEでWanMapアプリを完全に終了
   - ホームボタンをダブルクリック（またはスワイプアップ）
   - アプリを上にスワイプして終了

2. アプリを再度起動

### **5-2. ホーム画面で確認**

- [ ] ルート一覧に **3件のルート** が表示される
  - 芦ノ湖畔の朝散歩コース
  - 箱根旧街道 歴史散歩
  - 仙石原すすき草原 夕焼けコース
- [ ] 各ルートカードに距離・時間・タイトルが表示される

### **5-3. ルート詳細画面で確認（各ルートで実施）**

#### **ルート1: 芦ノ湖畔の朝散歩コース**

1. ルートカードをタップ

2. **地図表示を確認**
   - [ ] 地図が表示される
   - [ ] 赤い線でルートが描画される
   - [ ] スタート地点に緑の再生アイコンが表示される
   - [ ] ゴール地点に赤の停止アイコンが表示される

3. **統計情報を確認**
   - [ ] 距離: 2.5km
   - [ ] 時間: 30分
   - [ ] 日付が表示される

4. **写真ギャラリーを確認**
   - [ ] 「写真」セクションが表示される
   - [ ] **3枚の犬の写真** が3列グリッドで表示される
   - [ ] 各写真にキャプションが表示される
     - 「芦ノ湖の美しい景色」
     - 「愛犬も大喜び！」
     - 「湖畔で休憩」
   - [ ] 「写真を追加」ボタンが表示される（自分のルート）

5. **写真追加機能をテスト**
   - [ ] 「写真を追加」ボタンをタップ
   - [ ] ダイアログが表示される
     - 「ギャラリーから選択」
     - 「カメラで撮影」
   - [ ] どちらかを選択して実際に写真を追加してみる

#### **ルート2: 箱根旧街道 歴史散歩**

1. ホーム画面に戻る

2. 「箱根旧街道 歴史散歩」をタップ

3. 同様に確認
   - [ ] 地図表示
   - [ ] 統計情報（3.2km、40分）
   - [ ] **2枚の写真** が表示される

#### **ルート3: 仙石原すすき草原 夕焼けコース**

1. ホーム画面に戻る

2. 「仙石原すすき草原 夕焼けコース」をタップ

3. 同様に確認
   - [ ] 地図表示
   - [ ] 統計情報（1.8km、25分）
   - [ ] **3枚の写真** が表示される

### **5-4. ダークモード切り替えテスト（オプション）**

1. iPhoneの設定アプリを開く

2. 「画面表示と明るさ」→「ダークモード」をオン

3. WanMapアプリに戻る

4. ルート詳細画面を確認
   - [ ] 地図のタイルがダークテーマに変わる
   - [ ] UIがダークモードで表示される

---

## ✅ 成功の確認ポイント

### **全て確認できたら成功です！**

- ✅ 3件のルートが表示される
- ✅ 各ルート詳細で地図にルートが描画される
- ✅ 合計8枚の写真が表示される（3枚+2枚+3枚）
- ✅ 「写真を追加」ボタンが機能する
- ✅ ダークモードでマップタイルが変わる

---

## 📊 作成されるテストデータの詳細

| ルート名 | 距離 | 時間 | 写真枚数 | GPSポイント数 |
|---------|------|------|---------|-------------|
| 芦ノ湖畔の朝散歩コース | 2.5km | 30分 | 3枚 | 180件 |
| 箱根旧街道 歴史散歩 | 3.2km | 40分 | 2枚 | 240件 |
| 仙石原すすき草原 夕焼けコース | 1.8km | 25分 | 3枚 | 150件 |
| **合計** | **7.5km** | **95分** | **8枚** | **570件** |

---

## 🗑️ テストデータの削除（必要に応じて）

テスト完了後、データを削除する場合はSupabase SQL Editorで以下を実行：

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

## 🆘 トラブルシューティング

### **Q1: SQLエラー「relation "public.routes" does not exist」**

**原因**: テーブルが作成されていない

**解決方法**:
1. `supabase_migrations/complete_schema_with_social.sql` を実行
2. Table Editorで `routes`, `route_points`, `route_photos` テーブルの存在を確認

### **Q2: アプリにルートが表示されない**

**原因**: アプリのキャッシュ問題

**解決方法**:
1. アプリを完全に終了して再起動
2. ログアウト→ログインを試す
3. Supabase Table Editorでデータが挿入されているか確認

### **Q3: 写真が表示されない**

**原因**: インターネット接続の問題

**解決方法**:
1. Wi-Fi接続を確認
2. ブラウザで写真URL（Unsplash）にアクセスできるか確認
3. アプリを再起動

### **Q4: 「写真を追加」ボタンが表示されない**

**原因**: 他人のルートを見ている

**確認方法**:
- ルート詳細画面で、自分が作成したルートであることを確認
- テストデータは全て自分のユーザーID（da43ce7b...）で作成されているので表示されるはず

---

## 🎯 次のステップ

### **テストデータ確認後**

1. **写真機能が正常に動作することを確認**
   - ✅ 過去の懸念（写真追加ができない）は解消

2. **ルート保存問題の修正に進む**
   - map_screen.dartの`stopRecording()`が2回呼ばれる問題を修正
   - 新しいルートを記録してSupabaseに保存できるようにする

3. **Phase 25-27の統合**
   - オフラインバナーの追加
   - パフォーマンス最適化
   - エラーハンドリング強化

---

**このガイドに従って、テストデータを作成してください！** 🐕✨

何か問題があれば、すぐにお知らせください！

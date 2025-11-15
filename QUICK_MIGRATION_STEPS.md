# 📋 クイックマイグレーション手順

## Supabaseデータベース更新（5分で完了）

### ステップ1: Supabaseにアクセス

1. ブラウザで https://supabase.com にアクセス
2. ログイン
3. プロジェクト **wanmap-v2** を選択

### ステップ2: SQL Editorを開く

1. 左サイドバーから **SQL Editor** をクリック
2. 右上の **+ New query** をクリック

### ステップ3: SQLをコピー&実行

1. 以下のファイルを開く:
   ```
   supabase_migrations/add_area_fields_to_routes.sql
   ```

2. **全ての内容**をコピー（136行全て）

3. SQL Editorに貼り付け

4. 右下の **RUN** ボタンをクリック

### ステップ4: 実行結果を確認

成功すると以下のメッセージが表示されます：
```
Success. No rows returned
```

### ステップ5: 変更を確認（オプション）

以下のクエリをSQL Editorで実行して確認：

```sql
-- カラムが追加されたか確認
SELECT 
  column_name, 
  data_type
FROM information_schema.columns
WHERE table_name = 'routes'
AND column_name IN ('area', 'prefecture', 'thumbnail_url');
```

結果として3行表示されればOK：
```
area          | character varying
prefecture    | character varying
thumbnail_url | text
```

### ステップ6: 既存データの確認（オプション）

```sql
-- エリア別のルート数を確認
SELECT 
  COALESCE(area, 'unknown') as area,
  COUNT(*) as route_count
FROM public.routes
WHERE is_public = true
GROUP BY area
ORDER BY route_count DESC;
```

---

## ✅ 完了！

マイグレーションが完了しました。これでアプリで以下の機能が使えます：

1. ✅ エリア選択チップ（箱根、伊豆、那須、etc.）
2. ✅ マップビューで複数ルート表示
3. ✅ 写真付きルートカード

---

## ⚠️ トラブルシューティング

### エラー: "column already exists"

すでに実行済みです。問題ありません。

### エラー: "permission denied"

Supabaseダッシュボードに正しくログインしているか確認してください。

### ルートにエリアが設定されない

GPS座標がエリア範囲外の可能性があります。手動で設定する場合：

```sql
-- Romeoのルート（箱根）に設定
UPDATE public.routes
SET 
  area = 'hakone',
  prefecture = '神奈川県'
WHERE user_id = '7e40bb57-cd1f-4b96-a60f-f600126ee148';
```

---

## 📱 次：アプリでテスト

1. iPhone 12 SEでWanMapを起動
2. 「公開ルート」画面を開く
3. エリアチップ、マップ、写真カードを確認

何か問題があれば教えてください！

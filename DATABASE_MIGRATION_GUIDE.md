# データベースマイグレーション手順

## 公開ルート画面改善のためのデータベース更新

### 📋 概要

公開ルート画面に以下の機能を追加するため、データベースを更新する必要があります：

1. **エリア情報**: 箱根、伊豆、那須などのエリア分類
2. **都道府県情報**: 神奈川県、静岡県などの地域情報
3. **サムネイル画像**: ルートの代表写真URL

### 🔧 マイグレーションの実行

#### 手順1: Supabase SQL Editorを開く

1. Supabase Dashboardにアクセス
2. プロジェクト `wanmap-v2` を選択
3. 左サイドバーから **SQL Editor** を選択

#### 手順2: マイグレーションSQLを実行

以下のファイルの内容をコピーして、SQL Editorに貼り付けて実行してください：

```
supabase_migrations/add_area_fields_to_routes.sql
```

または、以下のコマンドで直接実行できます（Supabase CLIインストール済みの場合）：

```bash
cd /path/to/wanmap_v2
supabase db push
```

#### 手順3: 実行結果の確認

以下のクエリで変更を確認：

```sql
-- カラムが追加されたか確認
SELECT 
  column_name, 
  data_type, 
  is_nullable
FROM information_schema.columns
WHERE table_name = 'routes'
AND column_name IN ('area', 'prefecture', 'thumbnail_url');

-- エリア別のルート数を確認
SELECT 
  area,
  prefecture,
  COUNT(*) as route_count,
  COUNT(thumbnail_url) as with_thumbnail
FROM public.routes
WHERE is_public = true
GROUP BY area, prefecture
ORDER BY route_count DESC;
```

### 📊 変更内容の詳細

#### 追加されるカラム

| カラム名 | 型 | NULL許可 | 説明 |
|---------|-----|---------|------|
| `area` | VARCHAR(50) | YES | エリアID (hakone, izu, nasu, etc.) |
| `prefecture` | VARCHAR(50) | YES | 都道府県名 (神奈川県、静岡県、etc.) |
| `thumbnail_url` | TEXT | YES | サムネイル画像URL |

#### インデックス

```sql
idx_routes_area       -- WHERE is_public = true のエリア検索用
idx_routes_prefecture -- WHERE is_public = true の都道府県検索用
```

### 🗺️ エリア定義

マイグレーションで自動的に以下のエリアが設定されます：

| エリアID | エリア名 | 都道府県 | 緯度範囲 | 経度範囲 |
|---------|---------|---------|---------|---------|
| `hakone` | 箱根 | 神奈川県 | 35.2-35.3 | 139.0-139.1 |
| `izu` | 伊豆 | 静岡県 | 34.8-35.1 | 138.8-139.2 |
| `nasu` | 那須 | 栃木県 | 37.0-37.2 | 139.9-140.1 |
| `karuizawa` | 軽井沢 | 長野県 | 36.3-36.5 | 138.5-138.7 |
| `fuji` | 富士山周辺 | 山梨県 | 35.3-35.5 | 138.6-138.9 |
| `kamakura` | 鎌倉 | 神奈川県 | 35.3-35.4 | 139.5-139.6 |

### 🔄 自動データ更新

マイグレーション実行時に以下の処理が自動実行されます：

#### 1. エリア情報の自動設定

既存ルートのGPS座標から自動的にエリアを判定し、`area`と`prefecture`を設定します。

```sql
-- 例: 箱根エリアの自動判定
UPDATE public.routes r
SET 
  area = 'hakone',
  prefecture = '神奈川県'
WHERE EXISTS (
  SELECT 1 FROM public.route_points rp
  WHERE rp.route_id = r.id
  AND rp.latitude BETWEEN 35.2 AND 35.3
  AND rp.longitude BETWEEN 139.0 AND 139.1
  LIMIT 1
)
AND area IS NULL;
```

#### 2. サムネイル画像の自動設定

`route_photos`テーブルから各ルートの最初の写真を`thumbnail_url`に設定します。

```sql
UPDATE public.routes r
SET thumbnail_url = (
  SELECT rp.storage_path
  FROM public.route_photos rp
  WHERE rp.route_id = r.id
  ORDER BY rp.display_order ASC, rp.created_at ASC
  LIMIT 1
)
WHERE thumbnail_url IS NULL;
```

### ⚠️ 注意事項

1. **既存データへの影響**
   - 既存ルートには後からエリア情報が追加されます
   - エリア範囲外のルートは`area = NULL`のまま残ります
   - 写真がないルートは`thumbnail_url = NULL`のまま残ります

2. **新規ルートの扱い**
   - アプリ側で保存時にエリアを自動判定
   - `AreaInfo.detectAreaFromCoordinate()`で自動設定
   - 写真追加時に`thumbnail_url`を自動更新

3. **パフォーマンス**
   - インデックスが追加されているため、エリア検索は高速
   - `is_public = true`の条件付きインデックスで効率的

### 🧪 テスト方法

#### 1. マイグレーション実行後のテスト

```sql
-- 公開ルートのエリア分布を確認
SELECT 
  COALESCE(area, 'unknown') as area,
  COUNT(*) as count
FROM routes
WHERE is_public = true
GROUP BY area
ORDER BY count DESC;

-- サムネイル画像の設定状況を確認
SELECT 
  COUNT(*) as total_routes,
  COUNT(thumbnail_url) as with_thumbnail,
  ROUND(COUNT(thumbnail_url) * 100.0 / COUNT(*), 2) as percentage
FROM routes
WHERE is_public = true;
```

#### 2. アプリでの動作確認

1. **公開ルート画面を開く**
   - エリア選択チップが表示される
   - マップビューに複数ルートが表示される
   - 写真付きカードが表示される

2. **エリアフィルタリング**
   - 箱根エリアを選択 → 箱根のルートのみ表示
   - 全てを選択 → 全ルート表示

3. **マップ操作**
   - ルートマーカーをタップ → 詳細画面へ遷移
   - 展開/折りたたみボタンでサイズ変更

### 🔧 トラブルシューティング

#### 問題1: カラムが追加されない

```sql
-- 手動で追加
ALTER TABLE public.routes 
ADD COLUMN IF NOT EXISTS area VARCHAR(50),
ADD COLUMN IF NOT EXISTS prefecture VARCHAR(50),
ADD COLUMN IF NOT EXISTS thumbnail_url TEXT;
```

#### 問題2: エリアが自動設定されない

```sql
-- 手動で箱根エリアを設定
UPDATE public.routes r
SET 
  area = 'hakone',
  prefecture = '神奈川県'
WHERE r.id IN (
  SELECT DISTINCT rp.route_id
  FROM public.route_points rp
  WHERE rp.latitude BETWEEN 35.2 AND 35.3
  AND rp.longitude BETWEEN 139.0 AND 139.1
)
AND area IS NULL;
```

#### 問題3: サムネイルが表示されない

Supabase Storageのアクセス設定を確認：

```sql
-- route_photosのstorage_pathが正しく設定されているか確認
SELECT 
  r.id,
  r.title,
  r.thumbnail_url,
  rp.storage_path
FROM routes r
LEFT JOIN route_photos rp ON r.id = rp.route_id
WHERE r.is_public = true
LIMIT 10;
```

### 📚 関連ドキュメント

- `PUBLIC_ROUTES_ENHANCEMENT_PROPOSAL.md` - 機能詳細
- `supabase_migrations/add_area_fields_to_routes.sql` - マイグレーションSQL
- `lib/models/area_info.dart` - エリア定義

### ✅ マイグレーション完了チェックリスト

- [ ] Supabase SQL Editorでマイグレーション実行
- [ ] カラム追加を確認（`area`, `prefecture`, `thumbnail_url`）
- [ ] インデックス作成を確認
- [ ] 既存ルートのエリア自動設定を確認
- [ ] サムネイル自動設定を確認
- [ ] アプリで公開ルート画面を確認
- [ ] エリアフィルタリング動作確認
- [ ] マップビュー動作確認
- [ ] 写真付きカード表示確認

すべてチェックが完了したら、マイグレーション完了です！🎉

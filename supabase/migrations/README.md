# Supabase Migrations

このディレクトリには、Supabaseデータベースのマイグレーションファイルが含まれています。

## マイグレーションファイル

### 20251213_create_spot_reviews.sql
**目的**: スポット評価・レビュー機能の実装

**内容**:
- `spot_reviews` テーブルの作成
- 星評価（1-5）
- 設備情報（水飲み場、ドッグラン、日陰、トイレ、駐車場など）
- レビュー写真（複数対応）
- Row Level Security (RLS) ポリシー設定

## 実行方法

### Supabase Web UIで実行する場合

1. Supabaseダッシュボードにログイン
2. 左メニューから **SQL Editor** を選択
3. **New query** をクリック
4. `20251213_create_spot_reviews.sql` の内容をコピー＆ペースト
5. **Run** ボタンをクリックして実行

### Supabase CLIで実行する場合（ローカル開発）

```bash
# Supabase CLIのインストール（未インストールの場合）
npm install -g supabase

# プロジェクトディレクトリで実行
supabase db push

# または個別に実行
supabase db execute -f supabase/migrations/20251213_create_spot_reviews.sql
```

## 確認方法

マイグレーション実行後、以下のSQLで確認できます：

```sql
-- テーブルの存在確認
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name = 'spot_reviews';

-- カラム情報の確認
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'spot_reviews'
ORDER BY ordinal_position;

-- RLSポリシーの確認
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename = 'spot_reviews';
```

## トラブルシューティング

### エラー: `relation "route_pins" does not exist`
→ `route_pins` テーブルが存在しない場合は、先にルート・ピン関連のマイグレーションを実行してください。

### エラー: `function uuid_generate_v4() does not exist`
→ UUID拡張が有効化されていません。以下を実行：
```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
```

### エラー: RLS関連
→ RLSを無効化する場合：
```sql
ALTER TABLE spot_reviews DISABLE ROW LEVEL SECURITY;
```

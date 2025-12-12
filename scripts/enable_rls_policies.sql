-- =====================================================
-- RLS (Row Level Security) ポリシーを有効化
-- =====================================================
-- 目的: Supabaseのセキュリティ警告を解消
-- 対象テーブル:
-- 1. route_pins
-- 2. route_pin_photos
-- 3. official_routes
-- 4. routes
-- 5. route_points
-- 6. route_pin_likes
-- 7. route_pin_bookmarks
-- 8. route_pin_comments

-- =====================================================
-- 1. route_pins - ピン（公開ルート上の思い出）
-- =====================================================
ALTER TABLE route_pins ENABLE ROW LEVEL SECURITY;

-- 全員が読み取り可能
CREATE POLICY "route_pins_select_policy" ON route_pins
  FOR SELECT
  USING (true);

-- ログインユーザーのみ作成可能（自分のピンのみ）
CREATE POLICY "route_pins_insert_policy" ON route_pins
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- 自分のピンのみ更新可能
CREATE POLICY "route_pins_update_policy" ON route_pins
  FOR UPDATE
  USING (auth.uid() = user_id);

-- 自分のピンのみ削除可能
CREATE POLICY "route_pins_delete_policy" ON route_pins
  FOR DELETE
  USING (auth.uid() = user_id);

-- =====================================================
-- 2. route_pin_photos - ピンの写真
-- =====================================================
ALTER TABLE route_pin_photos ENABLE ROW LEVEL SECURITY;

-- 全員が読み取り可能
CREATE POLICY "route_pin_photos_select_policy" ON route_pin_photos
  FOR SELECT
  USING (true);

-- ログインユーザーのみ作成可能（自分のピンの写真のみ）
CREATE POLICY "route_pin_photos_insert_policy" ON route_pin_photos
  FOR INSERT
  WITH CHECK (
    auth.uid() IN (
      SELECT user_id FROM route_pins WHERE id = pin_id
    )
  );

-- 自分のピンの写真のみ更新可能
CREATE POLICY "route_pin_photos_update_policy" ON route_pin_photos
  FOR UPDATE
  USING (
    auth.uid() IN (
      SELECT user_id FROM route_pins WHERE id = pin_id
    )
  );

-- 自分のピンの写真のみ削除可能
CREATE POLICY "route_pin_photos_delete_policy" ON route_pin_photos
  FOR DELETE
  USING (
    auth.uid() IN (
      SELECT user_id FROM route_pins WHERE id = pin_id
    )
  );

-- =====================================================
-- 3. official_routes - 公式ルート（箱根DMOなど）
-- =====================================================
ALTER TABLE official_routes ENABLE ROW LEVEL SECURITY;

-- 全員が読み取り可能（公開ルート）
CREATE POLICY "official_routes_select_policy" ON official_routes
  FOR SELECT
  USING (true);

-- 管理者のみ作成・更新・削除可能（今後の拡張用）
-- 現時点では誰も作成・更新・削除できない（管理画面からのみ）

-- =====================================================
-- 4. routes - ユーザー作成ルート（将来の機能用）
-- =====================================================
ALTER TABLE routes ENABLE ROW LEVEL SECURITY;

-- 公開ルートのみ全員が読み取り可能
CREATE POLICY "routes_select_policy" ON routes
  FOR SELECT
  USING (is_public = true OR auth.uid() = user_id);

-- ログインユーザーのみ作成可能（自分のルートのみ）
CREATE POLICY "routes_insert_policy" ON routes
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- 自分のルートのみ更新可能
CREATE POLICY "routes_update_policy" ON routes
  FOR UPDATE
  USING (auth.uid() = user_id);

-- 自分のルートのみ削除可能
CREATE POLICY "routes_delete_policy" ON routes
  FOR DELETE
  USING (auth.uid() = user_id);

-- =====================================================
-- 5. route_points - ルートポイント
-- =====================================================
ALTER TABLE route_points ENABLE ROW LEVEL SECURITY;

-- 全員が読み取り可能
CREATE POLICY "route_points_select_policy" ON route_points
  FOR SELECT
  USING (true);

-- ログインユーザーのみ作成可能（自分のルートのポイントのみ）
CREATE POLICY "route_points_insert_policy" ON route_points
  FOR INSERT
  WITH CHECK (
    auth.uid() IN (
      SELECT user_id FROM routes WHERE id = route_id
    )
  );

-- 自分のルートのポイントのみ更新可能
CREATE POLICY "route_points_update_policy" ON route_points
  FOR UPDATE
  USING (
    auth.uid() IN (
      SELECT user_id FROM routes WHERE id = route_id
    )
  );

-- 自分のルートのポイントのみ削除可能
CREATE POLICY "route_points_delete_policy" ON route_points
  FOR DELETE
  USING (
    auth.uid() IN (
      SELECT user_id FROM routes WHERE id = route_id
    )
  );

-- =====================================================
-- 6. route_pin_likes - ピンへのいいね
-- =====================================================
ALTER TABLE route_pin_likes ENABLE ROW LEVEL SECURITY;

-- 全員が読み取り可能
CREATE POLICY "route_pin_likes_select_policy" ON route_pin_likes
  FOR SELECT
  USING (true);

-- ログインユーザーのみいいね可能
CREATE POLICY "route_pin_likes_insert_policy" ON route_pin_likes
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- 自分のいいねのみ削除可能
CREATE POLICY "route_pin_likes_delete_policy" ON route_pin_likes
  FOR DELETE
  USING (auth.uid() = user_id);

-- =====================================================
-- 7. route_pin_bookmarks - ピンのブックマーク
-- =====================================================
ALTER TABLE route_pin_bookmarks ENABLE ROW LEVEL SECURITY;

-- 自分のブックマークのみ読み取り可能
CREATE POLICY "route_pin_bookmarks_select_policy" ON route_pin_bookmarks
  FOR SELECT
  USING (auth.uid() = user_id);

-- ログインユーザーのみブックマーク可能
CREATE POLICY "route_pin_bookmarks_insert_policy" ON route_pin_bookmarks
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- 自分のブックマークのみ削除可能
CREATE POLICY "route_pin_bookmarks_delete_policy" ON route_pin_bookmarks
  FOR DELETE
  USING (auth.uid() = user_id);

-- =====================================================
-- 8. route_pin_comments - ピンへのコメント
-- =====================================================
ALTER TABLE route_pin_comments ENABLE ROW LEVEL SECURITY;

-- 全員が読み取り可能
CREATE POLICY "route_pin_comments_select_policy" ON route_pin_comments
  FOR SELECT
  USING (true);

-- ログインユーザーのみコメント可能
CREATE POLICY "route_pin_comments_insert_policy" ON route_pin_comments
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- 自分のコメントのみ更新可能
CREATE POLICY "route_pin_comments_update_policy" ON route_pin_comments
  FOR UPDATE
  USING (auth.uid() = user_id);

-- 自分のコメントのみ削除可能
CREATE POLICY "route_pin_comments_delete_policy" ON route_pin_comments
  FOR DELETE
  USING (auth.uid() = user_id);

-- =====================================================
-- 確認クエリ: RLS有効化状態をチェック
-- =====================================================
SELECT 
  schemaname,
  tablename,
  rowsecurity AS rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN (
    'route_pins',
    'route_pin_photos',
    'official_routes',
    'routes',
    'route_points',
    'route_pin_likes',
    'route_pin_bookmarks',
    'route_pin_comments'
  )
ORDER BY tablename;

-- 完了メッセージ
SELECT '✅ 8つのテーブルにRLSポリシーを設定しました' AS status;

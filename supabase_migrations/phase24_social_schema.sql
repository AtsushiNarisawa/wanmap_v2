-- Phase 24: Social Features - Database Schema
-- Tables: follows, likes

-- ============================================================
-- follows テーブル (フォロー/フォロワー関係)
-- ============================================================
CREATE TABLE IF NOT EXISTS follows (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  follower_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  following_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- 同じユーザーを複数回フォローできないようにする
  UNIQUE(follower_id, following_id),
  
  -- 自分自身をフォローできないようにする
  CONSTRAINT no_self_follow CHECK (follower_id != following_id)
);

-- インデックス作成
CREATE INDEX IF NOT EXISTS idx_follows_follower_id ON follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_following_id ON follows(following_id);
CREATE INDEX IF NOT EXISTS idx_follows_created_at ON follows(created_at DESC);

-- RLS (Row Level Security) ポリシー設定
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;

-- 誰でも読み取り可能
CREATE POLICY "Anyone can view follows"
  ON follows FOR SELECT
  USING (true);

-- 自分のフォローは作成可能
CREATE POLICY "Users can create their own follows"
  ON follows FOR INSERT
  WITH CHECK (auth.uid() = follower_id);

-- 自分のフォローは削除可能
CREATE POLICY "Users can delete their own follows"
  ON follows FOR DELETE
  USING (auth.uid() = follower_id);

-- ============================================================
-- likes テーブル (ルートへのいいね)
-- ============================================================
CREATE TABLE IF NOT EXISTS likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  route_id UUID NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- 同じルートに同じユーザーが複数回いいねできないようにする
  UNIQUE(user_id, route_id)
);

-- インデックス作成
CREATE INDEX IF NOT EXISTS idx_likes_user_id ON likes(user_id);
CREATE INDEX IF NOT EXISTS idx_likes_route_id ON likes(route_id);
CREATE INDEX IF NOT EXISTS idx_likes_created_at ON likes(created_at DESC);

-- RLS (Row Level Security) ポリシー設定
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;

-- 誰でも読み取り可能
CREATE POLICY "Anyone can view likes"
  ON likes FOR SELECT
  USING (true);

-- 認証済みユーザーは自分のいいねを作成可能
CREATE POLICY "Authenticated users can create likes"
  ON likes FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- 自分のいいねは削除可能
CREATE POLICY "Users can delete their own likes"
  ON likes FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================
-- ビュー: フォロー統計
-- ============================================================
CREATE OR REPLACE VIEW follow_stats AS
SELECT 
  u.id as user_id,
  COUNT(DISTINCT f1.id) as follower_count,
  COUNT(DISTINCT f2.id) as following_count
FROM auth.users u
LEFT JOIN follows f1 ON f1.following_id = u.id
LEFT JOIN follows f2 ON f2.follower_id = u.id
GROUP BY u.id;

-- ============================================================
-- ビュー: ルートのいいね数
-- ============================================================
CREATE OR REPLACE VIEW route_like_counts AS
SELECT 
  r.id as route_id,
  COUNT(l.id) as like_count
FROM routes r
LEFT JOIN likes l ON l.route_id = r.id
GROUP BY r.id;

-- ============================================================
-- 関数: ユーザーがフォローしているかチェック
-- ============================================================
CREATE OR REPLACE FUNCTION is_following(
  follower_user_id UUID,
  following_user_id UUID
)
RETURNS BOOLEAN AS $$
  SELECT EXISTS(
    SELECT 1 FROM follows
    WHERE follower_id = follower_user_id
      AND following_id = following_user_id
  );
$$ LANGUAGE sql STABLE;

-- ============================================================
-- 関数: ユーザーがルートにいいねしているかチェック
-- ============================================================
CREATE OR REPLACE FUNCTION has_liked_route(
  check_user_id UUID,
  check_route_id UUID
)
RETURNS BOOLEAN AS $$
  SELECT EXISTS(
    SELECT 1 FROM likes
    WHERE user_id = check_user_id
      AND route_id = check_route_id
  );
$$ LANGUAGE sql STABLE;

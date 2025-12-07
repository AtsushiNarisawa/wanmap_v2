-- ========================================
-- Phase 3.5 - Step 2: コメント返信機能の追加
-- ========================================

-- 1. route_pin_commentsテーブルに返信先カラムを追加
ALTER TABLE route_pin_comments 
ADD COLUMN IF NOT EXISTS reply_to_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL;

ALTER TABLE route_pin_comments 
ADD COLUMN IF NOT EXISTS reply_to_user_name TEXT;

-- インデックス追加（パフォーマンス向上）
CREATE INDEX IF NOT EXISTS idx_pin_comments_reply_to_user_id ON route_pin_comments(reply_to_user_id);

-- 2. add_pin_comment RPC関数の更新（返信先パラメータ追加）
DROP FUNCTION IF EXISTS add_pin_comment(UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS add_pin_comment(UUID, UUID, TEXT, UUID, TEXT);

CREATE FUNCTION add_pin_comment(
  p_pin_id UUID,
  p_user_id UUID,
  p_comment TEXT,
  p_reply_to_user_id UUID DEFAULT NULL,
  p_reply_to_user_name TEXT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
  v_comment_id UUID;
  v_result JSON;
BEGIN
  -- 空コメントチェック
  IF p_comment IS NULL OR TRIM(p_comment) = '' THEN
    v_result := json_build_object(
      'success', false,
      'message', 'Comment cannot be empty'
    );
    RETURN v_result;
  END IF;

  -- コメント追加（返信先情報を含む）
  INSERT INTO route_pin_comments (
    pin_id, 
    user_id, 
    comment,
    reply_to_user_id,
    reply_to_user_name
  )
  VALUES (
    p_pin_id, 
    p_user_id, 
    p_comment,
    p_reply_to_user_id,
    p_reply_to_user_name
  )
  RETURNING id INTO v_comment_id;

  v_result := json_build_object(
    'success', true,
    'comment_id', v_comment_id,
    'message', 'Comment added successfully'
  );
  RETURN v_result;
EXCEPTION
  WHEN OTHERS THEN
    v_result := json_build_object(
      'success', false,
      'message', SQLERRM
    );
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. get_pin_comments RPC関数の更新（返信先情報を返す）
DROP FUNCTION IF EXISTS get_pin_comments(UUID, INTEGER, INTEGER);

CREATE FUNCTION get_pin_comments(
  p_pin_id UUID,
  p_limit INTEGER DEFAULT 50,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  comment_id UUID,
  user_id UUID,
  user_name TEXT,
  user_avatar TEXT,
  comment TEXT,
  created_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE,
  reply_to_user_id UUID,
  reply_to_user_name TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    c.id AS comment_id,
    c.user_id,
    COALESCE(prof.display_name, u.email) AS user_name,
    prof.avatar_url AS user_avatar,
    c.comment,
    c.created_at,
    c.updated_at,
    c.reply_to_user_id,
    c.reply_to_user_name
  FROM route_pin_comments c
  JOIN auth.users u ON c.user_id = u.id
  LEFT JOIN profiles prof ON c.user_id = prof.id
  WHERE c.pin_id = p_pin_id
  ORDER BY c.created_at DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- 実行完了メッセージ
-- ========================================
DO $$
BEGIN
  RAISE NOTICE '✅ Phase 3.5 - Step 2: 返信機能のデータベース実装が完了しました';
  RAISE NOTICE '📊 追加カラム: reply_to_user_id, reply_to_user_name';
  RAISE NOTICE '🔧 更新RPC関数: add_pin_comment (返信先パラメータ追加)';
  RAISE NOTICE '🔧 更新RPC関数: get_pin_comments (返信先情報を返す)';
END $$;

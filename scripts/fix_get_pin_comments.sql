-- ========================================
-- get_pin_comments RPC関数の修正
-- エラー修正: profiles.user_id → profiles.id (主キー)
-- ========================================

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
  updated_at TIMESTAMP WITH TIME ZONE
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
    c.updated_at
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
  RAISE NOTICE 'get_pin_comments関数を修正しました';
  RAISE NOTICE '修正内容: LEFT JOIN profiles prof ON c.user_id = prof.id';
END $$;

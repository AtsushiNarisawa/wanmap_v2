-- ===============================================
-- Supabase認証設定の確認
-- ===============================================
-- このSQLをSupabase Dashboard → SQL Editorで実行してください
--
-- 確認項目:
-- 1. パスワードが正しく設定されているか
-- 2. メールアドレス確認が完了しているか
-- 3. トークンが正常か
-- 4. アカウントがロックされていないか
-- ===============================================

-- test1@example.comの詳細な認証情報を確認
SELECT 
  id,
  email,
  encrypted_password IS NOT NULL as has_password,
  LENGTH(encrypted_password) as password_length,
  email_confirmed_at IS NOT NULL as email_confirmed,
  email_confirmed_at,
  confirmation_token IS NOT NULL as has_confirmation_token,
  recovery_token IS NOT NULL as has_recovery_token,
  email_change_token_current IS NOT NULL as has_email_change_token,
  banned_until,
  deleted_at,
  last_sign_in_at,
  created_at,
  updated_at
FROM auth.users
WHERE email = 'test1@example.com';

-- すべてのauth.usersの状態を確認
SELECT 
  email,
  encrypted_password IS NOT NULL as has_password,
  email_confirmed_at IS NOT NULL as email_confirmed,
  banned_until IS NOT NULL as is_banned,
  deleted_at IS NOT NULL as is_deleted,
  last_sign_in_at
FROM auth.users
WHERE email LIKE 'test%@example.com'
ORDER BY email;

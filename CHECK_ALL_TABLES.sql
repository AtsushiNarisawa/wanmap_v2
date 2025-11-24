-- データベース内の全テーブル一覧を確認
SELECT 
    tablename
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;

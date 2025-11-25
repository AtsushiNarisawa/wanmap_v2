# ログイン問題のトラブルシューティング

## 🔴 現在の問題

- **症状**: `Invalid login credentials` エラー（statusCode: 400）
- **アカウント**: test1@example.com は存在し、正常な状態
- **コード**: AuthService、SupabaseConfig、.envファイルすべて正しい
- **前提**: 以前（2025-11-24 10:07）はログイン成功していた

## 🔍 原因の可能性

### 1. Supabaseのメール確認ポリシー

Supabase Dashboard → Authentication → Settings で以下を確認：

#### ✅ 確認項目:
- **Enable email confirmations**: OFFになっているか？
- **Confirm email**: Disabledになっているか？

#### 🔧 修正方法:
1. Supabase Dashboard → **Authentication** → **Settings**
2. **Email** セクションを展開
3. **Enable email confirmations** を **OFF** にする
4. **Save** をクリック

### 2. パスワードポリシーの変更

Supabase Dashboard → Authentication → Settings で以下を確認：

#### ✅ 確認項目:
- **Minimum password length**: 6以上になっているか？
- **Password requirements**: 複雑すぎる要件になっていないか？

### 3. レート制限（Rate Limiting）

短時間に何度もログイン試行すると、一時的にブロックされる可能性があります。

#### 🔧 修正方法:
- 5分待ってから再度ログイン試行
- Supabase Dashboard → Authentication → Rate Limits で確認

### 4. Supabaseプロジェクトの一時的な問題

Supabaseのサービスステータスを確認：
- https://status.supabase.com/

## 🎯 推奨される解決手順

### ステップ1: Supabase Authentication設定を確認

1. Supabase Dashboard → **Authentication** → **Settings**
2. **Email** セクション:
   - ☑️ **Enable email confirmations**: **OFF**
   - ☑️ **Confirm email**: **Disabled**
3. **Save** をクリック

### ステップ2: test1@example.comのパスワードをリセット

1. Supabase Dashboard → **Authentication** → **Users**
2. **test1@example.com** をクリック
3. 右上の **"..."** → **"Update user"**
4. 新しいパスワード: `test1234`
5. ☑️ **Auto Confirm User** にチェック
6. **Update user** をクリック

### ステップ3: アプリで再ログイン

```bash
cd /Users/atsushinarisawa/projects/webapp/wanmap_v2
flutter clean
flutter pub get
flutter run
```

ログイン画面で：
- Email: `test1@example.com`
- Password: `test1234`

### ステップ4: それでもダメな場合

ユーザーを削除して再作成：

1. Supabase Dashboard → **Authentication** → **Users**
2. test1@example.com を **Delete user**
3. **Add user** をクリック
   - Email: `test1@example.com`
   - Password: `test1234`
   - ☑️ **Auto Confirm User**
4. **Create user** をクリック

## 📝 デバッグ情報の収集

もし上記で解決しない場合、以下の情報を収集：

### Supabase側:
```sql
-- check_auth_settings.sqlを実行
SELECT 
  id,
  email,
  encrypted_password IS NOT NULL as has_password,
  email_confirmed_at,
  confirmation_token IS NOT NULL as has_confirmation_token,
  banned_until,
  deleted_at
FROM auth.users
WHERE email = 'test1@example.com';
```

### Flutter側:
- ターミナルの完全なログ
- `flutter doctor -v` の出力
- Supabase Flutterパッケージのバージョン確認

## 🔗 関連リンク

- [Supabase Authentication Docs](https://supabase.com/docs/guides/auth)
- [Supabase Status Page](https://status.supabase.com/)
- [Flutter Supabase Package](https://pub.dev/packages/supabase_flutter)

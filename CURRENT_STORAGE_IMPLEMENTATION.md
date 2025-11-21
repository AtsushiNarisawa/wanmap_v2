# WanMap ストレージ実装の現状

## 📅 調査日時
2025年11月21日

---

## 📁 ストレージサービスの実装状況

### ❌ 専用ストレージサービスは存在しない

現在、`storage_service.dart` という専用のストレージサービスファイルは**存在しません**。

代わりに、以下の2つのサービスが**Supabase Storageを直接使用**してストレージ機能を実装しています：

1. **photo_service.dart** - ルート写真のアップロード・管理
2. **profile_service.dart** - プロフィールアバター画像の管理

---

## 🗂️ 現在のストレージ実装

### 1. PhotoService (lib/services/photo_service.dart)

#### 使用ストレージ
- **Supabase Storage**
- バケット名: `route-photos`

#### 実装されている機能

**画像選択・撮影:**
```dart
Future<File?> pickImageFromGallery()  // ギャラリーから選択
Future<File?> takePhoto()              // カメラで撮影
```

**アップロード:**
```dart
Future<String?> uploadPhoto({
  required File file,
  required String routeId,
  required String userId,
}) async {
  final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
  final filePath = '$userId/$routeId/$fileName';

  // Supabase Storageにアップロード
  await _supabase.storage
      .from('route-photos')
      .upload(filePath, file);

  // route_photosテーブルに記録
  await _supabase.from('route_photos').insert({
    'route_id': routeId,
    'user_id': userId,
    'storage_path': filePath,
  });

  return filePath;
}
```

**写真取得:**
```dart
Future<List<RoutePhoto>> getRoutePhotos(String routeId) async {
  // route_photosテーブルから取得
  final response = await _supabase
      .from('route_photos')
      .select()
      .eq('route_id', routeId)
      .order('display_order', ascending: true);

  // 公開URLを生成
  final publicUrl = _supabase.storage
      .from('route-photos')
      .getPublicUrl(storagePath);
}
```

**削除:**
```dart
Future<bool> deletePhoto({
  required String photoId,
  required String storagePath,
  required String userId,
}) async {
  // Storageから削除
  await _supabase.storage
      .from('route-photos')
      .remove([storagePath]);

  // データベースから削除
  await _supabase
      .from('route_photos')
      .delete()
      .eq('id', photoId)
      .eq('user_id', userId);
}
```

#### ストレージパス構造
```
route-photos/
  └── {userId}/
      └── {routeId}/
          └── {timestamp}.jpg
```

#### データベーステーブル
```sql
route_photos:
  - id (UUID)
  - route_id (UUID)
  - user_id (UUID)
  - storage_path (TEXT)
  - caption (TEXT, nullable)
  - display_order (INTEGER)
  - created_at (TIMESTAMP)
```

---

### 2. ProfileService (lib/services/profile_service.dart)

#### 使用ストレージ
- **Supabase Storage**
- バケット名: `profile-avatars`

#### 実装されている機能

**アバターアップロード:**
```dart
Future<String?> uploadAvatar({
  required File file,
  required String userId,
}) async {
  final fileExt = file.path.split('.').last;
  final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
  final filePath = 'avatars/$fileName';

  // Supabase Storageにアップロード
  await _supabase.storage
      .from('profile-avatars')
      .upload(filePath, file);

  // 公開URLを取得
  final publicUrl = _supabase.storage
      .from('profile-avatars')
      .getPublicUrl(filePath);

  return publicUrl;
}
```

**アバター削除:**
```dart
Future<bool> deleteAvatar(String storagePath) async {
  await _supabase.storage
      .from('profile-avatars')
      .remove([storagePath]);
}
```

#### ストレージパス構造
```
profile-avatars/
  └── avatars/
      └── {userId}-{timestamp}.{ext}
```

---

## ⚙️ 環境設定

### lib/config/env.dart

#### Supabase設定（✅ 実装済み）
```dart
class Environment {
  // Supabase設定
  static const String supabaseUrl = 'https://jkpenklhrlbctebkpvax.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGci...';
}
```

#### Cloudflare R2設定（❌ 未実装）
```dart
// Cloudflare R2設定（画像ストレージ）
// TODO: 実際のR2認証情報に置き換えてください
static const String r2AccountId = 'your-r2-account-id';
static const String r2AccessKeyId = 'your-r2-access-key-id';
static const String r2SecretAccessKey = 'your-r2-secret-access-key';
static const String r2BucketName = 'wanmap-photos';
static const String r2PublicUrl = 'https://your-bucket.r2.dev';
```

**状態:** 定義されているが、プレースホルダー値のみ。実際の値は未設定。

---

## 📦 pubspec.yaml - ストレージ関連依存関係

### 現在の依存関係

#### ✅ 実装済み（Supabase Storage用）
```yaml
dependencies:
  # Supabase（Storageを含む）
  supabase_flutter: ^2.0.0
  
  # 画像処理
  image_picker: ^1.2.1  # カメラ・ギャラリーから画像選択
  image: ^4.1.3         # 画像の圧縮・リサイズ
  
  # HTTP・ネットワーク
  http: ^1.1.0
  dio: ^5.4.0
  
  # キャッシュ
  cached_network_image: ^3.3.0  # ネットワーク画像のキャッシュ
```

#### ❌ Cloudflare R2用の依存関係は存在しない

現在、以下のような**Cloudflare R2専用のパッケージは追加されていません**：

- `aws_s3_upload` (S3互換APIクライアント)
- `minio` (S3互換ストレージクライアント)
- `amazon_s3_cognito` 
- など

---

## 🔍 .env ファイル

### ファイル存在確認結果
```bash
❌ .env ファイルは存在しません
❌ .env.example ファイルも存在しません
❌ .env.local ファイルも存在しません
```

**現状:** 環境変数は `lib/config/env.dart` にハードコーディングされています。

---

## 📊 ストレージ実装の統計

### ファイル数
- **専用ストレージサービス:** 0個
- **Supabase Storageを使用するサービス:** 2個
  - photo_service.dart
  - profile_service.dart

### Supabase Storageバケット
- `route-photos` (ルート写真用)
- `profile-avatars` (アバター画像用)

### データベーステーブル
- `route_photos` (写真メタデータ)
- `profiles` (プロフィール情報、avatar_url含む)

---

## 🔄 現在のストレージアーキテクチャ

```
┌─────────────────────────────────────────────────────┐
│                   WanMapアプリ                       │
└─────────────────────────────────────────────────────┘
                         │
                         ▼
         ┌───────────────────────────────┐
         │   Supabase Flutter SDK        │
         └───────────────────────────────┘
                         │
         ┌───────────────┴────────────────┐
         ▼                                ▼
┌──────────────────┐           ┌──────────────────┐
│ Supabase Storage │           │ Supabase Database│
│                  │           │                  │
│ • route-photos   │           │ • route_photos   │
│ • profile-avatars│           │ • profiles       │
└──────────────────┘           └──────────────────┘

【凡例】
✅ 実装済み: Supabase Storage
❌ 未実装: Cloudflare R2
```

---

## ⚠️ Cloudflare R2 実装状況

### 現状: 未実装

1. **環境変数**: プレースホルダーのみ定義
2. **依存関係**: R2/S3クライアントパッケージなし
3. **サービスクラス**: R2専用サービスなし
4. **実装コード**: Supabase Storageのみ使用

### もしCloudflare R2に移行する場合

#### 必要な作業

1. **パッケージ追加**
   ```yaml
   dependencies:
     aws_s3_upload: ^3.0.0  # S3互換APIクライアント
     # または
     minio: ^3.0.0          # MinIOクライアント（S3互換）
   ```

2. **環境変数設定**
   ```dart
   // lib/config/env.dart
   static const String r2AccountId = '実際のアカウントID';
   static const String r2AccessKeyId = '実際のアクセスキー';
   static const String r2SecretAccessKey = '実際のシークレット';
   static const String r2BucketName = 'wanmap-photos';
   static const String r2PublicUrl = 'https://実際のバケット.r2.dev';
   ```

3. **storage_service.dart 作成**
   ```dart
   import 'package:aws_s3_upload/aws_s3_upload.dart';
   import '../config/env.dart';

   class StorageService {
     late AwsS3 _s3Client;

     StorageService() {
       _s3Client = AwsS3(
         accessKey: Environment.r2AccessKeyId,
         secretKey: Environment.r2SecretAccessKey,
         bucket: Environment.r2BucketName,
         region: 'auto',
         endpoint: 'https://${Environment.r2AccountId}.r2.cloudflarestorage.com',
       );
     }

     Future<String?> uploadFile(File file, String path) async {
       final result = await _s3Client.uploadFile(
         file: file,
         destPath: path,
         contentType: 'image/jpeg',
       );
       return '${Environment.r2PublicUrl}/$path';
     }

     Future<bool> deleteFile(String path) async {
       await _s3Client.deleteFile(path);
       return true;
     }
   }
   ```

4. **既存サービスの移行**
   - `photo_service.dart` を修正してStorageServiceを使用
   - `profile_service.dart` を修正してStorageServiceを使用

---

## 📋 推奨事項

### 短期的（現在のSupabase Storageを継続）

1. ✅ **現状維持**: Supabase Storageは十分機能している
2. ✅ **セキュリティ**: RLS（Row Level Security）が適用されている
3. ✅ **パフォーマンス**: グローバルCDN経由で配信

### 中長期的（必要に応じてCloudflare R2移行）

#### R2移行のメリット
- ✅ コスト削減（エグレス料金無料）
- ✅ Cloudflare CDNとの統合
- ✅ 大量の画像配信に有利

#### R2移行のデメリット
- ❌ 追加の実装工数
- ❌ S3互換APIクライアントの追加
- ❌ 認証管理の複雑化

#### 判断基準
- **月間転送量 < 100GB**: Supabase Storage継続推奨
- **月間転送量 > 100GB**: Cloudflare R2移行検討
- **写真枚数 < 10,000枚**: Supabase Storage十分
- **写真枚数 > 10,000枚**: R2移行のコスト効果あり

---

## 🎯 次のアクションアイテム

### 即座に対応が必要（必須）
- [ ] なし（現在のSupabase Storageで十分機能している）

### 検討が必要（推奨）
- [ ] `.env` ファイルの作成と`.gitignore`への追加
- [ ] 環境変数の外部化（ハードコーディング回避）
- [ ] ストレージ使用量のモニタリング

### 将来的に検討（オプション）
- [ ] Cloudflare R2への移行判断（トラフィック次第）
- [ ] 専用 `storage_service.dart` の作成（抽象化レイヤー）
- [ ] 画像最適化パイプラインの構築

---

## 📖 関連ドキュメント

- **RELEASE_READINESS_REPORT.md** - リリース準備状況
- **PHASE2_IMPLEMENTATION_SUMMARY.md** - Phase 2実装詳細
- **APP_ICON_IMPLEMENTATION.md** - アプリアイコン実装

---

## 📞 サポート情報

### Supabase Storage設定
- ダッシュボード: https://supabase.com/dashboard/project/jkpenklhrlbctebkpvax/storage
- バケット設定: Storage → Buckets
- RLSポリシー: Storage → Policies

### Cloudflare R2（将来的に必要な場合）
- ダッシュボード: https://dash.cloudflare.com
- R2コンソール: R2 → Overview
- バケット作成: R2 → Create bucket

---

**最終更新:** 2025年11月21日  
**調査者:** Claude AI Assistant  
**ステータス:** ✅ 現状確認完了

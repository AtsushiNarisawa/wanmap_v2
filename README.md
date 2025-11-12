# WanMap - 愛犬の散歩ルート共有モバイルアプリ

![WanMap Logo](https://img.shields.io/badge/Flutter-3.0+-blue.svg)
![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20Android%20%7C%20Web-lightgrey.svg)

## 📱 プロジェクト概要

**WanMap**は、愛犬家のための散歩ルート共有モバイルアプリケーションです。

### 🎯 主な機能

- 📍 **GPS追跡**: 散歩ルートをリアルタイムで記録
- 🗺️ **マップ表示**: OpenStreetMapベースの地図で散歩ルートを可視化
- 📸 **写真共有**: 散歩中の思い出の写真をルートに紐付けて保存
- 🐕 **愛犬プロフィール**: 複数の愛犬を登録・管理
- 🌟 **お気に入り**: 他のユーザーのルートを保存
- 💬 **コメント**: ルートに対してコメントを投稿
- 📅 **散歩プラン**: 友達と一緒の散歩を計画

## 🏗️ 技術スタック

### フロントエンド
- **Framework**: Flutter 3.0+
- **Language**: Dart
- **State Management**: Riverpod 2.4+
- **Routing**: Go Router 12.0+

### バックエンド
- **Database**: Supabase (PostgreSQL)
- **Authentication**: Supabase Auth
- **Storage**: Cloudflare R2 (画像保存)

### 地図・位置情報
- **Map**: flutter_map 6.0+ (OpenStreetMap)
- **GPS**: geolocator 10.1+
- **Permissions**: permission_handler 11.0+

## 📂 プロジェクト構造

```
wanmap_v2/
├── lib/                    # Dartコードのメインディレクトリ
│   ├── main.dart          # エントリーポイント
│   ├── config/            # 設定ファイル
│   │   ├── env.dart       # 環境変数
│   │   └── supabase_config.dart  # Supabase設定
│   ├── models/            # データモデル
│   │   ├── user_model.dart
│   │   ├── dog_model.dart
│   │   ├── route_model.dart
│   │   └── trip_plan_model.dart
│   ├── services/          # ビジネスロジック
│   │   ├── auth_service.dart
│   │   ├── database_service.dart
│   │   ├── gps_service.dart
│   │   └── storage_service.dart
│   ├── providers/         # Riverpod Provider
│   │   └── auth_provider.dart
│   ├── screens/           # 画面
│   │   ├── auth/          # 認証関連画面
│   │   ├── home/          # ホーム画面
│   │   ├── map/           # マップ画面
│   │   └── profile/       # プロフィール画面
│   └── widgets/           # 共通ウィジェット
│       └── common/
├── android/               # Androidアプリ設定
├── ios/                   # iOSアプリ設定
├── web/                   # PWA設定
├── assets/                # 画像・アイコン
│   ├── images/
│   └── icons/
├── test/                  # テストコード
├── pubspec.yaml          # Flutterの依存関係管理
└── README.md             # このファイル
```

## 🚀 セットアップ手順

### 前提条件

- Flutter SDK 3.0以上がインストールされていること
- iOS開発の場合: Xcode（macOSのみ）
- Android開発の場合: Android Studio

### 1. リポジトリのクローン

```bash
git clone <repository-url>
cd wanmap_v2
```

### 2. 依存関係のインストール

```bash
flutter pub get
```

### 3. 環境変数の設定

`lib/config/env.dart`を編集し、実際の認証情報を設定してください：

```dart
class Environment {
  // Supabase設定
  static const String supabaseUrl = 'https://your-project.supabase.co';
  static const String supabaseAnonKey = 'your-supabase-anon-key';
  
  // Cloudflare R2設定
  static const String r2AccountId = 'your-r2-account-id';
  static const String r2AccessKeyId = 'your-r2-access-key-id';
  static const String r2SecretAccessKey = 'your-r2-secret-access-key';
  static const String r2BucketName = 'wanmap-photos';
  static const String r2PublicUrl = 'https://your-bucket.r2.dev';
}
```

**⚠️ 重要**: 本番環境では、これらの値を`env_prod.dart`に分離し、`.gitignore`に追加してください。

### 4. Supabaseプロジェクトのセットアップ

#### データベーススキーマ

Supabaseのダッシュボードで以下のテーブルを作成してください：

```sql
-- Users テーブル
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  username TEXT UNIQUE NOT NULL,
  display_name TEXT,
  avatar_url TEXT,
  bio TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Dogs テーブル
CREATE TABLE dogs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  breed TEXT,
  age INTEGER,
  photo_url TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Routes テーブル
CREATE TABLE routes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  dog_id UUID REFERENCES dogs(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  description TEXT,
  distance FLOAT,
  duration INTEGER,
  difficulty TEXT,
  is_public BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Route Points テーブル
CREATE TABLE route_points (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  route_id UUID REFERENCES routes(id) ON DELETE CASCADE,
  latitude FLOAT NOT NULL,
  longitude FLOAT NOT NULL,
  altitude FLOAT,
  timestamp TIMESTAMP DEFAULT NOW(),
  sequence_number INTEGER
);

-- Photos テーブル
CREATE TABLE photos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  route_id UUID REFERENCES routes(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  photo_url TEXT NOT NULL,
  caption TEXT,
  latitude FLOAT,
  longitude FLOAT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Favorites テーブル
CREATE TABLE favorites (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  route_id UUID REFERENCES routes(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, route_id)
);

-- Comments テーブル
CREATE TABLE comments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  route_id UUID REFERENCES routes(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Trip Plans テーブル
CREATE TABLE trip_plans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  creator_id UUID REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  scheduled_date TIMESTAMP,
  meeting_point_lat FLOAT,
  meeting_point_lng FLOAT,
  created_at TIMESTAMP DEFAULT NOW()
);
```

#### ストレージバケットの作成

Supabaseのダッシュボードで以下のバケットを作成してください：

- `dog-photos` (Public)
- `route-photos` (Public)
- `user-avatars` (Public)

### 5. アプリの実行

```bash
# iOS シミュレータで実行
flutter run -d ios

# Android エミュレータで実行
flutter run -d android

# Webで実行
flutter run -d chrome
```

## 📱 開発ロードマップ

### Phase 1: 基礎構築 ✅
- [x] プロジェクト構造の作成
- [x] Supabase設定
- [x] スプラッシュ画面

### Phase 2: 認証機能 🚧
- [ ] ログイン画面
- [ ] サインアップ画面
- [ ] パスワードリセット
- [ ] プロフィール編集

### Phase 3: 地図・GPS機能
- [ ] マップ表示
- [ ] GPS追跡
- [ ] ルート記録
- [ ] ルート保存

### Phase 4: ソーシャル機能
- [ ] ルート一覧
- [ ] ルート詳細
- [ ] お気に入り
- [ ] コメント

### Phase 5: 写真機能
- [ ] 写真撮影
- [ ] 写真アップロード
- [ ] 写真表示

## 🔧 トラブルシューティング

### Flutterの依存関係エラー

```bash
flutter clean
flutter pub get
```

### iOSビルドエラー

```bash
cd ios
pod install
cd ..
flutter run
```

### Android権限エラー

`android/app/src/main/AndroidManifest.xml`に以下を追加：

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

## 📄 ライセンス

このプロジェクトはMITライセンスの下で公開されています。

## 👥 コントリビューション

プルリクエストは大歓迎です！

## 📞 お問い合わせ

質問や提案がある場合は、Issueを作成してください。

---

Made with ❤️ by WanMap Team

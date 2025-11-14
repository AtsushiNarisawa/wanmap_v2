# Phase 27: エラーハンドリング強化 - 実装ガイド

## 🎯 実装の目的

- ユーザーフレンドリーなエラーメッセージ表示
- 自動リトライ機能
- エラーログの記録
- ネットワークエラーの適切なハンドリング

## 📦 新規作成されたファイル

1. `lib/models/app_exception.dart` - カスタム例外クラス
2. `lib/services/error_handler_service.dart` - エラーハンドリングサービス
3. `lib/widgets/error_dialog.dart` - エラー表示UI
4. `lib/widgets/retryable_async_widget.dart` - リトライ機能付きウィジェット

## 🔧 既存コードの更新方法

### 1. サービスクラスのエラーハンドリング

**Before:**
```dart
Future<RouteModel> createRoute(RouteModel route) async {
  try {
    final response = await supabase.from('routes').insert(route.toJson());
    return RouteModel.fromJson(response);
  } catch (e) {
    print('Error: $e');
    rethrow;
  }
}
```

**After:**
```dart
import '../models/app_exception.dart';
import '../services/error_handler_service.dart';

Future<RouteModel> createRoute(RouteModel route) async {
  try {
    final response = await supabase.from('routes').insert(route.toJson());
    return RouteModel.fromJson(response);
  } catch (e, stackTrace) {
    final exception = ErrorHandlerService.handleSupabaseError(e, stackTrace);
    ErrorHandlerService.logError(exception);
    throw exception;
  }
}
```

### 2. UI でのエラー表示

**方法1: エラーダイアログ**
```dart
try {
  await routeService.createRoute(route);
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ルートを保存しました')),
    );
  }
} catch (e) {
  if (mounted) {
    ErrorDialog.show(
      context,
      error: e,
      onRetry: () => _saveRoute(), // リトライ関数
    );
  }
}
```

**方法2: エラースナックバー**
```dart
try {
  await routeService.createRoute(route);
} catch (e) {
  if (mounted) {
    ErrorSnackBar.show(
      context,
      error: e,
      onRetry: () => _saveRoute(),
    );
  }
}
```

### 3. FutureBuilder を RetryableAsyncWidget に置き換え

**Before:**
```dart
FutureBuilder<List<RouteModel>>(
  future: routeService.fetchRoutes(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const CircularProgressIndicator();
    }
    if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    }
    return ListView(children: ...);
  },
)
```

**After:**
```dart
RetryableAsyncWidget<List<RouteModel>>(
  futureBuilder: () => routeService.fetchRoutes(),
  builder: (context, routes) {
    return ListView(
      children: routes.map((route) => RouteCard(route: route)).toList(),
    );
  },
  maxRetries: 3, // 最大3回まで自動リトライ
)
```

### 4. バリデーションエラーの投げ方

```dart
import '../models/app_exception.dart';

void validateRouteData(RouteModel route) {
  if (route.title.isEmpty) {
    throw ValidationException(
      message: 'ルート名を入力してください',
    );
  }
  
  if (route.distance < 0) {
    throw ValidationException(
      message: '距離は0以上である必要があります',
    );
  }
}
```

## 🎨 エラーハンドリングのベストプラクティス

### 1. try-catch は必ず使う

```dart
// ❌ Bad
Future<void> saveRoute() async {
  await routeService.createRoute(route);
}

// ✅ Good
Future<void> saveRoute() async {
  try {
    await routeService.createRoute(route);
  } catch (e) {
    ErrorSnackBar.show(context, error: e);
  }
}
```

### 2. エラーは適切に変換する

```dart
// ❌ Bad - 生のエラーをそのまま投げる
throw Exception('Failed to save');

// ✅ Good - アプリケーション例外に変換
throw DatabaseException(
  message: 'Failed to save route',
  code: 'SAVE_FAILED',
);
```

### 3. ユーザーにはわかりやすいメッセージを

```dart
// ❌ Bad
'PostgrestException: 23505 duplicate key value'

// ✅ Good
'このルート名は既に使用されています'
```

### 4. ネットワークエラーは自動リトライ

```dart
RetryableAsyncWidget(
  futureBuilder: () => fetchData(),
  maxRetries: 3, // ネットワークエラーなら3回リトライ
  builder: (context, data) => DataView(data: data),
)
```

## ✅ 更新が必要な主要ファイル

- [ ] `lib/services/route_service.dart` - エラーハンドリング追加
- [ ] `lib/services/auth_service.dart` - エラーハンドリング追加
- [ ] `lib/services/profile_service.dart` - エラーハンドリング追加
- [ ] `lib/screens/recording/recording_screen.dart` - エラーUI追加
- [ ] `lib/screens/routes/routes_screen.dart` - RetryableAsyncWidget適用
- [ ] `lib/screens/profile/profile_screen.dart` - エラーハンドリング追加

## 🧪 テスト項目

- [ ] ネットワークエラー時のリトライ動作
- [ ] データベースエラー時のメッセージ表示
- [ ] バリデーションエラーの適切な表示
- [ ] 権限エラーの設定画面誘導
- [ ] オフライン時の適切なメッセージ

## 📊 期待される改善

- **ユーザー体験**: エラーが発生しても次のアクションが明確
- **デバッグ効率**: エラーログから問題を特定しやすい
- **アプリ安定性**: 予期しないクラッシュの防止
- **リカバリー**: 自動リトライで一時的なエラーを回復
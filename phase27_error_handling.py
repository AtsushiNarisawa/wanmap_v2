#!/usr/bin/env python3
"""
Phase 27: Error Handling Enhancement
包括的なエラーハンドリングの自動実装スクリプト
"""

import os

PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))

def create_app_exception_class():
    """アプリケーション固有の例外クラスを作成"""
    content = '''/// アプリケーション全体で使用する例外クラス
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppException({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    if (code != null) {
      return 'AppException [$code]: $message';
    }
    return 'AppException: $message';
  }

  /// ユーザー向けのエラーメッセージを取得
  String getUserMessage() {
    return message;
  }
}

/// ネットワークエラー
class NetworkException extends AppException {
  NetworkException({
    required String message,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code ?? 'NETWORK_ERROR',
          originalError: originalError,
          stackTrace: stackTrace,
        );

  @override
  String getUserMessage() {
    return 'ネットワーク接続を確認してください';
  }
}

/// 認証エラー
class AuthException extends AppException {
  AuthException({
    required String message,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code ?? 'AUTH_ERROR',
          originalError: originalError,
          stackTrace: stackTrace,
        );

  @override
  String getUserMessage() {
    return 'ログインが必要です。再度ログインしてください';
  }
}

/// データベースエラー
class DatabaseException extends AppException {
  DatabaseException({
    required String message,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code ?? 'DATABASE_ERROR',
          originalError: originalError,
          stackTrace: stackTrace,
        );

  @override
  String getUserMessage() {
    return 'データの保存に失敗しました。もう一度お試しください';
  }
}

/// バリデーションエラー
class ValidationException extends AppException {
  ValidationException({
    required String message,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code ?? 'VALIDATION_ERROR',
          originalError: originalError,
          stackTrace: stackTrace,
        );

  @override
  String getUserMessage() {
    return message; // バリデーションメッセージはそのまま表示
  }
}

/// 権限エラー
class PermissionException extends AppException {
  PermissionException({
    required String message,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code ?? 'PERMISSION_ERROR',
          originalError: originalError,
          stackTrace: stackTrace,
        );

  @override
  String getUserMessage() {
    return '必要な権限がありません。設定から権限を許可してください';
  }
}
'''.strip()
    
    filepath = os.path.join(PROJECT_ROOT, 'lib', 'models', 'app_exception.dart')
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"✅ Created: {filepath}")

def create_error_handler_service():
    """エラーハンドリングサービスを作成"""
    content = '''import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_exception.dart';

/// グローバルなエラーハンドリングサービス
class ErrorHandlerService {
  /// Supabase エラーをアプリケーション例外に変換
  static AppException handleSupabaseError(dynamic error, StackTrace stackTrace) {
    if (error is AuthException) {
      return AuthException(
        message: 'Authentication failed: ${error.message}',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (error is PostgrestException) {
      if (error.code == '23505') {
        return DatabaseException(
          message: 'Duplicate entry',
          code: 'DUPLICATE_ENTRY',
          originalError: error,
          stackTrace: stackTrace,
        );
      }

      return DatabaseException(
        message: 'Database error: ${error.message}',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (error is StorageException) {
      return DatabaseException(
        message: 'Storage error: ${error.message}',
        code: 'STORAGE_ERROR',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // その他の Supabase エラー
    return AppException(
      message: 'Supabase error: ${error.toString()}',
      code: 'SUPABASE_ERROR',
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// ネットワークエラーをハンドリング
  static AppException handleNetworkError(dynamic error, StackTrace stackTrace) {
    return NetworkException(
      message: 'Network error: ${error.toString()}',
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// 一般的なエラーをハンドリング
  static AppException handleGenericError(dynamic error, StackTrace stackTrace) {
    if (error is AppException) {
      return error;
    }

    return AppException(
      message: error.toString(),
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// エラーをログに記録（開発時のみ）
  static void logError(AppException exception) {
    if (kDebugMode) {
      print('❌ Error [${exception.code}]: ${exception.message}');
      if (exception.originalError != null) {
        print('   Original: ${exception.originalError}');
      }
      if (exception.stackTrace != null) {
        print('   StackTrace: ${exception.stackTrace}');
      }
    }
  }

  /// エラーをユーザーフレンドリーなメッセージに変換
  static String getUserFriendlyMessage(dynamic error) {
    if (error is AppException) {
      return error.getUserMessage();
    }

    // デフォルトメッセージ
    return '予期しないエラーが発生しました。もう一度お試しください';
  }
}
'''.strip()
    
    filepath = os.path.join(PROJECT_ROOT, 'lib', 'services', 'error_handler_service.dart')
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"✅ Created: {filepath}")

def create_error_dialog_widget():
    """エラーダイアログウィジェットを作成"""
    content = '''import 'package:flutter/material.dart';
import '../models/app_exception.dart';
import '../services/error_handler_service.dart';

/// エラー表示用のダイアログ
class ErrorDialog extends StatelessWidget {
  final dynamic error;
  final VoidCallback? onRetry;

  const ErrorDialog({
    super.key,
    required this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final errorMessage = ErrorHandlerService.getUserFriendlyMessage(error);
    final isRetryable = _isRetryableError(error);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.error, color: Colors.red[700]),
          const SizedBox(width: 8),
          const Text('エラー'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(errorMessage),
          if (error is AppException && error.code != null) ...[
            const SizedBox(height: 8),
            Text(
              'エラーコード: ${error.code}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (isRetryable && onRetry != null)
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry!();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('再試行'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
      ],
    );
  }

  bool _isRetryableError(dynamic error) {
    if (error is NetworkException) return true;
    if (error is DatabaseException) return true;
    return false;
  }

  /// エラーを表示する静的メソッド
  static void show(
    BuildContext context, {
    required dynamic error,
    VoidCallback? onRetry,
  }) {
    showDialog(
      context: context,
      builder: (context) => ErrorDialog(
        error: error,
        onRetry: onRetry,
      ),
    );
  }
}

/// エラー表示用のスナックバー
class ErrorSnackBar {
  static void show(
    BuildContext context, {
    required dynamic error,
    VoidCallback? onRetry,
  }) {
    final errorMessage = ErrorHandlerService.getUserFriendlyMessage(error);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(errorMessage)),
          ],
        ),
        backgroundColor: Colors.red[700],
        duration: const Duration(seconds: 4),
        action: onRetry != null
            ? SnackBarAction(
                label: '再試行',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }
}
'''.strip()
    
    filepath = os.path.join(PROJECT_ROOT, 'lib', 'widgets', 'error_dialog.dart')
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"✅ Created: {filepath}")

def create_retry_widget():
    """リトライ機能付きウィジェットを作成"""
    content = '''import 'package:flutter/material.dart';

/// リトライ機能付きの非同期データ表示ウィジェット
class RetryableAsyncWidget<T> extends StatefulWidget {
  final Future<T> Function() futureBuilder;
  final Widget Function(BuildContext context, T data) builder;
  final Widget? loadingWidget;
  final Widget Function(BuildContext context, dynamic error)? errorBuilder;
  final int maxRetries;

  const RetryableAsyncWidget({
    super.key,
    required this.futureBuilder,
    required this.builder,
    this.loadingWidget,
    this.errorBuilder,
    this.maxRetries = 3,
  });

  @override
  State<RetryableAsyncWidget<T>> createState() =>
      _RetryableAsyncWidgetState<T>();
}

class _RetryableAsyncWidgetState<T> extends State<RetryableAsyncWidget<T>> {
  late Future<T> _future;
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
    _future = widget.futureBuilder();
  }

  void _retry() {
    if (_retryCount < widget.maxRetries) {
      setState(() {
        _retryCount++;
        _future = widget.futureBuilder();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.loadingWidget ??
              const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          if (widget.errorBuilder != null) {
            return widget.errorBuilder!(context, snapshot.error);
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'エラーが発生しました',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                if (_retryCount < widget.maxRetries)
                  ElevatedButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh),
                    label: Text('再試行 (${_retryCount + 1}/${widget.maxRetries})'),
                  )
                else
                  const Text(
                    '最大再試行回数に達しました',
                    style: TextStyle(color: Colors.red),
                  ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('データがありません'));
        }

        return widget.builder(context, snapshot.data as T);
      },
    );
  }
}
'''.strip()
    
    filepath = os.path.join(PROJECT_ROOT, 'lib', 'widgets', 'retryable_async_widget.dart')
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"✅ Created: {filepath}")

def create_implementation_guide():
    """実装ガイドを作成"""
    content = '''# Phase 27: エラーハンドリング強化 - 実装ガイド

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
'''.strip()
    
    filepath = os.path.join(PROJECT_ROOT, 'PHASE27_IMPLEMENTATION.md')
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"✅ Created: {filepath}")

def main():
    """メイン処理"""
    print("🚀 Phase 27: Error Handling Enhancement")
    print("=" * 60)
    
    print("\n📦 Creating error handling components...")
    create_app_exception_class()
    create_error_handler_service()
    create_error_dialog_widget()
    create_retry_widget()
    create_implementation_guide()
    
    print("\n✅ Phase 27 Error Handling Enhancement code generated!")
    print("\n📋 次のステップ:")
    print("1. PHASE27_IMPLEMENTATION.md を確認")
    print("2. 既存のサービスクラスにエラーハンドリングを追加")
    print("3. UI にエラーダイアログ/スナックバーを統合")
    print("4. FutureBuilder を RetryableAsyncWidget に置き換え")
    print("5. エラーケースをテスト")

if __name__ == '__main__':
    main()

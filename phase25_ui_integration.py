#!/usr/bin/env python3
"""
Phase 25 Part 2: Offline Support UI Integration
オフライン対応のUI統合を自動生成するスクリプト
"""

import os
import re

# プロジェクトのルートディレクトリ
PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))

def create_offline_banner_widget():
    """オフラインバナーウィジェットを作成"""
    content = '''import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/connectivity_provider.dart';
import '../providers/sync_provider.dart';

/// オフライン状態を表示するバナーウィジェット
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnlineAsync = ref.watch(isOnlineProvider);
    final pendingCountAsync = ref.watch(pendingRoutesCountProvider);

    return isOnlineAsync.when(
      data: (isOnline) {
        if (isOnline) {
          // オンライン時は何も表示しない
          return const SizedBox.shrink();
        }

        // オフライン時はバナーを表示
        return pendingCountAsync.when(
          data: (pendingCount) => _buildOfflineBanner(context, pendingCount),
          loading: () => _buildOfflineBanner(context, 0),
          error: (_, __) => _buildOfflineBanner(context, 0),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildOfflineBanner(BuildContext context, int pendingCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.orange.shade100,
      child: Row(
        children: [
          Icon(Icons.cloud_off, color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              pendingCount > 0
                  ? 'オフラインモード（未同期: $pendingCount件）'
                  : 'オフラインモード',
              style: TextStyle(
                color: Colors.orange.shade900,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (pendingCount > 0)
            Text(
              '接続時に自動同期します',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}
'''.strip()
    
    filepath = os.path.join(PROJECT_ROOT, 'lib', 'widgets', 'offline_banner.dart')
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"✅ Created: {filepath}")

def create_sync_status_widget():
    """同期ステータスウィジェットを作成"""
    content = '''import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sync_provider.dart';
import '../providers/connectivity_provider.dart';
import '../services/sync_service.dart';

/// 同期ステータスを表示するウィジェット（プロフィール画面用）
class SyncStatusCard extends ConsumerWidget {
  const SyncStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnlineAsync = ref.watch(isOnlineProvider);
    final pendingCountAsync = ref.watch(pendingRoutesCountProvider);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sync, size: 24),
                const SizedBox(width: 8),
                const Text(
                  '同期ステータス',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 接続状態
            isOnlineAsync.when(
              data: (isOnline) => _buildConnectionStatus(isOnline),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('接続状態を取得できません'),
            ),
            
            const SizedBox(height: 12),
            
            // 未同期データ数
            pendingCountAsync.when(
              data: (count) => _buildPendingCount(count),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('未同期データを取得できません'),
            ),
            
            const SizedBox(height: 16),
            
            // 手動同期ボタン
            _buildSyncButton(context, ref, isOnlineAsync, pendingCountAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus(bool isOnline) {
    return Row(
      children: [
        Icon(
          isOnline ? Icons.cloud_done : Icons.cloud_off,
          color: isOnline ? Colors.green : Colors.orange,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          isOnline ? 'オンライン' : 'オフライン',
          style: TextStyle(
            color: isOnline ? Colors.green : Colors.orange,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPendingCount(int count) {
    return Row(
      children: [
        Icon(
          count > 0 ? Icons.sync_problem : Icons.check_circle,
          color: count > 0 ? Colors.orange : Colors.green,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          count > 0 ? '未同期データ: $count件' : '全てのデータが同期されています',
          style: TextStyle(
            color: count > 0 ? Colors.orange : Colors.green,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSyncButton(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<bool> isOnlineAsync,
    AsyncValue<int> pendingCountAsync,
  ) {
    final isOnline = isOnlineAsync.value ?? false;
    final pendingCount = pendingCountAsync.value ?? 0;
    final canSync = isOnline && pendingCount > 0;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canSync ? () => _handleManualSync(context, ref) : null,
        icon: const Icon(Icons.sync),
        label: Text(
          canSync ? '今すぐ同期する' : isOnline ? '同期済み' : 'オフライン',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: canSync ? Colors.blue : Colors.grey,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Future<void> _handleManualSync(BuildContext context, WidgetRef ref) async {
    // 同期開始のダイアログを表示
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('同期中...'),
          ],
        ),
      ),
    );

    try {
      // 同期実行
      final syncService = ref.read(syncServiceProvider);
      final result = await syncService.sync();

      // ダイアログを閉じる
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // 結果を表示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.success
                  ? '同期が完了しました（${result.syncedCount}件）'
                  : '同期に失敗しました: ${result.message}',
            ),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );
      }

      // プロバイダーを更新
      ref.invalidate(pendingRoutesCountProvider);
    } catch (e) {
      // エラー処理
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('同期中にエラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
'''.strip()
    
    filepath = os.path.join(PROJECT_ROOT, 'lib', 'widgets', 'sync_status_card.dart')
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"✅ Created: {filepath}")

def update_main_dart():
    """main.dartにオフラインバナーを追加"""
    filepath = os.path.join(PROJECT_ROOT, 'lib', 'main.dart')
    
    if not os.path.exists(filepath):
        print(f"⚠️  File not found: {filepath}")
        return
    
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # インポートを追加
    if "import 'widgets/offline_banner.dart';" not in content:
        # import文の最後に追加
        import_pattern = r"(import '[^']+';[\s\n]+)+([\s\n]*void main\(\))"
        replacement = r"\g<0>import 'widgets/offline_banner.dart';\n\n"
        content = re.sub(import_pattern, replacement, content, count=1)
    
    print(f"ℹ️  main.dart のインポート追加を確認してください")
    print(f"   追加するインポート: import 'widgets/offline_banner.dart';")
    print(f"   MaterialApp の builder に OfflineBanner() を追加してください")

def update_profile_screen():
    """プロフィール画面に同期ステータスカードを追加する手順を出力"""
    print("\n📝 プロフィール画面の更新手順:")
    print("=" * 60)
    print("1. lib/screens/profile/profile_screen.dart を開く")
    print("2. ファイル冒頭に以下をインポート:")
    print("   import '../../widgets/sync_status_card.dart';")
    print()
    print("3. ListView の children に SyncStatusCard() を追加:")
    print("   例: children: [")
    print("         const SyncStatusCard(),  // ← これを追加")
    print("         UserInfoCard(...),")
    print("         ...")
    print("       ]")
    print("=" * 60)

def main():
    """メイン処理"""
    print("🚀 Phase 25 Part 2: Offline Support UI Integration")
    print("=" * 60)
    
    print("\n📦 Creating widgets...")
    create_offline_banner_widget()
    create_sync_status_widget()
    
    print("\n📝 Update instructions:")
    update_main_dart()
    update_profile_screen()
    
    print("\n✅ Phase 25 Part 2 UI Integration code generated!")
    print("\n📋 次のステップ:")
    print("1. ローカル環境で flutter pub get を実行")
    print("2. dart run build_runner build --delete-conflicting-outputs を実行")
    print("3. main.dart と profile_screen.dart を上記の指示に従って更新")
    print("4. アプリを実行してテスト")

if __name__ == '__main__':
    main()

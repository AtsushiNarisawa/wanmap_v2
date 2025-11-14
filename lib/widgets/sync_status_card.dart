import 'package:flutter/material.dart';
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
import 'package:flutter/material.dart';
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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wanmap_v2/services/connectivity_service.dart';
import 'package:wanmap_v2/services/sync_service.dart';
import 'package:wanmap_v2/services/local_database_service.dart';

/// 接続状態プロバイダー
final connectivityServiceProvider = Provider((ref) => ConnectivityService());

/// オンライン状態プロバイダー
final isOnlineProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.connectivityStream;
});

/// 同期サービスプロバイダー
final syncServiceProvider = Provider((ref) => SyncService());

/// 同期状態プロバイダー
final isSyncingProvider = StateProvider<bool>((ref) => false);

/// 未同期ルート数プロバイダー
final pendingRoutesCountProvider = FutureProvider<int>((ref) async {
  final localDb = LocalDatabaseService();
  if (!localDb.isInitialized) return 0;
  return await localDb.getPendingRoutesCount();
});

/// 手動同期アクション
class SyncActions {
  final Ref _ref;

  SyncActions(this._ref);

  Future<SyncResult> sync() async {
    final syncService = _ref.read(syncServiceProvider);
    _ref.read(isSyncingProvider.notifier).state = true;

    try {
      final result = await syncService.sync();
      
      // 同期後に未同期数を更新
      _ref.invalidate(pendingRoutesCountProvider);
      
      return result;
    } finally {
      _ref.read(isSyncingProvider.notifier).state = false;
    }
  }

  Future<void> autoSync() async {
    final syncService = _ref.read(syncServiceProvider);
    await syncService.autoSync();
    
    // 同期後に未同期数を更新
    _ref.invalidate(pendingRoutesCountProvider);
  }
}

final syncActionsProvider = Provider((ref) => SyncActions(ref));

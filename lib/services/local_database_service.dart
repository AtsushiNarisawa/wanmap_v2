import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:wanmap/models/local_route_model.dart';

/// ローカルデータベースサービス（Isar）
class LocalDatabaseService {
  static final LocalDatabaseService _instance =
      LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal();

  Isar? _isar;
  Isar get isar {
    if (_isar == null) {
      throw Exception('LocalDatabaseService not initialized');
    }
    return _isar!;
  }

  bool get isInitialized => _isar != null;

  /// データベースの初期化
  Future<void> initialize() async {
    if (_isar != null) return;

    try {
      final dir = await getApplicationDocumentsDirectory();

      _isar = await Isar.open(
        [
          LocalRouteModelSchema,
          LocalRoutePointModelSchema,
        ],
        directory: dir.path,
        name: 'wanmap_local',
      );

      debugPrint('Isar database initialized at: ${dir.path}');
    } catch (e) {
      debugPrint('Isar initialization error: $e');
      rethrow;
    }
  }

  // ============================================================
  // ルート操作
  // ============================================================

  /// ローカルルートを保存
  Future<int> saveLocalRoute(LocalRouteModel route) async {
    return await isar.writeTxn(() async {
      return await isar.localRouteModels.put(route);
    });
  }

  /// 未同期のルートを取得
  Future<List<LocalRouteModel>> getPendingRoutes() async {
    return await isar.localRouteModels
        .filter()
        .syncStatusEqualTo(SyncStatus.pending)
        .or()
        .syncStatusEqualTo(SyncStatus.failed)
        .findAll();
  }

  /// ユーザーのローカルルートを取得
  Future<List<LocalRouteModel>> getLocalRoutesByUser(String userId) async {
    return await isar.localRouteModels
        .filter()
        .userIdEqualTo(userId)
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// ローカルルートを更新
  Future<void> updateLocalRoute(LocalRouteModel route) async {
    await isar.writeTxn(() async {
      await isar.localRouteModels.put(route);
    });
  }

  /// ローカルルートを削除
  Future<void> deleteLocalRoute(int id) async {
    await isar.writeTxn(() async {
      // 関連するポイントも削除
      await isar.localRoutePointModels
          .filter()
          .localRouteIdEqualTo(id)
          .deleteAll();
      await isar.localRouteModels.delete(id);
    });
  }

  /// 同期済みルートを削除（キャッシュクリーンアップ）
  Future<void> cleanupSyncedRoutes({int daysOld = 30}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

    await isar.writeTxn(() async {
      final oldRoutes = await isar.localRouteModels
          .filter()
          .syncStatusEqualTo(SyncStatus.synced)
          .createdAtLessThan(cutoffDate)
          .findAll();

      for (final route in oldRoutes) {
        // 関連するポイントも削除
        await isar.localRoutePointModels
            .filter()
            .localRouteIdEqualTo(route.id)
            .deleteAll();
      }

      await isar.localRouteModels
          .filter()
          .syncStatusEqualTo(SyncStatus.synced)
          .createdAtLessThan(cutoffDate)
          .deleteAll();
    });

    debugPrint('Cleaned up routes older than $daysOld days');
  }

  // ============================================================
  // ルートポイント操作
  // ============================================================

  /// ルートポイントを一括保存
  Future<void> saveRoutePoints(List<LocalRoutePointModel> points) async {
    await isar.writeTxn(() async {
      await isar.localRoutePointModels.putAll(points);
    });
  }

  /// ルートのポイントを取得
  Future<List<LocalRoutePointModel>> getRoutePoints(int localRouteId) async {
    return await isar.localRoutePointModels
        .filter()
        .localRouteIdEqualTo(localRouteId)
        .sortBySequenceNumber()
        .findAll();
  }

  /// ルートポイントを削除
  Future<void> deleteRoutePoints(int localRouteId) async {
    await isar.writeTxn(() async {
      await isar.localRoutePointModels
          .filter()
          .localRouteIdEqualTo(localRouteId)
          .deleteAll();
    });
  }

  // ============================================================
  // 統計・ユーティリティ
  // ============================================================

  /// 未同期ルート数を取得
  Future<int> getPendingRoutesCount() async {
    return await isar.localRouteModels
        .filter()
        .syncStatusEqualTo(SyncStatus.pending)
        .or()
        .syncStatusEqualTo(SyncStatus.failed)
        .count();
  }

  /// データベースのサイズを取得（MB）
  Future<double> getDatabaseSize() async {
    final size = await isar.getSize();
    return size / (1024 * 1024); // Convert to MB
  }

  /// データベースを閉じる
  Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }
}

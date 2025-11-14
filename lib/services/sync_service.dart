import 'package:flutter/material.dart';
import 'package:wanmap/models/local_route_model.dart';
import 'package:wanmap/models/route_model.dart';
import 'package:wanmap/services/local_database_service.dart';
import 'package:wanmap/services/route_service.dart';
import 'package:wanmap/services/connectivity_service.dart';
import 'dart:convert';

/// オフラインデータとSupabaseの同期サービス
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final _localDb = LocalDatabaseService();
  final _routeService = RouteService();
  final _connectivity = ConnectivityService();

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  /// 同期を実行
  Future<SyncResult> sync() async {
    if (_isSyncing) {
      debugPrint('Sync already in progress');
      return SyncResult(success: false, message: '同期中です');
    }

    if (!_connectivity.isOnline) {
      debugPrint('Cannot sync: offline');
      return SyncResult(success: false, message: 'オフラインです');
    }

    _isSyncing = true;

    try {
      debugPrint('🔄 Starting sync...');

      // 未同期のルートを取得
      final pendingRoutes = await _localDb.getPendingRoutes();
      debugPrint('Found ${pendingRoutes.length} pending routes');

      if (pendingRoutes.isEmpty) {
        return SyncResult(
          success: true,
          message: '同期するデータがありません',
          syncedCount: 0,
        );
      }

      int successCount = 0;
      int failCount = 0;
      final errors = <String>[];

      for (final localRoute in pendingRoutes) {
        try {
          // 同期中状態に更新
          localRoute.syncStatus = SyncStatus.syncing;
          await _localDb.updateLocalRoute(localRoute);

          // ルートポイントを取得
          final localPoints = await _localDb.getRoutePoints(localRoute.id);

          // Supabaseにアップロード
          final routeModel = await _uploadRoute(localRoute, localPoints);

          // 同期済み状態に更新
          localRoute.supabaseId = routeModel.id;
          localRoute.syncStatus = SyncStatus.synced;
          localRoute.updatedAt = DateTime.now();
          await _localDb.updateLocalRoute(localRoute);

          successCount++;
          debugPrint('✅ Synced route: ${localRoute.title}');
        } catch (e) {
          // 同期失敗状態に更新
          localRoute.syncStatus = SyncStatus.failed;
          await _localDb.updateLocalRoute(localRoute);

          failCount++;
          errors.add('${localRoute.title}: $e');
          debugPrint('❌ Failed to sync route: ${localRoute.title} - $e');
        }
      }

      final message = successCount > 0
          ? '$successCount件のルートを同期しました'
          : '同期に失敗しました';

      return SyncResult(
        success: successCount > 0,
        message: message,
        syncedCount: successCount,
        failedCount: failCount,
        errors: errors,
      );
    } catch (e) {
      debugPrint('Sync error: $e');
      return SyncResult(
        success: false,
        message: '同期エラー: $e',
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// ルートをSupabaseにアップロード
  Future<RouteModel> _uploadRoute(
    LocalRouteModel localRoute,
    List<LocalRoutePointModel> localPoints,
  ) async {
    // RouteModelに変換
    final routeModel = RouteModel(
      id: localRoute.supabaseId ?? '',
      userId: localRoute.userId,
      dogId: localRoute.dogId,
      title: localRoute.title,
      description: localRoute.description,
      distance: localRoute.distance,
      duration: localRoute.duration,
      startedAt: localRoute.startedAt,
      endedAt: localRoute.endedAt,
      isPublic: localRoute.isPublic,
      createdAt: localRoute.createdAt,
      updatedAt: localRoute.updatedAt,
    );

    // ポイントデータを準備
    final pointsData = localPoints.map((point) => {
      'latitude': point.latitude,
      'longitude': point.longitude,
      'altitude': point.altitude,
      'accuracy': point.accuracy,
      'speed': point.speed,
      'timestamp': point.timestamp.toIso8601String(),
      'sequence_number': point.sequenceNumber,
    }).toList();

    // ルートを保存（ポイントも一緒に）
    return await _routeService.saveRouteWithPoints(routeModel, pointsData);
  }

  /// 自動同期（オンライン復帰時）
  Future<void> autoSync() async {
    if (!_connectivity.isOnline) return;

    final pendingCount = await _localDb.getPendingRoutesCount();
    if (pendingCount > 0) {
      debugPrint('🔄 Auto sync triggered: $pendingCount pending routes');
      await sync();
    }
  }

  /// ルートをローカルに保存（オフライン対応）
  Future<LocalRouteModel> saveRouteOffline({
    required String userId,
    String? dogId,
    required String title,
    String? description,
    required double distance,
    required int duration,
    required DateTime startedAt,
    DateTime? endedAt,
    required bool isPublic,
    required List<Map<String, dynamic>> points,
  }) async {
    final localRoute = LocalRouteModel()
      ..userId = userId
      ..dogId = dogId
      ..title = title
      ..description = description
      ..distance = distance
      ..duration = duration
      ..startedAt = startedAt
      ..endedAt = endedAt
      ..isPublic = isPublic
      ..syncStatus = SyncStatus.pending
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    // ルートを保存
    final localRouteId = await _localDb.saveLocalRoute(localRoute);
    localRoute.id = localRouteId;

    // ポイントを保存
    final localPoints = points.asMap().entries.map((entry) {
      final index = entry.key;
      final point = entry.value;
      return LocalRoutePointModel()
        ..localRouteId = localRouteId
        ..latitude = point['latitude']
        ..longitude = point['longitude']
        ..altitude = point['altitude']
        ..accuracy = point['accuracy']
        ..speed = point['speed']
        ..timestamp = DateTime.parse(point['timestamp'])
        ..sequenceNumber = index
        ..createdAt = DateTime.now();
    }).toList();

    await _localDb.saveRoutePoints(localPoints);

    debugPrint('💾 Route saved offline: $title');

    // オンラインなら即座に同期
    if (_connectivity.isOnline) {
      autoSync();
    }

    return localRoute;
  }
}

/// 同期結果
class SyncResult {
  final bool success;
  final String message;
  final int syncedCount;
  final int failedCount;
  final List<String> errors;

  SyncResult({
    required this.success,
    required this.message,
    this.syncedCount = 0,
    this.failedCount = 0,
    this.errors = const [],
  });
}

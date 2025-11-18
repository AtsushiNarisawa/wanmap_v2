// ==================================================
// Notification Service for WanMap v2
// ==================================================
// Author: AI Assistant
// Created: 2024-11-17
// Purpose: Service layer for notification system
// ==================================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

/// 通知IDの定数
class NotificationIds {
  static const String dailyWalkReminder = 'daily_walk_reminder';
}

class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ==================================================
  // ローカル通知機能（スタブ実装）
  // ==================================================

  /// 通知権限をリクエスト（スタブ実装）
  Future<bool> requestPermission() async {
    debugPrint('NotificationService.requestPermission() - stub');
    // TODO: flutter_local_notifications等を使った実装が必要
    return true;
  }

  /// 通知システムを初期化（スタブ実装）
  Future<void> initialize() async {
    debugPrint('NotificationService.initialize() - stub');
    // TODO: flutter_local_notifications等を使った実装が必要
  }

  /// すべての通知をキャンセル（スタブ実装）
  Future<void> cancelAllNotifications() async {
    debugPrint('NotificationService.cancelAllNotifications() - stub');
    // TODO: flutter_local_notifications等を使った実装が必要
  }

  /// 特定の通知をキャンセル（スタブ実装）
  Future<void> cancelNotification(String id) async {
    debugPrint('NotificationService.cancelNotification($id) - stub');
    // TODO: flutter_local_notifications等を使った実装が必要
  }

  /// 毎日の通知をスケジュール（スタブ実装）
  Future<void> scheduleDailyNotification({
    required String id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    debugPrint('NotificationService.scheduleDailyNotification() - stub');
    debugPrint('  id: $id, title: $title, time: ${time.hour}:${time.minute}');
    // TODO: flutter_local_notifications等を使った実装が必要
  }

  /// 通知を表示（スタブ実装）
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    debugPrint('NotificationService.showNotification() - stub');
    debugPrint('  id: $id, title: $title, body: $body');
    // TODO: flutter_local_notifications等を使った実装が必要
  }

  /// リソースを解放（スタブ実装）
  void dispose() {
    debugPrint('NotificationService.dispose() - stub');
    // TODO: 必要に応じてリソース解放処理を実装
  }

  // ==================================================
  // 通知取得
  // ==================================================

  /// 通知一覧を取得
  /// [limit] 取得件数
  /// [offset] オフセット
  /// [unreadOnly] 未読のみ取得するか
  Future<List<NotificationModel>> getNotifications({
    int limit = 20,
    int offset = 0,
    bool unreadOnly = false,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('ユーザーがログインしていません');
      }

      final response = await _supabase.rpc(
        'get_notifications',
        params: {
          'p_user_id': userId,
          'p_limit': limit,
          'p_offset': offset,
          'p_unread_only': unreadOnly,
        },
      );

      if (response == null) return [];

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('通知一覧の取得に失敗しました: $e');
    }
  }

  /// 未読通知数を取得
  Future<int> getUnreadCount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return 0;
      }

      final response = await _supabase.rpc(
        'get_unread_notification_count',
        params: {'p_user_id': userId},
      );

      return response as int? ?? 0;
    } catch (e) {
      throw Exception('未読通知数の取得に失敗しました: $e');
    }
  }

  // ==================================================
  // 通知の既読管理
  // ==================================================

  /// 通知を既読にする
  /// [notificationId] 通知ID
  Future<void> markAsRead(String notificationId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('ユーザーがログインしていません');
      }

      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('通知の既読化に失敗しました: $e');
    }
  }

  /// 複数の通知を既読にする
  /// [notificationIds] 通知IDのリスト
  Future<void> markMultipleAsRead(List<String> notificationIds) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('ユーザーがログインしていません');
      }

      if (notificationIds.isEmpty) return;

      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .inFilter('id', notificationIds);
    } catch (e) {
      throw Exception('通知の一括既読化に失敗しました: $e');
    }
  }

  /// 全ての通知を既読にする
  Future<int> markAllAsRead() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('ユーザーがログインしていません');
      }

      final response = await _supabase.rpc(
        'mark_all_notifications_as_read',
        params: {'p_user_id': userId},
      );

      return response as int? ?? 0;
    } catch (e) {
      throw Exception('全通知の既読化に失敗しました: $e');
    }
  }

  // ==================================================
  // 通知削除
  // ==================================================

  /// 通知を削除する
  /// [notificationId] 通知ID
  Future<void> deleteNotification(String notificationId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('ユーザーがログインしていません');
      }

      await _supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('通知の削除に失敗しました: $e');
    }
  }

  /// 複数の通知を削除する
  /// [notificationIds] 通知IDのリスト
  Future<void> deleteMultipleNotifications(List<String> notificationIds) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('ユーザーがログインしていません');
      }

      if (notificationIds.isEmpty) return;

      await _supabase
          .from('notifications')
          .delete()
          .eq('user_id', userId)
          .inFilter('id', notificationIds);
    } catch (e) {
      throw Exception('通知の一括削除に失敗しました: $e');
    }
  }

  /// 既読の通知を全て削除する
  Future<void> deleteAllReadNotifications() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('ユーザーがログインしていません');
      }

      await _supabase
          .from('notifications')
          .delete()
          .eq('user_id', userId)
          .eq('is_read', true);
    } catch (e) {
      throw Exception('既読通知の削除に失敗しました: $e');
    }
  }

  // ==================================================
  // リアルタイム通知
  // ==================================================

  /// 通知の変更をリアルタイムで監視
  /// [onNotification] 新しい通知を受信した時のコールバック
  /// [onUpdate] 通知が更新された時のコールバック
  /// [onDelete] 通知が削除された時のコールバック
  RealtimeChannel subscribeToNotifications({
    required Function(NotificationModel) onNotification,
    Function(NotificationModel)? onUpdate,
    Function(String)? onDelete,
  }) {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('ユーザーがログインしていません');
    }

    final channel = _supabase.channel('notifications:$userId');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            try {
              final notification = NotificationModel.fromJson(
                payload.newRecord as Map<String, dynamic>,
              );
              onNotification(notification);
            } catch (e) {
              print('通知のパースに失敗: $e');
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            if (onUpdate != null) {
              try {
                final notification = NotificationModel.fromJson(
                  payload.newRecord as Map<String, dynamic>,
                );
                onUpdate(notification);
              } catch (e) {
                print('通知の更新パースに失敗: $e');
              }
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            if (onDelete != null) {
              final id = payload.oldRecord['id'] as String?;
              if (id != null) {
                onDelete(id);
              }
            }
          },
        )
        .subscribe();

    return channel;
  }

  /// リアルタイム監視を停止
  Future<void> unsubscribeFromNotifications(RealtimeChannel channel) async {
    await _supabase.removeChannel(channel);
  }

  // ==================================================
  // システム通知（管理者用）
  // ==================================================

  /// 特定ユーザーにシステム通知を送信
  /// 注: この関数はSECURITY DEFINERで実行されるため、管理者権限が必要
  Future<String> sendSystemNotification({
    required String userId,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _supabase.rpc(
        'create_system_notification',
        params: {
          'p_user_id': userId,
          'p_title': title,
          'p_message': message,
          'p_data': data,
        },
      );

      return response as String;
    } catch (e) {
      throw Exception('システム通知の送信に失敗しました: $e');
    }
  }

  /// 全ユーザーにシステム通知を送信
  /// 注: この関数はSECURITY DEFINERで実行されるため、管理者権限が必要
  Future<int> broadcastSystemNotification({
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _supabase.rpc(
        'broadcast_system_notification',
        params: {
          'p_title': title,
          'p_message': message,
          'p_data': data,
        },
      );

      return response as int? ?? 0;
    } catch (e) {
      throw Exception('全体通知の送信に失敗しました: $e');
    }
  }

  // ==================================================
  // メンテナンス機能
  // ==================================================

  /// 古い既読通知を削除（メンテナンス用）
  /// [days] 何日前までの通知を削除するか（デフォルト: 30日）
  Future<int> deleteOldNotifications({int days = 30}) async {
    try {
      final response = await _supabase.rpc(
        'delete_old_notifications',
        params: {'p_days': days},
      );

      return response as int? ?? 0;
    } catch (e) {
      throw Exception('古い通知の削除に失敗しました: $e');
    }
  }
}

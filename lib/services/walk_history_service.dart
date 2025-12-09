import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/walk_history.dart';

/// 散歩履歴を取得するサービス
/// お出かけ散歩と日常散歩の両方に対応
class WalkHistoryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// お出かけ散歩履歴を取得（写真付き）
  /// 
  /// Parameters:
  /// - [userId]: ユーザーID
  /// - [limit]: 取得件数（デフォルト20件）
  /// - [offset]: オフセット（ページネーション用）
  /// 
  /// Returns: お出かけ散歩履歴のリスト
  Future<List<OutingWalkHistory>> getOutingWalkHistory({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      if (kDebugMode) {
        print('🔍 Fetching outing walk history for user: $userId');
      }
      
      final response = await _supabase.rpc(
        'get_outing_walk_history',
        params: {
          'p_user_id': userId,
          'p_limit': limit,
          'p_offset': offset,
        },
      );

      if (kDebugMode) {
        print('📦 RPC response: $response');
      }

      if (response == null) return [];

      final List<dynamic> data = response as List<dynamic>;
      if (kDebugMode) {
        print('✅ Found ${data.length} outing walks');
      }
      return data.map((item) => OutingWalkHistory.fromJson(item)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching outing walk history: $e');
      }
      return [];
    }
  }

  /// 日常散歩履歴を取得（シンプル）
  /// 
  /// Parameters:
  /// - [userId]: ユーザーID
  /// - [limit]: 取得件数（デフォルト20件）
  /// - [offset]: オフセット（ページネーション用）
  /// 
  /// Returns: 日常散歩履歴のリスト
  Future<List<DailyWalkHistory>> getDailyWalkHistory({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_daily_walk_history',
        params: {
          'p_user_id': userId,
          'p_limit': limit,
          'p_offset': offset,
        },
      );

      if (response == null) return [];

      final List<dynamic> data = response as List<dynamic>;
      return data.map((item) => DailyWalkHistory.fromJson(item)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching daily walk history: $e');
      }
      return [];
    }
  }

  /// 全散歩履歴を取得（お出かけ + 日常）
  /// 
  /// Parameters:
  /// - [userId]: ユーザーID
  /// - [limit]: 取得件数
  /// 
  /// Returns: 統合された散歩履歴のリスト
  Future<List<WalkHistoryItem>> getAllWalkHistory({
    required String userId,
    int limit = 20,
  }) async {
    try {
      final outingWalks = await getOutingWalkHistory(userId: userId, limit: limit);
      final dailyWalks = await getDailyWalkHistory(userId: userId, limit: limit);

      // 統合してソート
      final List<WalkHistoryItem> allWalks = [
        ...outingWalks.map((w) => WalkHistoryItem.fromOuting(w)),
        ...dailyWalks.map((w) => WalkHistoryItem.fromDaily(w)),
      ];

      allWalks.sort((a, b) => b.walkedAt.compareTo(a.walkedAt));
      return allWalks.take(limit).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching all walk history: $e');
      }
      return [];
    }
  }

  /// 月別の散歩回数を取得（統計用）
  /// 
  /// Parameters:
  /// - [userId]: ユーザーID
  /// - [year]: 年
  /// - [month]: 月
  /// 
  /// Returns: その月の散歩回数
  Future<int> getMonthlyWalkCount({
    required String userId,
    required int year,
    required int month,
  }) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

      // walks テーブルから全ての散歩回数を取得
      final walkCount = await _supabase
          .from('walks')
          .select('id')
          .eq('user_id', userId)
          .gte('start_time', startDate.toIso8601String())
          .lte('start_time', endDate.toIso8601String())
          .count();

      return walkCount.count;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching monthly walk count: $e');
      }
      return 0;
    }
  }

  /// 訪問したエリア一覧を取得
  /// 
  /// Parameters:
  /// - [userId]: ユーザーID
  /// 
  /// Returns: 訪問したエリアのID一覧
  Future<List<String>> getVisitedAreas({
    required String userId,
  }) async {
    try {
      final response = await _supabase
          .from('walks')
          .select('routes!inner(area)')
          .eq('user_id', userId)
          .eq('walk_type', 'outing')
          .not('route_id', 'is', null);

      final Set<String> areaIds = {};
      for (var item in response) {
        final route = item['routes'];
        if (route != null && route['area'] != null) {
          areaIds.add(route['area'] as String);
        }
      }

      return areaIds.toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching visited areas: $e');
      }
      return [];
    }
  }
}

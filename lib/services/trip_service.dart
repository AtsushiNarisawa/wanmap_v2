import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wanmap_v2/models/trip_model.dart';
import 'package:wanmap_v2/models/route_model.dart';

class TripService {
  final _supabase = Supabase.instance.client;

  /// トリップ一覧を取得（自分のトリップ）
  Future<List<TripModel>> getMyTrips() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('未認証');

    final response = await _supabase
        .from('trips')
        .select('''
          *,
          trip_routes(count)
        ''')
        .eq('user_id', userId)
        .order('start_date', ascending: false);

    return (response as List)
        .map((json) => TripModel.fromJson(json))
        .toList();
  }

  /// 公開トリップ一覧を取得
  Future<List<TripModel>> getPublicTrips({String? destination}) async {
    var query = _supabase
        .from('trips')
        .select('''
          *,
          trip_routes(count)
        ''')
        .eq('is_public', true);

    if (destination != null) {
      query = query.eq('destination', destination);
    }

    final orderedQuery = query.order('start_date', ascending: false);

    final response = await orderedQuery;

    return (response as List)
        .map((json) => TripModel.fromJson(json))
        .toList();
  }

  /// トリップ詳細を取得（ルート情報含む）
  Future<TripModel?> getTripById(String tripId) async {
    final tripResponse = await _supabase
        .from('trips')
        .select()
        .eq('id', tripId)
        .single();

    final trip = TripModel.fromJson(tripResponse);

    // トリップに紐付くルートを取得
    final routesResponse = await _supabase
        .from('trip_routes')
        .select('''
          *,
          routes(*)
        ''')
        .eq('trip_id', tripId)
        .order('day_number', ascending: true)
        .order('sequence_order', ascending: true);

    final routes = (routesResponse as List)
        .map((json) {
          final routeData = json['routes'] as Map<String, dynamic>;
          return RouteModel.fromJson(routeData);
        })
        .toList();

    return trip.copyWith(
      routes: routes,
      routeCount: routes.length,
      totalDistance: routes.fold<double>(0.0, (sum, r) => sum + (r.distance ?? 0.0)),
      totalDuration: routes.fold<int>(0, (sum, r) => sum + (r.duration ?? 0)),
    );
  }

  /// トリップを作成
  Future<TripModel> createTrip(TripModel trip) async {
    final data = trip.toJson();
    data.remove('id'); // IDは自動生成

    final response = await _supabase
        .from('trips')
        .insert(data)
        .select()
        .single();

    return TripModel.fromJson(response);
  }

  /// トリップを更新
  Future<TripModel> updateTrip(TripModel trip) async {
    if (trip.id == null) throw Exception('トリップIDが必要です');

    final data = trip.toJson();
    data.remove('created_at'); // 作成日時は更新しない

    final response = await _supabase
        .from('trips')
        .update(data)
        .eq('id', trip.id!)
        .select()
        .single();

    return TripModel.fromJson(response);
  }

  /// トリップを削除
  Future<void> deleteTrip(String tripId) async {
    await _supabase
        .from('trips')
        .delete()
        .eq('id', tripId);
  }

  /// トリップにルートを追加
  Future<void> addRouteToTrip({
    required String tripId,
    required String routeId,
    int? dayNumber,
    int sequenceOrder = 0,
    String? notes,
  }) async {
    await _supabase.from('trip_routes').insert({
      'trip_id': tripId,
      'route_id': routeId,
      'day_number': dayNumber,
      'sequence_order': sequenceOrder,
      'notes': notes,
    });
  }

  /// トリップからルートを削除
  Future<void> removeRouteFromTrip({
    required String tripId,
    required String routeId,
  }) async {
    await _supabase
        .from('trip_routes')
        .delete()
        .eq('trip_id', tripId)
        .eq('route_id', routeId);
  }

  /// トリップのルート順序を更新
  Future<void> updateRouteOrder({
    required String tripRouteId,
    int? dayNumber,
    int? sequenceOrder,
  }) async {
    final data = <String, dynamic>{};
    if (dayNumber != null) data['day_number'] = dayNumber;
    if (sequenceOrder != null) data['sequence_order'] = sequenceOrder;

    if (data.isEmpty) return;

    await _supabase
        .from('trip_routes')
        .update(data)
        .eq('id', tripRouteId);
  }

  /// トリップの統計を計算
  Future<Map<String, dynamic>> getTripStatistics(String tripId) async {
    final routesResponse = await _supabase
        .from('trip_routes')
        .select('''
          routes(distance, duration)
        ''')
        .eq('trip_id', tripId);

    final routes = routesResponse as List;
    
    double totalDistance = 0;
    int totalDuration = 0;

    for (final item in routes) {
      final route = item['routes'] as Map<String, dynamic>;
      totalDistance += (route['distance'] as num?)?.toDouble() ?? 0;
      totalDuration += route['duration'] as int? ?? 0;
    }

    return {
      'route_count': routes.length,
      'total_distance': totalDistance,
      'total_duration': totalDuration,
      'avg_distance': routes.isEmpty ? 0 : totalDistance / routes.length,
      'avg_duration': routes.isEmpty ? 0 : totalDuration / routes.length,
    };
  }
}

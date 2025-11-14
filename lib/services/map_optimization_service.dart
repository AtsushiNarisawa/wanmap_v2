import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/route_model.dart';

/// 地図描画の最適化サービス
class MapOptimizationService {
  /// ルートポイントを間引いて描画パフォーマンスを向上
  /// 
  /// Douglas-Peucker アルゴリズムを使用してポイント数を削減
  static List<LatLng> simplifyRoute(
    List<LatLng> points, {
    double tolerance = 0.0001, // 約10m
  }) {
    if (points.length <= 2) return points;
    return _douglasPeucker(points, tolerance);
  }

  /// Douglas-Peucker アルゴリズムの実装
  static List<LatLng> _douglasPeucker(List<LatLng> points, double tolerance) {
    if (points.length <= 2) return points;

    // 最初と最後の点を結ぶ線分から最も遠い点を見つける
    double maxDistance = 0;
    int maxIndex = 0;

    for (int i = 1; i < points.length - 1; i++) {
      double distance = _perpendicularDistance(
        points[i],
        points.first,
        points.last,
      );
      if (distance > maxDistance) {
        maxDistance = distance;
        maxIndex = i;
      }
    }

    // 最大距離が許容値より大きい場合、再帰的に簡略化
    if (maxDistance > tolerance) {
      final left = _douglasPeucker(
        points.sublist(0, maxIndex + 1),
        tolerance,
      );
      final right = _douglasPeucker(
        points.sublist(maxIndex),
        tolerance,
      );
      return [...left.sublist(0, left.length - 1), ...right];
    } else {
      return [points.first, points.last];
    }
  }

  /// 点から線分への垂直距離を計算
  static double _perpendicularDistance(
    LatLng point,
    LatLng lineStart,
    LatLng lineEnd,
  ) {
    final dx = lineEnd.latitude - lineStart.latitude;
    final dy = lineEnd.longitude - lineStart.longitude;

    if (dx == 0 && dy == 0) {
      return _distance(point, lineStart);
    }

    final t = ((point.latitude - lineStart.latitude) * dx +
            (point.longitude - lineStart.longitude) * dy) /
        (dx * dx + dy * dy);

    if (t < 0) {
      return _distance(point, lineStart);
    } else if (t > 1) {
      return _distance(point, lineEnd);
    } else {
      final projection = LatLng(
        lineStart.latitude + t * dx,
        lineStart.longitude + t * dy,
      );
      return _distance(point, projection);
    }
  }

  /// 2点間の距離を計算（簡易版）
  static double _distance(LatLng p1, LatLng p2) {
    final dx = p1.latitude - p2.latitude;
    final dy = p1.longitude - p2.longitude;
    return dx * dx + dy * dy;
  }

  /// ズームレベルに応じた最適な簡略化の許容値を取得
  static double getToleranceForZoom(double zoom) {
    if (zoom < 10) return 0.001; // 広域表示：積極的に間引く
    if (zoom < 13) return 0.0005; // 中域表示：中程度の間引き
    if (zoom < 15) return 0.0001; // 近域表示：軽い間引き
    return 0.00005; // 詳細表示：最小限の間引き
  }

  /// メモリ使用量を最適化するため、表示範囲外のルートをフィルタ
  static List<RouteModel> filterRoutesInBounds(
    List<RouteModel> routes,
    LatLngBounds bounds,
  ) {
    return routes.where((route) {
      // ルートの開始点が表示範囲内かチェック
      if (route.startLatitude != null && route.startLongitude != null) {
        final startPoint = LatLng(route.startLatitude!, route.startLongitude!);
        return bounds.contains(startPoint);
      }
      return false;
    }).toList();
  }
}
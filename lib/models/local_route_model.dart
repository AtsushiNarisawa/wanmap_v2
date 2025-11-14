import 'package:isar/isar.dart';

part 'local_route_model.g.dart';

/// ローカルストレージ用のルートモデル（オフライン対応）
@collection
class LocalRouteModel {
  Id id = Isar.autoIncrement;

  /// SupabaseのUUID（同期時に使用）
  @Index()
  String? supabaseId;

  @Index()
  late String userId;

  String? dogId;

  late String title;

  String? description;

  late double distance; // メートル

  late int duration; // 秒

  @Index()
  late DateTime startedAt;

  DateTime? endedAt;

  late bool isPublic;

  /// 同期状態
  @enumerated
  late SyncStatus syncStatus;

  late DateTime createdAt;

  late DateTime updatedAt;

  /// ルートポイント（JSON文字列として保存）
  String? routePointsJson;

  LocalRouteModel();

  /// RouteModelから変換
  factory LocalRouteModel.fromRouteModel(dynamic routeModel) {
    return LocalRouteModel()
      ..supabaseId = routeModel.id
      ..userId = routeModel.userId
      ..dogId = routeModel.dogId
      ..title = routeModel.title
      ..description = routeModel.description
      ..distance = routeModel.distance
      ..duration = routeModel.duration
      ..startedAt = routeModel.startedAt
      ..endedAt = routeModel.endedAt
      ..isPublic = routeModel.isPublic
      ..syncStatus = SyncStatus.synced
      ..createdAt = routeModel.createdAt
      ..updatedAt = routeModel.updatedAt;
  }
}

/// 同期状態
enum SyncStatus {
  /// 未同期（オフラインで作成）
  pending,

  /// 同期中
  syncing,

  /// 同期済み
  synced,

  /// 同期失敗
  failed,
}

/// ローカルルートポイントモデル
@collection
class LocalRoutePointModel {
  Id id = Isar.autoIncrement;

  /// 親ルートのローカルID
  @Index()
  late int localRouteId;

  /// SupabaseのUUID（同期時に使用）
  String? supabaseId;

  late double latitude;

  late double longitude;

  double? altitude;

  double? accuracy;

  double? speed;

  late DateTime timestamp;

  late int sequenceNumber;

  late DateTime createdAt;

  LocalRoutePointModel();
}

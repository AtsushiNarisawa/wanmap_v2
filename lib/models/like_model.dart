class LikeModel {
  final String id;
  final String userId;
  final String routeId;
  final DateTime createdAt;

  LikeModel({
    required this.id,
    required this.userId,
    required this.routeId,
    required this.createdAt,
  });

  factory LikeModel.fromJson(Map<String, dynamic> json) {
    return LikeModel(
      id: json['id'],
      userId: json['user_id'],
      routeId: json['route_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'route_id': routeId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

import 'package:latlong2/latlong.dart';

/// わんスポット（犬関連施設）のモデル
class SpotModel {
  final String? id;
  final String userId;
  final String name;
  final String? description;
  final SpotCategory category;
  final LatLng location;
  final String? address;
  final String? phone;
  final String? website;
  final double? rating; // 0.0 ~ 5.0
  final int upvoteCount;
  final int commentCount;
  final bool isVerified; // 管理者による検証済みフラグ
  final DateTime createdAt;
  final DateTime updatedAt;

  SpotModel({
    this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.category,
    required this.location,
    this.address,
    this.phone,
    this.website,
    this.rating,
    this.upvoteCount = 0,
    this.commentCount = 0,
    this.isVerified = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// 評価を星で表示
  String get ratingDisplay {
    if (rating == null) return '評価なし';
    return '★' * rating!.round() + '☆' * (5 - rating!.round());
  }

  /// JSONからモデルを作成
  factory SpotModel.fromJson(Map<String, dynamic> json) {
    // PostGISのGEOMETRY型からlatitude/longitudeを抽出
    final locationData = json['location'];
    late LatLng location;
    
    if (locationData is Map) {
      // すでにパースされたオブジェクト
      location = LatLng(
        locationData['latitude'] as double,
        locationData['longitude'] as double,
      );
    } else if (locationData is String) {
      // WKT形式: "POINT(lng lat)"
      final coords = locationData
          .replaceAll('POINT(', '')
          .replaceAll(')', '')
          .split(' ');
      location = LatLng(
        double.parse(coords[1]), // latitude
        double.parse(coords[0]), // longitude
      );
    } else {
      // フォールバック
      location = LatLng(0, 0);
    }

    return SpotModel(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: SpotCategoryExtension.fromString(json['category'] as String),
      location: location,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      website: json['website'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      upvoteCount: json['upvote_count'] as int? ?? 0,
      commentCount: json['comment_count'] as int? ?? 0,
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// モデルをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'category': category.value,
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'address': address,
      'phone': phone,
      'website': website,
      'rating': rating,
      'upvote_count': upvoteCount,
      'comment_count': commentCount,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Supabase insert用のJSONに変換（PostGIS対応）
  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'name': name,
      if (description != null) 'description': description,
      'category': category.value,
      // PostGISのPOINT型として挿入（Supabase RPCで変換される）
      'location': 'POINT(${location.longitude} ${location.latitude})',
      if (address != null) 'address': address,
      if (phone != null) 'phone': phone,
      if (website != null) 'website': website,
      if (rating != null) 'rating': rating,
    };
  }

  /// コピーを作成
  SpotModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    SpotCategory? category,
    LatLng? location,
    String? address,
    String? phone,
    String? website,
    double? rating,
    int? upvoteCount,
    int? commentCount,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SpotModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      location: location ?? this.location,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      rating: rating ?? this.rating,
      upvoteCount: upvoteCount ?? this.upvoteCount,
      commentCount: commentCount ?? this.commentCount,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// わんスポットのカテゴリ
enum SpotCategory {
  park,     // 公園
  cafe,     // カフェ
  shop,     // ショップ
  hospital, // 動物病院
  other,    // その他
}

extension SpotCategoryExtension on SpotCategory {
  String get value {
    switch (this) {
      case SpotCategory.park:
        return 'park';
      case SpotCategory.cafe:
        return 'cafe';
      case SpotCategory.shop:
        return 'shop';
      case SpotCategory.hospital:
        return 'hospital';
      case SpotCategory.other:
        return 'other';
    }
  }

  String get displayName {
    switch (this) {
      case SpotCategory.park:
        return '公園';
      case SpotCategory.cafe:
        return 'カフェ';
      case SpotCategory.shop:
        return 'ショップ';
      case SpotCategory.hospital:
        return '動物病院';
      case SpotCategory.other:
        return 'その他';
    }
  }

  String get icon {
    switch (this) {
      case SpotCategory.park:
        return '🌳';
      case SpotCategory.cafe:
        return '☕';
      case SpotCategory.shop:
        return '🛍️';
      case SpotCategory.hospital:
        return '🏥';
      case SpotCategory.other:
        return '📍';
    }
  }

  static SpotCategory fromString(String value) {
    switch (value) {
      case 'park':
        return SpotCategory.park;
      case 'cafe':
        return SpotCategory.cafe;
      case 'shop':
        return SpotCategory.shop;
      case 'hospital':
        return SpotCategory.hospital;
      case 'other':
      default:
        return SpotCategory.other;
    }
  }
}

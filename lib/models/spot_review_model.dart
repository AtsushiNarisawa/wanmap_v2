/// スポット評価・レビューモデル
class SpotReviewModel {
  final String id;
  final String userId;
  final String spotId;
  
  // 評価情報
  final int rating; // 1-5
  final String? reviewText;
  
  // 基本設備情報
  final bool hasWaterFountain;
  final bool hasDogRun;
  final bool hasShade;
  final bool hasToilet;
  final bool hasParking;
  final bool hasDogWasteBin;
  
  // 利用条件
  final bool leashRequired;
  final bool dogFriendlyCafe;
  final String? dogSizeSuitable; // 'small', 'medium', 'large', 'all'
  
  // 追加情報
  final String? seasonalInfo;
  
  // 写真
  final List<String> photoUrls;
  
  // メタ情報
  final DateTime createdAt;
  final DateTime updatedAt;

  SpotReviewModel({
    required this.id,
    required this.userId,
    required this.spotId,
    required this.rating,
    this.reviewText,
    this.hasWaterFountain = false,
    this.hasDogRun = false,
    this.hasShade = false,
    this.hasToilet = false,
    this.hasParking = false,
    this.hasDogWasteBin = false,
    this.leashRequired = false,
    this.dogFriendlyCafe = false,
    this.dogSizeSuitable,
    this.seasonalInfo,
    this.photoUrls = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        assert(rating >= 1 && rating <= 5, 'Rating must be between 1 and 5');

  /// Supabaseから取得したJSONをSpotReviewModelオブジェクトに変換
  factory SpotReviewModel.fromJson(Map<String, dynamic> json) {
    List<String> photoUrls = [];
    if (json['photo_urls'] != null && json['photo_urls'] is List) {
      photoUrls = (json['photo_urls'] as List).map((e) => e.toString()).toList();
    }

    return SpotReviewModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      spotId: json['spot_id'] as String,
      rating: json['rating'] as int,
      reviewText: json['review_text'] as String?,
      hasWaterFountain: json['has_water_fountain'] as bool? ?? false,
      hasDogRun: json['has_dog_run'] as bool? ?? false,
      hasShade: json['has_shade'] as bool? ?? false,
      hasToilet: json['has_toilet'] as bool? ?? false,
      hasParking: json['has_parking'] as bool? ?? false,
      hasDogWasteBin: json['has_dog_waste_bin'] as bool? ?? false,
      leashRequired: json['leash_required'] as bool? ?? false,
      dogFriendlyCafe: json['dog_friendly_cafe'] as bool? ?? false,
      dogSizeSuitable: json['dog_size_suitable'] as String?,
      seasonalInfo: json['seasonal_info'] as String?,
      photoUrls: photoUrls,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// SpotReviewModelオブジェクトをJSON形式に変換（Supabase挿入用）
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'spot_id': spotId,
      'rating': rating,
      'review_text': reviewText,
      'has_water_fountain': hasWaterFountain,
      'has_dog_run': hasDogRun,
      'has_shade': hasShade,
      'has_toilet': hasToilet,
      'has_parking': hasParking,
      'has_dog_waste_bin': hasDogWasteBin,
      'leash_required': leashRequired,
      'dog_friendly_cafe': dogFriendlyCafe,
      'dog_size_suitable': dogSizeSuitable,
      'seasonal_info': seasonalInfo,
      'photo_urls': photoUrls,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// 挿入用JSONに変換（idを除外）
  Map<String, dynamic> toInsertJson() {
    final json = toJson();
    json.remove('id');
    json.remove('created_at');
    json.remove('updated_at');
    return json;
  }

  /// 更新用JSONに変換（id, user_id, spot_id, created_atを除外）
  Map<String, dynamic> toUpdateJson() {
    final json = toJson();
    json.remove('id');
    json.remove('user_id');
    json.remove('spot_id');
    json.remove('created_at');
    return json;
  }

  /// 設備情報の有無をチェック
  bool get hasAnyFacilities {
    return hasWaterFountain ||
        hasDogRun ||
        hasShade ||
        hasToilet ||
        hasParking ||
        hasDogWasteBin ||
        dogFriendlyCafe;
  }

  /// 設備情報のリストを取得
  List<String> get facilityList {
    final List<String> facilities = [];
    if (hasWaterFountain) facilities.add('水飲み場');
    if (hasDogRun) facilities.add('ドッグラン');
    if (hasShade) facilities.add('日陰');
    if (hasToilet) facilities.add('トイレ');
    if (hasParking) facilities.add('駐車場');
    if (hasDogWasteBin) facilities.add('犬用ゴミ箱');
    if (dogFriendlyCafe) facilities.add('犬同伴カフェ');
    if (leashRequired) facilities.add('リード必須');
    return facilities;
  }

  /// 犬のサイズ表示
  String get dogSizeSuitableDisplay {
    switch (dogSizeSuitable) {
      case 'small':
        return '小型犬向け';
      case 'medium':
        return '中型犬向け';
      case 'large':
        return '大型犬向け';
      case 'all':
        return '全サイズOK';
      default:
        return '未設定';
    }
  }

  /// 写真の枚数
  int get photoCount => photoUrls.length;

  /// 写真があるかどうか
  bool get hasPhotos => photoUrls.isNotEmpty;

  /// 相対時間表示（例：「3日前」「2時間前」）
  String get relativeTime {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inDays > 0) {
      return '${diff.inDays}日前';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}時間前';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}分前';
    } else {
      return 'たった今';
    }
  }

  /// コピーメソッド
  SpotReviewModel copyWith({
    String? id,
    String? userId,
    String? spotId,
    int? rating,
    String? reviewText,
    bool? hasWaterFountain,
    bool? hasDogRun,
    bool? hasShade,
    bool? hasToilet,
    bool? hasParking,
    bool? hasDogWasteBin,
    bool? leashRequired,
    bool? dogFriendlyCafe,
    String? dogSizeSuitable,
    String? seasonalInfo,
    List<String>? photoUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SpotReviewModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      spotId: spotId ?? this.spotId,
      rating: rating ?? this.rating,
      reviewText: reviewText ?? this.reviewText,
      hasWaterFountain: hasWaterFountain ?? this.hasWaterFountain,
      hasDogRun: hasDogRun ?? this.hasDogRun,
      hasShade: hasShade ?? this.hasShade,
      hasToilet: hasToilet ?? this.hasToilet,
      hasParking: hasParking ?? this.hasParking,
      hasDogWasteBin: hasDogWasteBin ?? this.hasDogWasteBin,
      leashRequired: leashRequired ?? this.leashRequired,
      dogFriendlyCafe: dogFriendlyCafe ?? this.dogFriendlyCafe,
      dogSizeSuitable: dogSizeSuitable ?? this.dogSizeSuitable,
      seasonalInfo: seasonalInfo ?? this.seasonalInfo,
      photoUrls: photoUrls ?? this.photoUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'SpotReviewModel(id: $id, spotId: $spotId, rating: $rating)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SpotReviewModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

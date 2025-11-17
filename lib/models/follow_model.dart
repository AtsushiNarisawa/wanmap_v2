import 'package:wanmap_v2/models/profile_model.dart';

class FollowModel {
  final String id;
  final String followerId;
  final String followingId;
  final DateTime createdAt;
  final ProfileModel? followerProfile;
  final ProfileModel? followingProfile;

  FollowModel({
    required this.id,
    required this.followerId,
    required this.followingId,
    required this.createdAt,
    this.followerProfile,
    this.followingProfile,
  });

  factory FollowModel.fromJson(Map<String, dynamic> json) {
    return FollowModel(
      id: json['id'],
      followerId: json['follower_id'],
      followingId: json['following_id'],
      createdAt: DateTime.parse(json['created_at']),
      followerProfile: json['follower_profile'] != null
          ? ProfileModel.fromJson(json['follower_profile'])
          : null,
      followingProfile: json['following_profile'] != null
          ? ProfileModel.fromJson(json['following_profile'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'follower_id': followerId,
      'following_id': followingId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class FollowStats {
  final String userId;
  final int followerCount;
  final int followingCount;

  FollowStats({
    required this.userId,
    required this.followerCount,
    required this.followingCount,
  });

  factory FollowStats.fromJson(Map<String, dynamic> json) {
    return FollowStats(
      userId: json['user_id'],
      followerCount: json['follower_count'] ?? 0,
      followingCount: json['following_count'] ?? 0,
    );
  }
}

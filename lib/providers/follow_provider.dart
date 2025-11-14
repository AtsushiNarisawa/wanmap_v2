import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wanmap/models/follow_model.dart';
import 'package:wanmap/models/profile_model.dart';
import 'package:wanmap/services/follow_service.dart';

final followServiceProvider = Provider((ref) => FollowService());

/// フォロー状態プロバイダー
final isFollowingProvider = FutureProvider.family<bool, String>((ref, userId) async {
  final service = ref.watch(followServiceProvider);
  return await service.isFollowing(userId);
});

/// フォロー統計プロバイダー
final followStatsProvider = FutureProvider.family<FollowStats, String>((ref, userId) async {
  final service = ref.watch(followServiceProvider);
  return await service.getFollowStats(userId);
});

/// フォロワー一覧プロバイダー
final followersProvider = FutureProvider.family<List<ProfileModel>, String>((ref, userId) async {
  final service = ref.watch(followServiceProvider);
  return await service.getFollowers(userId);
});

/// フォロー中一覧プロバイダー
final followingProvider = FutureProvider.family<List<ProfileModel>, String>((ref, userId) async {
  final service = ref.watch(followServiceProvider);
  return await service.getFollowing(userId);
});

/// ユーザー検索プロバイダー
final userSearchProvider = FutureProvider.family<List<ProfileModel>, String>((ref, query) async {
  final service = ref.watch(followServiceProvider);
  return await service.searchUsers(query);
});

/// フォロー/アンフォローアクション
class FollowActions {
  final FollowService _service;
  final Ref _ref;

  FollowActions(this._service, this._ref);

  Future<void> toggleFollow(String userId) async {
    final isFollowing = await _service.isFollowing(userId);
    
    if (isFollowing) {
      await _service.unfollowUser(userId);
    } else {
      await _service.followUser(userId);
    }

    // プロバイダーを無効化して再読み込み
    _ref.invalidate(isFollowingProvider(userId));
    _ref.invalidate(followStatsProvider(userId));
  }
}

final followActionsProvider = Provider((ref) {
  final service = ref.watch(followServiceProvider);
  return FollowActions(service, ref);
});

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wanmap/models/follow_model.dart';
import 'package:wanmap/models/profile_model.dart';

class FollowService {
  final _supabase = Supabase.instance.client;

  /// ユーザーをフォローする
  Future<void> followUser(String followingId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('未認証');

    await _supabase.from('follows').insert({
      'follower_id': userId,
      'following_id': followingId,
    });
  }

  /// ユーザーのフォローを解除する
  Future<void> unfollowUser(String followingId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('未認証');

    await _supabase
        .from('follows')
        .delete()
        .eq('follower_id', userId)
        .eq('following_id', followingId);
  }

  /// フォローしているかチェック
  Future<bool> isFollowing(String followingId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    final response = await _supabase
        .from('follows')
        .select()
        .eq('follower_id', userId)
        .eq('following_id', followingId)
        .maybeSingle();

    return response != null;
  }

  /// フォロワー一覧を取得
  Future<List<ProfileModel>> getFollowers(String userId) async {
    final response = await _supabase
        .from('follows')
        .select('follower_id, profiles!follows_follower_id_fkey(*)')
        .eq('following_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => ProfileModel.fromJson(item['profiles']))
        .toList();
  }

  /// フォロー中のユーザー一覧を取得
  Future<List<ProfileModel>> getFollowing(String userId) async {
    final response = await _supabase
        .from('follows')
        .select('following_id, profiles!follows_following_id_fkey(*)')
        .eq('follower_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => ProfileModel.fromJson(item['profiles']))
        .toList();
  }

  /// フォロー統計を取得
  Future<FollowStats> getFollowStats(String userId) async {
    final response = await _supabase
        .from('follow_stats')
        .select()
        .eq('user_id', userId)
        .single();

    return FollowStats.fromJson(response);
  }

  /// ユーザー検索
  Future<List<ProfileModel>> searchUsers(String query) async {
    if (query.isEmpty) return [];

    final response = await _supabase
        .from('profiles')
        .select()
        .or('display_name.ilike.%$query%,email.ilike.%$query%')
        .limit(20);

    return (response as List)
        .map((item) => ProfileModel.fromJson(item))
        .toList();
  }
}

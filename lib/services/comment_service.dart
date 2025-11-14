import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/comment_model.dart';

class CommentService {
  final _supabase = Supabase.instance.client;

  /// コメントを投稿
  Future<bool> postComment({
    required String routeId,
    required String userId,
    required String content,
  }) async {
    try {
      await _supabase.from('comments').insert({
        'route_id': routeId,
        'user_id': userId,
        'content': content,
      });

      print('✅ Comment posted');
      return true;
    } catch (e) {
      print('❌ Error posting comment: $e');
      return false;
    }
  }

  /// ルートのコメント一覧を取得
  Future<List<CommentModel>> getRouteComments(String routeId) async {
    try {
      final response = await _supabase
          .from('comments')
          .select('''
            *,
            profiles:user_id (
              display_name,
              avatar_url
            )
          ''')
          .eq('route_id', routeId)
          .order('created_at', ascending: false);

      final List<CommentModel> comments = [];
      for (final item in response) {
        final profile = item['profiles'];
        comments.add(CommentModel(
          id: item['id'],
          routeId: item['route_id'],
          userId: item['user_id'],
          content: item['content'],
          createdAt: DateTime.parse(item['created_at']),
          userDisplayName: profile?['display_name'],
          userAvatarUrl: profile?['avatar_url'],
        ));
      }

      return comments;
    } catch (e) {
      print('❌ Error getting comments: $e');
      return [];
    }
  }

  /// コメントを削除
  Future<bool> deleteComment(String commentId, String userId) async {
    try {
      await _supabase
          .from('comments')
          .delete()
          .eq('id', commentId)
          .eq('user_id', userId);

      print('✅ Comment deleted');
      return true;
    } catch (e) {
      print('❌ Error deleting comment: $e');
      return false;
    }
  }
}

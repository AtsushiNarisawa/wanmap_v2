import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/spot_model.dart';

/// わんスポット管理サービス
class SpotService {
  final _supabase = Supabase.instance.client;
  final _picker = ImagePicker();

  /// ギャラリーから写真を選択
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      print('画像選択エラー: $e');
      return null;
    }
  }

  /// カメラで写真を撮影
  Future<File?> takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      print('カメラ撮影エラー: $e');
      return null;
    }
  }

  /// スポットの写真をアップロード
  Future<String?> uploadSpotPhoto({
    required File file,
    required String userId,
    String? spotId,
  }) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'spots/$userId/$fileName';

      // Supabase Storageにアップロード
      await _supabase.storage
          .from('spot-photos')
          .upload(filePath, file);

      // 公開URLを取得
      final publicUrl = _supabase.storage
          .from('spot-photos')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      print('スポット写真アップロードエラー: $e');
      return null;
    }
  }

  /// スポットを作成
  Future<SpotModel?> createSpot(SpotModel spot) async {
    try {
      final response = await _supabase
          .from('spots')
          .insert(spot.toInsertJson())
          .select()
          .single();

      return SpotModel.fromJson(response);
    } catch (e) {
      print('スポット作成エラー: $e');
      return null;
    }
  }

  /// スポット重複チェック（近隣50m以内）
  Future<List<SpotModel>> checkDuplicateSpots({
    required String name,
    required LatLng location,
    double radiusMeters = 50.0,
  }) async {
    try {
      // PostGISのST_DWithin関数を使用して近隣スポットを検索
      final response = await _supabase.rpc(
        'check_spot_duplicate',
        params: {
          'spot_name': name,
          'spot_lat': location.latitude,
          'spot_lng': location.longitude,
          'radius_meters': radiusMeters,
        },
      );

      if (response == null || response is! List) {
        return [];
      }

      return (response as List)
          .map((json) => SpotModel.fromJson(json))
          .toList();
    } catch (e) {
      print('スポット重複チェックエラー: $e');
      return [];
    }
  }

  /// 近隣のスポットを検索
  Future<List<SpotModel>> searchNearbySpots({
    required LatLng location,
    double radiusKm = 10.0,
    SpotCategory? category,
  }) async {
    try {
      // PostGISのST_DWithin関数を使用して近隣スポットを検索
      final response = await _supabase.rpc(
        'search_nearby_spots',
        params: {
          'user_lat': location.latitude,
          'user_lng': location.longitude,
          'search_radius_km': radiusKm,
          'category_filter': category?.value,
        },
      );

      if (response == null || response is! List) {
        return [];
      }

      return (response as List)
          .map((json) => SpotModel.fromJson(json))
          .toList();
    } catch (e) {
      print('近隣スポット検索エラー: $e');
      return [];
    }
  }

  /// スポット一覧を取得
  Future<List<SpotModel>> getSpots({
    int limit = 50,
    SpotCategory? category,
  }) async {
    try {
      var query = _supabase
          .from('spots')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      if (category != null) {
        query = query.eq('category', category.value);
      }

      final response = await query;

      return (response as List)
          .map((json) => SpotModel.fromJson(json))
          .toList();
    } catch (e) {
      print('スポット一覧取得エラー: $e');
      return [];
    }
  }

  /// スポット詳細を取得
  Future<SpotModel?> getSpotById(String spotId) async {
    try {
      final response = await _supabase
          .from('spots')
          .select()
          .eq('id', spotId)
          .single();

      return SpotModel.fromJson(response);
    } catch (e) {
      print('スポット詳細取得エラー: $e');
      return null;
    }
  }

  /// スポットを更新
  Future<SpotModel?> updateSpot(String spotId, Map<String, dynamic> updates) async {
    try {
      // updated_atを自動更新
      updates['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('spots')
          .update(updates)
          .eq('id', spotId)
          .select()
          .single();

      return SpotModel.fromJson(response);
    } catch (e) {
      print('スポット更新エラー: $e');
      return null;
    }
  }

  /// スポットを削除
  Future<bool> deleteSpot(String spotId, String userId) async {
    try {
      await _supabase
          .from('spots')
          .delete()
          .eq('id', spotId)
          .eq('user_id', userId);

      return true;
    } catch (e) {
      print('スポット削除エラー: $e');
      return false;
    }
  }

  /// スポットにupvote（いいね）
  Future<bool> upvoteSpot({
    required String spotId,
    required String userId,
  }) async {
    try {
      // 既存のupvoteをチェック
      final existing = await _supabase
          .from('spot_upvotes')
          .select()
          .eq('spot_id', spotId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        // 既にupvote済みなら削除（トグル動作）
        await _supabase
            .from('spot_upvotes')
            .delete()
            .eq('spot_id', spotId)
            .eq('user_id', userId);
        return false;
      } else {
        // 新しくupvoteを追加
        await _supabase.from('spot_upvotes').insert({
          'spot_id': spotId,
          'user_id': userId,
        });
        return true;
      }
    } catch (e) {
      print('スポットupvoteエラー: $e');
      return false;
    }
  }

  /// ユーザーが特定のスポットをupvoteしているかチェック
  Future<bool> hasUserUpvoted({
    required String spotId,
    required String userId,
  }) async {
    try {
      final response = await _supabase
          .from('spot_upvotes')
          .select()
          .eq('spot_id', spotId)
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('upvoteチェックエラー: $e');
      return false;
    }
  }

  /// スポットのupvote数を取得
  Future<int> getUpvoteCount(String spotId) async {
    try {
      final response = await _supabase
          .from('spot_upvotes')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('spot_id', spotId);

      return response.count ?? 0;
    } catch (e) {
      print('upvote数取得エラー: $e');
      return 0;
    }
  }
}

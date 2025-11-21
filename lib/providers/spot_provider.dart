import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../models/spot_model.dart';
import '../services/spot_service.dart';

/// わんスポット情報の状態を管理するProvider
class SpotProvider extends ChangeNotifier {
  final SpotService _spotService = SpotService();
  
  List<SpotModel> _spots = [];
  SpotModel? _selectedSpot;
  bool _isLoading = false;
  String? _errorMessage;
  
  // 検索フィルタ
  SpotCategory? _categoryFilter;
  
  // Getters
  List<SpotModel> get spots => _spots;
  SpotModel? get selectedSpot => _selectedSpot;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  SpotCategory? get categoryFilter => _categoryFilter;
  bool get hasSpots => _spots.isNotEmpty;
  
  /// スポット一覧を読み込み
  Future<void> loadSpots({
    int limit = 50,
    SpotCategory? category,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _categoryFilter = category;
    notifyListeners();
    
    try {
      _spots = await _spotService.getSpots(
        limit: limit,
        category: category,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'スポット一覧の取得に失敗しました: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// 近隣のスポットを検索
  Future<void> searchNearbySpots({
    required LatLng location,
    double radiusKm = 10.0,
    SpotCategory? category,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _categoryFilter = category;
    notifyListeners();
    
    try {
      _spots = await _spotService.searchNearbySpots(
        location: location,
        radiusKm: radiusKm,
        category: category,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = '近隣スポットの検索に失敗しました: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// スポット詳細を取得
  Future<SpotModel?> getSpotDetail(String spotId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final spot = await _spotService.getSpotById(spotId);
      _isLoading = false;
      
      if (spot != null) {
        _selectedSpot = spot;
      } else {
        _errorMessage = 'スポット詳細の取得に失敗しました';
      }
      
      notifyListeners();
      return spot;
    } catch (e) {
      _errorMessage = 'スポット詳細の取得に失敗しました: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
  
  /// スポットを作成
  Future<SpotModel?> createSpot(SpotModel spot) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final newSpot = await _spotService.createSpot(spot);
      if (newSpot != null) {
        _spots.insert(0, newSpot); // 先頭に追加
        _isLoading = false;
        notifyListeners();
      }
      return newSpot;
    } catch (e) {
      _errorMessage = 'スポットの作成に失敗しました: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
  
  /// スポット重複チェック
  Future<List<SpotModel>> checkDuplicateSpots({
    required String name,
    required LatLng location,
    double radiusMeters = 50.0,
  }) async {
    try {
      return await _spotService.checkDuplicateSpots(
        name: name,
        location: location,
        radiusMeters: radiusMeters,
      );
    } catch (e) {
      _errorMessage = 'スポット重複チェックに失敗しました: ${e.toString()}';
      notifyListeners();
      return [];
    }
  }
  
  /// スポットを更新
  Future<SpotModel?> updateSpot(String spotId, Map<String, dynamic> updates) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final updatedSpot = await _spotService.updateSpot(spotId, updates);
      if (updatedSpot != null) {
        final index = _spots.indexWhere((s) => s.id == spotId);
        if (index != -1) {
          _spots[index] = updatedSpot;
        }
        if (_selectedSpot?.id == spotId) {
          _selectedSpot = updatedSpot;
        }
        _isLoading = false;
        notifyListeners();
      }
      return updatedSpot;
    } catch (e) {
      _errorMessage = 'スポットの更新に失敗しました: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
  
  /// スポットを削除
  Future<bool> deleteSpot(String spotId, String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final success = await _spotService.deleteSpot(spotId, userId);
      if (success) {
        _spots.removeWhere((s) => s.id == spotId);
        if (_selectedSpot?.id == spotId) {
          _selectedSpot = null;
        }
        _isLoading = false;
        notifyListeners();
      }
      return success;
    } catch (e) {
      _errorMessage = 'スポットの削除に失敗しました: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// スポットにupvote
  Future<bool> upvoteSpot({
    required String spotId,
    required String userId,
  }) async {
    try {
      final isUpvoted = await _spotService.upvoteSpot(
        spotId: spotId,
        userId: userId,
      );
      
      // ローカルのupvoteカウントを更新
      final index = _spots.indexWhere((s) => s.id == spotId);
      if (index != -1) {
        final spot = _spots[index];
        _spots[index] = spot.copyWith(
          upvoteCount: spot.upvoteCount + (isUpvoted ? 1 : -1),
        );
      }
      
      if (_selectedSpot?.id == spotId) {
        final spot = _selectedSpot!;
        _selectedSpot = spot.copyWith(
          upvoteCount: spot.upvoteCount + (isUpvoted ? 1 : -1),
        );
      }
      
      notifyListeners();
      return isUpvoted;
    } catch (e) {
      _errorMessage = 'upvoteに失敗しました: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  /// ユーザーが特定のスポットをupvoteしているかチェック
  Future<bool> hasUserUpvoted({
    required String spotId,
    required String userId,
  }) async {
    return await _spotService.hasUserUpvoted(
      spotId: spotId,
      userId: userId,
    );
  }
  
  /// スポットを選択
  void selectSpot(SpotModel spot) {
    _selectedSpot = spot;
    notifyListeners();
  }
  
  /// スポットの選択を解除
  void clearSelectedSpot() {
    _selectedSpot = null;
    notifyListeners();
  }
  
  /// カテゴリフィルタを設定
  void setCategoryFilter(SpotCategory? category) {
    _categoryFilter = category;
    notifyListeners();
  }
  
  /// フィルタをクリア
  void clearFilters() {
    _categoryFilter = null;
    notifyListeners();
  }
  
  /// ギャラリーから写真を選択
  Future<File?> pickImageFromGallery() async {
    return await _spotService.pickImageFromGallery();
  }
  
  /// カメラで写真を撮影
  Future<File?> takePhoto() async {
    return await _spotService.takePhoto();
  }
  
  /// スポットの写真をアップロード
  Future<String?> uploadSpotPhoto({
    required File file,
    required String userId,
    String? spotId,
  }) async {
    return await _spotService.uploadSpotPhoto(
      file: file,
      userId: userId,
      spotId: spotId,
    );
  }
  
  /// エラーメッセージをクリア
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/dog_model.dart';
import '../services/dog_service.dart';

/// 犬情報の状態を管理するProvider
/// ChangeNotifierを使用してProviderパッケージと連携
class DogProvider extends ChangeNotifier {
  final DogService _dogService = DogService();
  
  List<DogModel> _dogs = [];
  DogModel? _selectedDog;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getters
  List<DogModel> get dogs => _dogs;
  DogModel? get selectedDog => _selectedDog;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasDogs => _dogs.isNotEmpty;
  
  /// ユーザーの犬一覧を読み込み
  Future<void> loadUserDogs(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _dogs = await _dogService.getUserDogs(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = '犬一覧の取得に失敗しました: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// 犬情報を作成
  Future<DogModel?> createDog(DogModel dog) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final newDog = await _dogService.createDog(dog);
      if (newDog != null) {
        _dogs.insert(0, newDog); // 先頭に追加
        _isLoading = false;
        notifyListeners();
      }
      return newDog;
    } catch (e) {
      _errorMessage = '犬情報の作成に失敗しました: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
  
  /// 犬情報を更新
  Future<DogModel?> updateDog(String dogId, Map<String, dynamic> updates) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final updatedDog = await _dogService.updateDog(dogId, updates);
      if (updatedDog != null) {
        final index = _dogs.indexWhere((dog) => dog.id == dogId);
        if (index != -1) {
          _dogs[index] = updatedDog;
        }
        if (_selectedDog?.id == dogId) {
          _selectedDog = updatedDog;
        }
        _isLoading = false;
        notifyListeners();
      }
      return updatedDog;
    } catch (e) {
      _errorMessage = '犬情報の更新に失敗しました: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
  
  /// 犬情報を削除
  Future<bool> deleteDog(String dogId, String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final success = await _dogService.deleteDog(dogId, userId);
      if (success) {
        _dogs.removeWhere((dog) => dog.id == dogId);
        if (_selectedDog?.id == dogId) {
          _selectedDog = null;
        }
        _isLoading = false;
        notifyListeners();
      }
      return success;
    } catch (e) {
      _errorMessage = '犬情報の削除に失敗しました: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// 犬を選択
  void selectDog(DogModel dog) {
    _selectedDog = dog;
    notifyListeners();
  }
  
  /// 犬の選択を解除
  void clearSelectedDog() {
    _selectedDog = null;
    notifyListeners();
  }
  
  /// 犬の写真を更新
  Future<String?> updateDogPhoto({
    required String dogId,
    required String userId,
    required File file,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final newPhotoUrl = await _dogService.updateDogPhoto(
        dogId: dogId,
        userId: userId,
        file: file,
      );
      
      if (newPhotoUrl != null) {
        // ローカルの犬情報を更新
        final index = _dogs.indexWhere((dog) => dog.id == dogId);
        if (index != -1) {
          _dogs[index] = _dogs[index].copyWith(photoUrl: newPhotoUrl);
        }
        if (_selectedDog?.id == dogId) {
          _selectedDog = _selectedDog!.copyWith(photoUrl: newPhotoUrl);
        }
      }
      
      _isLoading = false;
      notifyListeners();
      return newPhotoUrl;
    } catch (e) {
      _errorMessage = '写真の更新に失敗しました: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
  
  /// ギャラリーから写真を選択
  Future<File?> pickImageFromGallery() async {
    return await _dogService.pickImageFromGallery();
  }
  
  /// カメラで写真を撮影
  Future<File?> takePhoto() async {
    return await _dogService.takePhoto();
  }
  
  /// 犬の写真をアップロード
  Future<String?> uploadDogPhoto({
    required File file,
    required String userId,
    String? dogId,
  }) async {
    return await _dogService.uploadDogPhoto(
      file: file,
      userId: userId,
      dogId: dogId,
    );
  }
  
  /// エラーメッセージをクリア
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

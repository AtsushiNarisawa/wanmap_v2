import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../models/route_model.dart';
import '../services/gps_service.dart';

/// GPS記録の状態を管理するProvider
class GpsProvider extends ChangeNotifier {
  final GpsService _gpsService = GpsService();
  
  bool _isRecording = false;
  bool _isPaused = false;
  LatLng? _currentLocation;
  List<RoutePoint> _currentRoutePoints = [];
  String? _errorMessage;
  
  // Getters
  bool get isRecording => _isRecording;
  bool get isPaused => _isPaused;
  LatLng? get currentLocation => _currentLocation;
  List<RoutePoint> get currentRoutePoints => _currentRoutePoints;
  int get currentPointCount => _currentRoutePoints.length;
  String? get errorMessage => _errorMessage;
  bool get hasPermission => _currentLocation != null;
  
  /// 現在位置を取得
  Future<void> getCurrentLocation() async {
    try {
      _currentLocation = await _gpsService.getCurrentPosition();
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = '位置情報の取得に失敗しました: ${e.toString()}';
      notifyListeners();
    }
  }
  
  /// GPS権限をチェック
  Future<bool> checkPermission() async {
    try {
      final hasPermission = await _gpsService.checkPermission();
      if (!hasPermission) {
        _errorMessage = '位置情報の権限が必要です';
        notifyListeners();
      }
      return hasPermission;
    } catch (e) {
      _errorMessage = '権限チェックに失敗しました: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  /// 記録を開始
  Future<bool> startRecording() async {
    try {
      final success = await _gpsService.startRecording();
      if (success) {
        _isRecording = true;
        _isPaused = false;
        _currentRoutePoints = [];
        _errorMessage = null;
        notifyListeners();
        
        // 定期的にポイント数を更新
        _startPointCountUpdater();
      } else {
        _errorMessage = '記録の開始に失敗しました';
        notifyListeners();
      }
      return success;
    } catch (e) {
      _errorMessage = '記録開始エラー: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  /// 記録を一時停止
  void pauseRecording() {
    if (!_isRecording || _isPaused) return;
    
    _gpsService.pauseRecording();
    _isPaused = true;
    notifyListeners();
  }
  
  /// 記録を再開
  void resumeRecording() {
    if (!_isRecording || !_isPaused) return;
    
    _gpsService.resumeRecording();
    _isPaused = false;
    notifyListeners();
  }
  
  /// 記録を停止
  RouteModel? stopRecording({
    required String userId,
    required String title,
    String? description,
    String? dogId,
    bool isPublic = false,
  }) {
    if (!_isRecording) {
      _errorMessage = '記録していません';
      notifyListeners();
      return null;
    }
    
    final route = _gpsService.stopRecording(
      userId: userId,
      title: title,
      description: description,
      dogId: dogId,
      isPublic: isPublic,
    );
    
    if (route != null) {
      _isRecording = false;
      _isPaused = false;
      _currentRoutePoints = [];
      _errorMessage = null;
      notifyListeners();
    } else {
      _errorMessage = 'ルート記録に失敗しました（ポイント不足）';
      notifyListeners();
    }
    
    return route;
  }
  
  /// 記録をキャンセル
  void cancelRecording() {
    _gpsService.dispose();
    _isRecording = false;
    _isPaused = false;
    _currentRoutePoints = [];
    _errorMessage = null;
    notifyListeners();
  }
  
  /// 定期的にポイント数を更新
  void _startPointCountUpdater() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (_isRecording) {
        _currentRoutePoints = _gpsService.currentRoutePoints;
        notifyListeners();
        return true;
      }
      return false;
    });
  }
  
  /// エラーメッセージをクリア
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _gpsService.dispose();
    super.dispose();
  }
}

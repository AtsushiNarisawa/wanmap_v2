import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// ネットワーク接続状態を監視するサービス
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _subscription;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// サービスの初期化
  Future<void> initialize() async {
    // 初期状態を確認
    await _checkConnectivity();

    // 接続状態の変更を監視
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      _updateConnectionStatus(result);
    });

    debugPrint('ConnectivityService initialized. Online: $_isOnline');
  }

  /// 現在の接続状態を確認
  Future<void> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      debugPrint('接続状態確認エラー: $e');
      _isOnline = false;
    }
  }

  /// 接続状態を更新
  void _updateConnectionStatus(ConnectivityResult result) {
    final wasOnline = _isOnline;
    
    // none以外の接続があればオンライン
    _isOnline = result != ConnectivityResult.none;

    debugPrint('Connectivity changed: $_isOnline (result: $result)');

    // 状態が変わった場合のみ通知
    if (wasOnline != _isOnline) {
      _connectivityController.add(_isOnline);
      
      if (_isOnline) {
        debugPrint('📶 オンラインに復帰しました');
      } else {
        debugPrint('📵 オフラインになりました');
      }
    }
  }

  /// オンラインかどうかを再確認
  Future<bool> checkConnection() async {
    await _checkConnectivity();
    return _isOnline;
  }

  /// サービスの終了
  void dispose() {
    _subscription?.cancel();
    _connectivityController.close();
  }
}

/// 接続状態プロバイダー用の値
class ConnectivityStatus {
  final bool isOnline;
  final DateTime lastChecked;

  ConnectivityStatus({
    required this.isOnline,
    required this.lastChecked,
  });

  ConnectivityStatus copyWith({
    bool? isOnline,
    DateTime? lastChecked,
  }) {
    return ConnectivityStatus(
      isOnline: isOnline ?? this.isOnline,
      lastChecked: lastChecked ?? this.lastChecked,
    );
  }
}

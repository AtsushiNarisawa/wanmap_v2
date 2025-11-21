import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../config/env.dart';
import '../../config/wanmap_colors.dart';
import '../../providers/gps_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dog_provider.dart';
import '../../models/dog_model.dart';
import '../../services/route_service.dart';

/// GPS記録画面
class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  final MapController _mapController = MapController();
  Timer? _timer;
  int _elapsedSeconds = 0;
  
  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// 位置情報を初期化
  Future<void> _initializeLocation() async {
    final gpsProvider = context.read<GpsProvider>();
    await gpsProvider.getCurrentLocation();
    
    if (gpsProvider.currentLocation != null) {
      _mapController.move(gpsProvider.currentLocation!, 16.0);
    }
  }

  /// 記録を開始
  Future<void> _startRecording() async {
    final gpsProvider = context.read<GpsProvider>();
    final hasPermission = await gpsProvider.checkPermission();
    
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('位置情報の権限が必要です'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    final success = await gpsProvider.startRecording();
    
    if (success) {
      // タイマーを開始
      _elapsedSeconds = 0;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _elapsedSeconds++;
        });
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('記録を開始しました'),
            backgroundColor: WanMapColors.success,
          ),
        );
      }
    }
  }

  /// 記録を停止して保存
  Future<void> _stopAndSaveRecording() async {
    final gpsProvider = context.read<GpsProvider>();
    
    if (gpsProvider.currentPointCount < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('記録するには最低2つのポイントが必要です'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // 保存ダイアログを表示
    final result = await _showSaveDialog();
    
    if (result != null) {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.currentUser?.id;
      
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ユーザー情報が取得できません'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // 記録を停止してルートを取得
      final route = gpsProvider.stopRecording(
        userId: userId,
        title: result['title'],
        description: result['description'],
        dogId: result['dogId'],
        isPublic: result['isPublic'],
      );
      
      if (route != null) {
        // タイマーを停止
        _timer?.cancel();
        _elapsedSeconds = 0;
        
        // ルートをSupabaseに保存
        final routeService = RouteService();
        final savedRoute = await routeService.saveRoute(route);
        
        if (mounted) {
          if (savedRoute != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('ルートを保存しました'),
                backgroundColor: WanMapColors.success,
              ),
            );
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('ルートの保存に失敗しました'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }
  }

  /// 保存ダイアログを表示
  Future<Map<String, dynamic>?> _showSaveDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final dogProvider = context.read<DogProvider>();
    
    // 犬一覧を取得
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;
    if (userId != null) {
      await dogProvider.loadUserDogs(userId);
    }
    
    DogModel? selectedDog;
    bool isPublic = true;
    
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('ルートを保存'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'タイトル *',
                    hintText: '例: 公園の散歩',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: '説明',
                    hintText: '例: 桜がきれいでした',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                
                // 犬を選択
                if (dogProvider.hasDogs)
                  DropdownButtonFormField<DogModel>(
                    value: selectedDog,
                    decoration: const InputDecoration(
                      labelText: '愛犬',
                      hintText: '選択してください',
                    ),
                    items: dogProvider.dogs.map((dog) {
                      return DropdownMenuItem(
                        value: dog,
                        child: Text(dog.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedDog = value;
                      });
                    },
                  ),
                const SizedBox(height: 16),
                
                // 公開設定
                SwitchListTile(
                  title: const Text('公開する'),
                  subtitle: const Text('他のユーザーがこのルートを閲覧できます'),
                  value: isPublic,
                  onChanged: (value) {
                    setState(() {
                      isPublic = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('タイトルを入力してください'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                Navigator.pop(context, {
                  'title': titleController.text.trim(),
                  'description': descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                  'dogId': selectedDog?.id,
                  'isPublic': isPublic,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: WanMapColors.accent,
              ),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  /// 経過時間をフォーマット
  String _formatElapsedTime() {
    final hours = _elapsedSeconds ~/ 3600;
    final minutes = (_elapsedSeconds % 3600) ~/ 60;
    final seconds = _elapsedSeconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GPS記録'),
        backgroundColor: WanMapColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<GpsProvider>(
        builder: (context, gpsProvider, child) {
          return Stack(
            children: [
              // 地図
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: gpsProvider.currentLocation ?? const LatLng(35.6812, 139.7671),
                  initialZoom: 16.0,
                  minZoom: 5.0,
                  maxZoom: 18.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.thunderforest.com/outdoors/{z}/{x}/{y}.png?apikey=${Environment.thunderforestApiKey}',
                    userAgentPackageName: 'com.example.wanmap',
                  ),
                  
                  // 記録中のルートライン
                  if (gpsProvider.currentRoutePoints.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: gpsProvider.currentRoutePoints
                              .map((p) => p.latLng)
                              .toList(),
                          color: WanMapColors.accent,
                          strokeWidth: 4.0,
                        ),
                      ],
                    ),
                  
                  // 現在位置マーカー
                  if (gpsProvider.currentLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: gpsProvider.currentLocation!,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.my_location,
                            color: WanMapColors.primary,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              
              // 情報パネル
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _InfoItem(
                              label: '経過時間',
                              value: _formatElapsedTime(),
                              icon: Icons.timer,
                            ),
                            _InfoItem(
                              label: '記録点',
                              value: '${gpsProvider.currentPointCount}',
                              icon: Icons.location_on,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // コントロールボタン
              Positioned(
                bottom: 32,
                left: 16,
                right: 16,
                child: Column(
                  children: [
                    if (!gpsProvider.isRecording)
                      // 開始ボタン
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton.icon(
                          onPressed: _startRecording,
                          icon: const Icon(Icons.play_arrow, size: 32),
                          label: const Text(
                            '記録開始',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: WanMapColors.accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      )
                    else
                      // 記録中のコントロール
                      Row(
                        children: [
                          // 一時停止/再開ボタン
                          Expanded(
                            child: SizedBox(
                              height: 60,
                              child: ElevatedButton.icon(
                                onPressed: gpsProvider.isPaused
                                    ? () => gpsProvider.resumeRecording()
                                    : () => gpsProvider.pauseRecording(),
                                icon: Icon(
                                  gpsProvider.isPaused ? Icons.play_arrow : Icons.pause,
                                  size: 28,
                                ),
                                label: Text(
                                  gpsProvider.isPaused ? '再開' : '一時停止',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          // 停止ボタン
                          Expanded(
                            child: SizedBox(
                              height: 60,
                              child: ElevatedButton.icon(
                                onPressed: _stopAndSaveRecording,
                                icon: const Icon(Icons.stop, size: 28),
                                label: const Text(
                                  '停止',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 情報項目ウィジェット
class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  
  const _InfoItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: WanMapColors.primary, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: WanMapColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

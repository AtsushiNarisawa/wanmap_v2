import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/env.dart';
import '../../config/wanmap_colors.dart';
import '../../models/spot_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/spot_provider.dart';
import '../../providers/gps_provider.dart';

/// わんスポット登録画面
class SpotRegistrationScreen extends StatefulWidget {
  const SpotRegistrationScreen({super.key});

  @override
  State<SpotRegistrationScreen> createState() => _SpotRegistrationScreenState();
}

class _SpotRegistrationScreenState extends State<SpotRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();
  final MapController _mapController = MapController();
  
  SpotCategory _selectedCategory = SpotCategory.park;
  LatLng? _selectedLocation;
  File? _selectedImage;
  bool _isLoading = false;
  List<SpotModel> _duplicateSpots = [];

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  /// 位置情報を初期化
  Future<void> _initializeLocation() async {
    final gpsProvider = context.read<GpsProvider>();
    await gpsProvider.getCurrentLocation();
    
    if (gpsProvider.currentLocation != null) {
      setState(() {
        _selectedLocation = gpsProvider.currentLocation;
      });
      _mapController.move(_selectedLocation!, 16.0);
    }
  }

  /// 写真を選択
  Future<void> _pickImage(ImageSource source) async {
    final spotProvider = context.read<SpotProvider>();
    
    File? image;
    if (source == ImageSource.gallery) {
      image = await spotProvider.pickImageFromGallery();
    } else {
      image = await spotProvider.takePhoto();
    }
    
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  /// 写真選択のダイアログを表示
  Future<void> _showImageSourceDialog() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: WanMapColors.primary),
                title: const Text('ギャラリーから選択'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: WanMapColors.primary),
                title: const Text('カメラで撮影'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_selectedImage != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('写真を削除'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedImage = null;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 重複チェック
  Future<void> _checkDuplicate() async {
    if (_nameController.text.trim().isEmpty || _selectedLocation == null) {
      return;
    }
    
    final spotProvider = context.read<SpotProvider>();
    final duplicates = await spotProvider.checkDuplicateSpots(
      name: _nameController.text.trim(),
      location: _selectedLocation!,
      radiusMeters: 50.0,
    );
    
    if (mounted) {
      setState(() {
        _duplicateSpots = duplicates;
      });
      
      if (duplicates.isNotEmpty) {
        _showDuplicateWarning(duplicates);
      }
    }
  }

  /// 重複警告ダイアログを表示
  Future<void> _showDuplicateWarning(List<SpotModel> duplicates) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('重複の可能性'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('近隣（50m以内）に似たスポットが既に登録されています：'),
            const SizedBox(height: 12),
            ...duplicates.map((spot) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '• ${spot.name} (${spot.category.displayName})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            )),
            const SizedBox(height: 12),
            const Text('それでも登録しますか？'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: WanMapColors.accent,
            ),
            child: const Text('登録する'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        _saveSpot();
      }
    });
  }

  /// スポットを保存
  Future<void> _saveSpot() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('地図上で位置を選択してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final authProvider = context.read<AuthProvider>();
      final spotProvider = context.read<SpotProvider>();
      final userId = authProvider.currentUser?.id;
      
      if (userId == null) {
        throw Exception('ユーザーIDが取得できません');
      }
      
      // 写真をアップロード
      String? photoUrl;
      if (_selectedImage != null) {
        photoUrl = await spotProvider.uploadSpotPhoto(
          file: _selectedImage!,
          userId: userId,
        );
      }
      
      // スポットを作成
      final newSpot = SpotModel(
        userId: userId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        category: _selectedCategory,
        location: _selectedLocation!,
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        website: _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text.trim(),
      );
      
      final createdSpot = await spotProvider.createSpot(newSpot);
      
      if (mounted) {
        if (createdSpot != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('わんスポットを登録しました'),
              backgroundColor: WanMapColors.success,
            ),
          );
          Navigator.pop(context, true);
        } else {
          throw Exception('スポットの作成に失敗しました');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラー: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WanMapColors.background,
      appBar: AppBar(
        title: const Text('わんスポット登録'),
        backgroundColor: WanMapColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 地図
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _selectedLocation ?? const LatLng(35.6812, 139.7671),
                      initialZoom: 16.0,
                      onTap: (_, point) {
                        setState(() {
                          _selectedLocation = point;
                        });
                        _checkDuplicate();
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.thunderforest.com/outdoors/{z}/{x}/{y}.png?apikey=${Environment.thunderforestApiKey}',
                        userAgentPackageName: 'com.example.wanmap',
                      ),
                      if (_selectedLocation != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _selectedLocation!,
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.place,
                                color: WanMapColors.accent,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '地図をタップして場所を選択してください',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),

                // 写真
                if (_selectedImage != null)
                  GestureDetector(
                    onTap: _showImageSourceDialog,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                          image: FileImage(_selectedImage!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: _showImageSourceDialog,
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text('写真を追加（任意）'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                const SizedBox(height: 24),

                // 名前
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'スポット名 *',
                    hintText: '例: わんわん公園',
                    prefixIcon: const Icon(Icons.location_on),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'スポット名を入力してください';
                    }
                    return null;
                  },
                  onChanged: (_) => _checkDuplicate(),
                ),
                const SizedBox(height: 16),

                // カテゴリ
                DropdownButtonFormField<SpotCategory>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'カテゴリ *',
                    prefixIcon: const Icon(Icons.category),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: SpotCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // 説明
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: '説明',
                    hintText: 'スポットの特徴や魅力を入力',
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // 住所
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: '住所',
                    hintText: '例: 東京都渋谷区...',
                    prefixIcon: const Icon(Icons.home),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                // 電話番号
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: '電話番号',
                    hintText: '例: 03-1234-5678',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),

                // ウェブサイト
                TextFormField(
                  controller: _websiteController,
                  decoration: InputDecoration(
                    labelText: 'ウェブサイト',
                    hintText: 'https://example.com',
                    prefixIcon: const Icon(Icons.link),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 24),

                // 必須項目の注意書き
                Text(
                  '* は必須項目です',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),

                // 登録ボタン
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () async {
                      // 重複チェック
                      if (_duplicateSpots.isEmpty) {
                        _saveSpot();
                      } else {
                        _showDuplicateWarning(_duplicateSpots);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WanMapColors.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            '登録する',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

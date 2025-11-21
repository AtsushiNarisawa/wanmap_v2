import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/dog_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dog_provider.dart';
import '../../config/wanmap_colors.dart';

/// 犬情報登録画面
class DogRegistrationScreen extends StatefulWidget {
  final DogModel? existingDog; // 編集モードの場合は既存の犬情報を渡す
  
  const DogRegistrationScreen({
    super.key,
    this.existingDog,
  });

  @override
  State<DogRegistrationScreen> createState() => _DogRegistrationScreenState();
}

class _DogRegistrationScreenState extends State<DogRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _weightController = TextEditingController();
  
  DogSize? _selectedSize;
  DateTime? _selectedBirthDate;
  File? _selectedImage;
  String? _existingPhotoUrl;
  bool _isLoading = false;
  
  bool get _isEditMode => widget.existingDog != null;

  @override
  void initState() {
    super.initState();
    
    // 編集モードの場合は既存データを設定
    if (_isEditMode) {
      final dog = widget.existingDog!;
      _nameController.text = dog.name;
      _breedController.text = dog.breed ?? '';
      _weightController.text = dog.weight?.toString() ?? '';
      _selectedSize = dog.size;
      _selectedBirthDate = dog.birthDate;
      _existingPhotoUrl = dog.photoUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  /// 写真を選択
  Future<void> _pickImage(ImageSource source) async {
    final dogProvider = context.read<DogProvider>();
    
    File? image;
    if (source == ImageSource.gallery) {
      image = await dogProvider.pickImageFromGallery();
    } else {
      image = await dogProvider.takePhoto();
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
              if (_selectedImage != null || _existingPhotoUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('写真を削除'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedImage = null;
                      _existingPhotoUrl = null;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 生年月日を選択
  Future<void> _selectBirthDate() async {
    final now = DateTime.now();
    final initialDate = _selectedBirthDate ?? DateTime(now.year - 5, now.month, now.day);
    
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1990),
      lastDate: now,
      locale: const Locale('ja', 'JP'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: WanMapColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  /// 犬情報を保存
  Future<void> _saveDog() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final authProvider = context.read<AuthProvider>();
      final dogProvider = context.read<DogProvider>();
      final userId = authProvider.currentUser?.id;
      
      if (userId == null) {
        throw Exception('ユーザーIDが取得できません');
      }
      
      // 写真をアップロード（新しい写真が選択されている場合）
      String? photoUrl = _existingPhotoUrl;
      if (_selectedImage != null) {
        photoUrl = await dogProvider.uploadDogPhoto(
          file: _selectedImage!,
          userId: userId,
        );
      }
      
      if (_isEditMode) {
        // 更新モード
        final updates = <String, dynamic>{
          'name': _nameController.text.trim(),
          'breed': _breedController.text.trim().isEmpty ? null : _breedController.text.trim(),
          'size': _selectedSize?.value,
          'birth_date': _selectedBirthDate?.toIso8601String().split('T')[0],
          'weight': _weightController.text.isEmpty ? null : double.parse(_weightController.text),
          'photo_url': photoUrl,
        };
        
        await dogProvider.updateDog(widget.existingDog!.id!, updates);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('犬情報を更新しました'),
              backgroundColor: WanMapColors.success,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        // 新規登録モード
        final newDog = DogModel(
          userId: userId,
          name: _nameController.text.trim(),
          breed: _breedController.text.trim().isEmpty ? null : _breedController.text.trim(),
          size: _selectedSize,
          birthDate: _selectedBirthDate,
          weight: _weightController.text.isEmpty ? null : double.parse(_weightController.text),
          photoUrl: photoUrl,
        );
        
        final createdDog = await dogProvider.createDog(newDog);
        
        if (mounted) {
          if (createdDog != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('犬情報を登録しました'),
                backgroundColor: WanMapColors.success,
              ),
            );
            Navigator.pop(context, true);
          } else {
            throw Exception('犬情報の作成に失敗しました');
          }
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
        title: Text(_isEditMode ? '犬情報を編集' : '犬情報を登録'),
        backgroundColor: WanMapColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 写真
                Center(
                  child: GestureDetector(
                    onTap: _showImageSourceDialog,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: WanMapColors.primary,
                          width: 3,
                        ),
                        image: _selectedImage != null
                            ? DecorationImage(
                                image: FileImage(_selectedImage!),
                                fit: BoxFit.cover,
                              )
                            : _existingPhotoUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(_existingPhotoUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                      ),
                      child: (_selectedImage == null && _existingPhotoUrl == null)
                          ? Icon(
                              Icons.add_a_photo,
                              size: 50,
                              color: Colors.grey[400],
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '写真をタップして変更',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),

                // 名前
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: '名前 *',
                    hintText: '愛犬の名前',
                    prefixIcon: const Icon(Icons.pets),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '名前を入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 犬種
                TextFormField(
                  controller: _breedController,
                  decoration: InputDecoration(
                    labelText: '犬種',
                    hintText: '柴犬、トイプードルなど',
                    prefixIcon: const Icon(Icons.category_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                // サイズ
                DropdownButtonFormField<DogSize>(
                  value: _selectedSize,
                  decoration: InputDecoration(
                    labelText: 'サイズ',
                    prefixIcon: const Icon(Icons.straighten),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: DogSize.values.map((size) {
                    return DropdownMenuItem(
                      value: size,
                      child: Text(size.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSize = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // 生年月日
                InkWell(
                  onTap: _selectBirthDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: '生年月日',
                      prefixIcon: const Icon(Icons.cake_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    child: Text(
                      _selectedBirthDate != null
                          ? '${_selectedBirthDate!.year}年${_selectedBirthDate!.month}月${_selectedBirthDate!.day}日'
                          : '選択してください',
                      style: TextStyle(
                        color: _selectedBirthDate != null ? Colors.black : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 体重
                TextFormField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: '体重 (kg)',
                    hintText: '例: 5.5',
                    prefixIcon: const Icon(Icons.monitor_weight_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final weight = double.tryParse(value);
                      if (weight == null || weight <= 0) {
                        return '正しい体重を入力してください';
                      }
                    }
                    return null;
                  },
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

                // 保存ボタン
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveDog,
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
                        : Text(
                            _isEditMode ? '更新する' : '登録する',
                            style: const TextStyle(
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/dog_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dog_provider.dart';
import '../../config/wanmap_colors.dart';
import 'dog_registration_screen.dart';

/// 犬一覧画面
class DogListScreen extends StatefulWidget {
  const DogListScreen({super.key});

  @override
  State<DogListScreen> createState() => _DogListScreenState();
}

class _DogListScreenState extends State<DogListScreen> {
  @override
  void initState() {
    super.initState();
    _loadDogs();
  }

  /// 犬一覧を読み込み
  Future<void> _loadDogs() async {
    final authProvider = context.read<AuthProvider>();
    final dogProvider = context.read<DogProvider>();
    final userId = authProvider.currentUser?.id;
    
    if (userId != null) {
      await dogProvider.loadUserDogs(userId);
    }
  }

  /// 犬を削除
  Future<void> _deleteDog(DogModel dog) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('犬情報を削除'),
        content: Text('${dog.name}の情報を削除しますか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final authProvider = context.read<AuthProvider>();
      final dogProvider = context.read<DogProvider>();
      final userId = authProvider.currentUser?.id;
      
      if (userId != null) {
        final success = await dogProvider.deleteDog(dog.id!, userId);
        
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('犬情報を削除しました'),
                backgroundColor: WanMapColors.success,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('削除に失敗しました'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }
  }

  /// 犬を編集
  Future<void> _editDog(DogModel dog) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DogRegistrationScreen(existingDog: dog),
      ),
    );
    
    // 編集から戻ってきたら一覧を再読み込み
    if (result == true) {
      _loadDogs();
    }
  }

  /// 新規登録画面へ遷移
  Future<void> _addNewDog() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const DogRegistrationScreen(),
      ),
    );
    
    // 登録から戻ってきたら一覧を再読み込み
    if (result == true) {
      _loadDogs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WanMapColors.background,
      appBar: AppBar(
        title: const Text('愛犬一覧'),
        backgroundColor: WanMapColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<DogProvider>(
        builder: (context, dogProvider, child) {
          if (dogProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          if (dogProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    dogProvider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadDogs,
                    child: const Text('再読み込み'),
                  ),
                ],
              ),
            );
          }
          
          if (!dogProvider.hasDogs) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.pets,
                    size: 100,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '愛犬を登録しましょう',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '散歩の記録を始めるために\n愛犬の情報を登録してください',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _addNewDog,
                    icon: const Icon(Icons.add),
                    label: const Text('犬を登録'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WanMapColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          
          return RefreshIndicator(
            onRefresh: _loadDogs,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: dogProvider.dogs.length,
              itemBuilder: (context, index) {
                final dog = dogProvider.dogs[index];
                return _DogCard(
                  dog: dog,
                  onEdit: () => _editDog(dog),
                  onDelete: () => _deleteDog(dog),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewDog,
        backgroundColor: WanMapColors.accent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

/// 犬情報カード
class _DogCard extends StatelessWidget {
  final DogModel dog;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  
  const _DogCard({
    required this.dog,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 写真
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: WanMapColors.primary,
                    width: 2,
                  ),
                  image: dog.photoUrl != null
                      ? DecorationImage(
                          image: NetworkImage(dog.photoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: Colors.grey[200],
                ),
                child: dog.photoUrl == null
                    ? Icon(
                        Icons.pets,
                        size: 40,
                        color: Colors.grey[400],
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              
              // 情報
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dog.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (dog.breed != null)
                      Text(
                        dog.breed!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (dog.size != null) ...[
                          _InfoChip(
                            icon: Icons.straighten,
                            label: dog.sizeDisplay,
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (dog.age != null)
                          _InfoChip(
                            icon: Icons.cake,
                            label: dog.ageDisplay,
                          ),
                        if (dog.weight != null) ...[
                          const SizedBox(width: 8),
                          _InfoChip(
                            icon: Icons.monitor_weight,
                            label: dog.weightDisplay,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // メニューボタン
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: WanMapColors.primary),
                        SizedBox(width: 8),
                        Text('編集'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('削除'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 情報チップ
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: WanMapColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: WanMapColors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: WanMapColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

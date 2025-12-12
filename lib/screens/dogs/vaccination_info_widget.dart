import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';
import '../../models/dog_model.dart';
import '../../services/dog_service.dart';
import '../../providers/dog_provider.dart';

/// 予防接種情報ウィジェット
class VaccinationInfoWidget extends ConsumerStatefulWidget {
  final DogModel dog;
  final String userId;

  const VaccinationInfoWidget({
    super.key,
    required this.dog,
    required this.userId,
  });

  @override
  ConsumerState<VaccinationInfoWidget> createState() => _VaccinationInfoWidgetState();
}

class _VaccinationInfoWidgetState extends ConsumerState<VaccinationInfoWidget> {
  final _dogService = DogService();
  bool _isUploading = false;

  /// 日付選択ダイアログ
  Future<DateTime?> _selectDate(DateTime? initialDate) async {
    return showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
  }

  /// ワクチン写真を選択してアップロード
  Future<void> _uploadVaccinationPhoto(String vaccineType) async {
    try {
      setState(() => _isUploading = true);

      // 写真を選択
      final file = await _dogService.pickImageFromGallery();
      if (file == null) {
        setState(() => _isUploading = false);
        return;
      }

      // アップロード
      final photoUrl = await _dogService.uploadVaccinationPhoto(
        file: file,
        userId: widget.userId,
        dogId: widget.dog.id!,
        vaccineType: vaccineType,
      );

      if (photoUrl == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('写真のアップロードに失敗しました')),
          );
        }
        setState(() => _isUploading = false);
        return;
      }

      // データベースを更新
      final fieldName = vaccineType == 'rabies' 
          ? 'rabies_vaccine_photo_url' 
          : 'mixed_vaccine_photo_url';
      
      await ref.read(dogProvider.notifier).updateDog(
        widget.dog.id!,
        {fieldName: photoUrl},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('写真をアップロードしました')),
        );
      }

      setState(() => _isUploading = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
      setState(() => _isUploading = false);
    }
  }

  /// 接種日を更新
  Future<void> _updateVaccinationDate(String vaccineType, DateTime? currentDate) async {
    final newDate = await _selectDate(currentDate);
    if (newDate == null) return;

    try {
      final fieldName = vaccineType == 'rabies' 
          ? 'rabies_vaccine_date' 
          : 'mixed_vaccine_date';
      
      await ref.read(dogProvider.notifier).updateDog(
        widget.dog.id!,
        {fieldName: newDate.toIso8601String().split('T')[0]},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('接種日を更新しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    }
  }

  /// 写真を全画面表示
  void _showFullScreenImage(String photoUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  photoUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.error,
                        color: Colors.white,
                        size: 48,
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // 最新の愛犬データを取得（更新後に自動で反映される）
    final dogState = ref.watch(dogProvider);
    final currentDog = dogState.dogs.firstWhere(
      (dog) => dog.id == widget.dog.id,
      orElse: () => widget.dog,
    );
    
    return Container(
      padding: const EdgeInsets.all(WanMapSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? WanMapColors.surfaceDark : WanMapColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? WanMapColors.borderDark : WanMapColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🏥 予防接種情報',
            style: WanMapTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: WanMapSpacing.lg),
          
          // 狂犬病ワクチン
          _buildVaccinationCard(
            title: '狂犬病ワクチン',
            vaccineType: 'rabies',
            photoUrl: currentDog.rabiesVaccinePhotoUrl,
            date: currentDog.rabiesVaccineDate,
            isDark: isDark,
          ),
          
          const SizedBox(height: WanMapSpacing.md),
          
          // 混合ワクチン
          _buildVaccinationCard(
            title: '混合ワクチン',
            vaccineType: 'mixed',
            photoUrl: currentDog.mixedVaccinePhotoUrl,
            date: currentDog.mixedVaccineDate,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildVaccinationCard({
    required String title,
    required String vaccineType,
    required String? photoUrl,
    required DateTime? date,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(WanMapSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? WanMapColors.backgroundDark : WanMapColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? WanMapColors.borderDark : WanMapColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: WanMapTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: WanMapSpacing.md),
          
          // 接種証明書の画像と編集ボタン
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 写真
              GestureDetector(
                onTap: photoUrl != null && photoUrl.isNotEmpty 
                    ? () => _showFullScreenImage(photoUrl) 
                    : null,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                    image: photoUrl != null && photoUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(photoUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: photoUrl == null || photoUrl.isEmpty
                      ? Icon(
                          Icons.image,
                          size: 32,
                          color: Colors.grey[600],
                        )
                      : null,
                ),
              ),
              const SizedBox(width: WanMapSpacing.sm),
              
              // 写真変更ボタン（小）
              IconButton(
                onPressed: _isUploading ? null : () => _uploadVaccinationPhoto(vaccineType),
                icon: _isUploading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.edit, size: 20),
                tooltip: '写真を変更',
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: WanMapSpacing.md),
          
          // 接種日（1行）
          Row(
            children: [
              Text(
                '接種日: ',
                style: WanMapTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Expanded(
                child: Text(
                  date != null 
                      ? DateFormat('yyyy年MM月dd日').format(date)
                      : '未設定',
                  style: WanMapTypography.bodyMedium,
                ),
              ),
              // 日付変更ボタン（小）
              IconButton(
                onPressed: () => _updateVaccinationDate(vaccineType, date),
                icon: const Icon(Icons.calendar_today, size: 18),
                tooltip: '日付を変更',
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

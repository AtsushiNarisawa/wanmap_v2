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
          Row(
            children: [
              Icon(
                Icons.medical_services,
                color: WanMapColors.primary,
                size: 24,
              ),
              const SizedBox(width: WanMapSpacing.sm),
              Text(
                '予防接種情報',
                style: WanMapTypography.headlineSmall,
              ),
            ],
          ),
          const SizedBox(height: WanMapSpacing.md),
          Text(
            'ペット施設利用時に提示が必要な接種証明書を登録できます',
            style: WanMapTypography.bodySmall,
          ),
          const SizedBox(height: WanMapSpacing.lg),
          
          // 狂犬病ワクチン
          _buildVaccinationCard(
            title: '狂犬病ワクチン',
            vaccineType: 'rabies',
            photoUrl: widget.dog.rabiesVaccinePhotoUrl,
            date: widget.dog.rabiesVaccineDate,
            isDark: isDark,
          ),
          
          const SizedBox(height: WanMapSpacing.md),
          
          // 混合ワクチン
          _buildVaccinationCard(
            title: '混合ワクチン',
            vaccineType: 'mixed',
            photoUrl: widget.dog.mixedVaccinePhotoUrl,
            date: widget.dog.mixedVaccineDate,
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
          
          // 接種証明書写真
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '接種証明書',
                      style: WanMapTypography.bodyMedium,
                    ),
                    const SizedBox(height: WanMapSpacing.xs),
                    if (photoUrl != null && photoUrl.isNotEmpty)
                      GestureDetector(
                        onTap: () => _showFullScreenImage(photoUrl),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            photoUrl,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 120,
                                height: 120,
                                color: Colors.grey[300],
                                child: const Icon(Icons.error),
                              );
                            },
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.image,
                          size: 48,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: WanMapSpacing.md),
              ElevatedButton.icon(
                onPressed: _isUploading ? null : () => _uploadVaccinationPhoto(vaccineType),
                icon: _isUploading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file),
                label: Text(photoUrl != null ? '写真を変更' : '写真を追加'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: WanMapColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: WanMapSpacing.md),
          
          // 接種日
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '接種日',
                      style: WanMapTypography.bodyMedium,
                    ),
                    const SizedBox(height: WanMapSpacing.xs),
                    Text(
                      date != null 
                          ? DateFormat('yyyy年MM月dd日').format(date)
                          : '未設定',
                      style: WanMapTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _updateVaccinationDate(vaccineType, date),
                icon: const Icon(Icons.calendar_today),
                label: Text(date != null ? '日付を変更' : '日付を設定'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: WanMapColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

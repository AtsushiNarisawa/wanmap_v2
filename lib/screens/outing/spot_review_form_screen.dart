import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';
import '../../models/spot_review_model.dart';
import '../../providers/spot_review_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// スポット評価・レビュー投稿画面
class SpotReviewFormScreen extends ConsumerStatefulWidget {
  final String spotId;
  final String spotTitle; // ピンのタイトル（ヘッダーに表示）
  final SpotReviewModel? existingReview; // 編集モードの場合は既存レビュー

  const SpotReviewFormScreen({
    super.key,
    required this.spotId,
    required this.spotTitle,
    this.existingReview,
  });

  @override
  ConsumerState<SpotReviewFormScreen> createState() =>
      _SpotReviewFormScreenState();
}

class _SpotReviewFormScreenState extends ConsumerState<SpotReviewFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reviewTextController = TextEditingController();
  final _seasonalInfoController = TextEditingController();

  // 評価
  int _rating = 5;

  // 設備情報
  bool _hasWaterFountain = false;
  bool _hasDogRun = false;
  bool _hasShade = false;
  bool _hasToilet = false;
  bool _hasParking = false;
  bool _hasDogWasteBin = false;

  // 利用条件
  bool _leashRequired = true;
  bool _hasDogFriendlyCafe = false;
  String _dogSizeSuitable = 'all'; // 'small', 'medium', 'large', 'all'

  // 写真URL（今回は写真アップロード機能は省略、将来実装）
  List<String> _photoUrls = [];

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // 編集モードの場合は既存データをセット
    if (widget.existingReview != null) {
      final review = widget.existingReview!;
      _rating = review.rating;
      _reviewTextController.text = review.reviewText ?? '';
      _hasWaterFountain = review.hasWaterFountain;
      _hasDogRun = review.hasDogRun;
      _hasShade = review.hasShade;
      _hasToilet = review.hasToilet;
      _hasParking = review.hasParking;
      _hasDogWasteBin = review.hasDogWasteBin;
      _leashRequired = review.leashRequired;
      _hasDogFriendlyCafe = review.hasDogFriendlyCafe;
      _dogSizeSuitable = review.dogSizeSuitable ?? 'all';
      _seasonalInfoController.text = review.seasonalInfo ?? '';
      _photoUrls = review.photoUrls;
    }
  }

  @override
  void dispose() {
    _reviewTextController.dispose();
    _seasonalInfoController.dispose();
    super.dispose();
  }

  /// レビューを保存
  Future<void> _saveReview() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('ログインが必要です');
      }

      final reviewData = {
        'user_id': userId,
        'spot_id': widget.spotId,
        'rating': _rating,
        'review_text': _reviewTextController.text.trim().isEmpty
            ? null
            : _reviewTextController.text.trim(),
        'has_water_fountain': _hasWaterFountain,
        'has_dog_run': _hasDogRun,
        'has_shade': _hasShade,
        'has_toilet': _hasToilet,
        'has_parking': _hasParking,
        'has_dog_waste_bin': _hasDogWasteBin,
        'leash_required': _leashRequired,
        'has_dog_friendly_cafe': _hasDogFriendlyCafe,
        'dog_size_suitable': _dogSizeSuitable,
        'seasonal_info': _seasonalInfoController.text.trim().isEmpty
            ? null
            : _seasonalInfoController.text.trim(),
        'photo_urls': _photoUrls,
      };

      if (widget.existingReview != null) {
        // 更新
        await ref
            .read(spotReviewNotifierProvider.notifier)
            .updateReview(widget.existingReview!.id, reviewData);
      } else {
        // 新規作成
        await ref
            .read(spotReviewNotifierProvider.notifier)
            .createReview(reviewData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingReview != null
                  ? 'レビューを更新しました'
                  : 'レビューを投稿しました',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // 成功フラグを返す
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingReview != null ? 'レビューを編集' : 'レビューを書く',
        ),
        actions: [
          if (_isSubmitting)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveReview,
              child: const Text(
                '保存',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(WanMapSpacing.md),
          children: [
            // スポット名
            Text(
              widget.spotTitle,
              style: WanMapTypography.headlineMedium.copyWith(
                color: isDark
                    ? WanMapColors.textPrimaryDark
                    : WanMapColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: WanMapSpacing.lg),

            // 星評価セクション
            _buildRatingSection(isDark),
            const SizedBox(height: WanMapSpacing.xl),

            // レビューテキストセクション
            _buildReviewTextSection(isDark),
            const SizedBox(height: WanMapSpacing.xl),

            // 設備情報セクション
            _buildFacilitiesSection(isDark),
            const SizedBox(height: WanMapSpacing.xl),

            // 利用条件セクション
            _buildConditionsSection(isDark),
            const SizedBox(height: WanMapSpacing.xl),

            // 季節情報セクション
            _buildSeasonalInfoSection(isDark),
            const SizedBox(height: WanMapSpacing.xl),

            // 写真セクション（今回は省略）
            // TODO: 将来実装
          ],
        ),
      ),
    );
  }

  /// 星評価セクション
  Widget _buildRatingSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '総合評価',
          style: WanMapTypography.headlineSmall.copyWith(
            color: isDark
                ? WanMapColors.textPrimaryDark
                : WanMapColors.textPrimaryLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: WanMapSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starValue = index + 1;
            return IconButton(
              onPressed: () {
                setState(() {
                  _rating = starValue;
                });
              },
              icon: Icon(
                starValue <= _rating ? Icons.star : Icons.star_border,
                size: 48,
                color: starValue <= _rating ? Colors.amber : Colors.grey,
              ),
            );
          }),
        ),
        Center(
          child: Text(
            _getRatingText(_rating),
            style: WanMapTypography.bodyLarge.copyWith(
              color: isDark
                  ? WanMapColors.textSecondaryDark
                  : WanMapColors.textSecondaryLight,
            ),
          ),
        ),
      ],
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return '残念';
      case 2:
        return 'イマイチ';
      case 3:
        return '普通';
      case 4:
        return '良い';
      case 5:
        return '最高！';
      default:
        return '';
    }
  }

  /// レビューテキストセクション
  Widget _buildReviewTextSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'レビュー（任意）',
          style: WanMapTypography.headlineSmall.copyWith(
            color: isDark
                ? WanMapColors.textPrimaryDark
                : WanMapColors.textPrimaryLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: WanMapSpacing.sm),
        TextFormField(
          controller: _reviewTextController,
          maxLines: 5,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'このスポットの感想を教えてください...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
          ),
        ),
      ],
    );
  }

  /// 設備情報セクション
  Widget _buildFacilitiesSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '設備情報',
          style: WanMapTypography.headlineSmall.copyWith(
            color: isDark
                ? WanMapColors.textPrimaryDark
                : WanMapColors.textPrimaryLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: WanMapSpacing.sm),
        _buildCheckboxTile('水飲み場', Icons.water_drop, _hasWaterFountain,
            (value) {
          setState(() {
            _hasWaterFountain = value ?? false;
          });
        }, isDark),
        _buildCheckboxTile('ドッグラン', Icons.pets, _hasDogRun, (value) {
          setState(() {
            _hasDogRun = value ?? false;
          });
        }, isDark),
        _buildCheckboxTile('日陰', Icons.wb_sunny, _hasShade, (value) {
          setState(() {
            _hasShade = value ?? false;
          });
        }, isDark),
        _buildCheckboxTile('トイレ', Icons.wc, _hasToilet, (value) {
          setState(() {
            _hasToilet = value ?? false;
          });
        }, isDark),
        _buildCheckboxTile('駐車場', Icons.local_parking, _hasParking, (value) {
          setState(() {
            _hasParking = value ?? false;
          });
        }, isDark),
        _buildCheckboxTile(
            '犬用ゴミ箱', Icons.delete_outline, _hasDogWasteBin, (value) {
          setState(() {
            _hasDogWasteBin = value ?? false;
          });
        }, isDark),
      ],
    );
  }

  Widget _buildCheckboxTile(String title, IconData icon, bool value,
      Function(bool?) onChanged, bool isDark) {
    return CheckboxListTile(
      title: Row(
        children: [
          Icon(icon, size: 20, color: WanMapColors.accent),
          const SizedBox(width: WanMapSpacing.sm),
          Text(title),
        ],
      ),
      value: value,
      onChanged: onChanged,
      activeColor: WanMapColors.accent,
      tileColor: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  /// 利用条件セクション
  Widget _buildConditionsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '利用条件',
          style: WanMapTypography.headlineSmall.copyWith(
            color: isDark
                ? WanMapColors.textPrimaryDark
                : WanMapColors.textPrimaryLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: WanMapSpacing.sm),
        SwitchListTile(
          title: const Text('リード必須'),
          value: _leashRequired,
          onChanged: (value) {
            setState(() {
              _leashRequired = value;
            });
          },
          activeColor: WanMapColors.accent,
          tileColor: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: WanMapSpacing.sm),
        SwitchListTile(
          title: const Text('ドッグカフェあり'),
          value: _hasDogFriendlyCafe,
          onChanged: (value) {
            setState(() {
              _hasDogFriendlyCafe = value;
            });
          },
          activeColor: WanMapColors.accent,
          tileColor: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: WanMapSpacing.md),
        Text(
          '適した犬のサイズ',
          style: WanMapTypography.bodyMedium.copyWith(
            color: isDark
                ? WanMapColors.textPrimaryDark
                : WanMapColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: WanMapSpacing.sm),
        Wrap(
          spacing: WanMapSpacing.sm,
          children: [
            _buildDogSizeChip('すべて', 'all', isDark),
            _buildDogSizeChip('小型犬', 'small', isDark),
            _buildDogSizeChip('中型犬', 'medium', isDark),
            _buildDogSizeChip('大型犬', 'large', isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildDogSizeChip(String label, String value, bool isDark) {
    final isSelected = _dogSizeSuitable == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _dogSizeSuitable = value;
        });
      },
      selectedColor: WanMapColors.accent,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : null,
      ),
    );
  }

  /// 季節情報セクション
  Widget _buildSeasonalInfoSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '季節情報（任意）',
          style: WanMapTypography.headlineSmall.copyWith(
            color: isDark
                ? WanMapColors.textPrimaryDark
                : WanMapColors.textPrimaryLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: WanMapSpacing.sm),
        TextFormField(
          controller: _seasonalInfoController,
          maxLines: 3,
          maxLength: 200,
          decoration: InputDecoration(
            hintText: '春は桜が綺麗、夏は暑いので朝夕がおすすめ...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
          ),
        ),
      ],
    );
  }
}

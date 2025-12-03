import 'package:flutter/material.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';

/// WanMapエラー表示ウィジェット
/// 
/// エラー発生時のUI統一と再試行機能を提供
class WanMapErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final bool isNetworkError;
  final IconData? icon;

  const WanMapErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.isNetworkError = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(WanMapSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // アイコン
          Icon(
            icon ?? (isNetworkError ? Icons.wifi_off : Icons.error_outline),
            size: 64,
            color: isDark 
                ? WanMapColors.textSecondaryDark 
                : WanMapColors.textSecondaryLight,
          ),
          const SizedBox(height: WanMapSpacing.lg),
          
          // エラーメッセージ
          Text(
            message,
            style: WanMapTypography.bodyLarge.copyWith(
              color: isDark 
                  ? WanMapColors.textPrimaryDark 
                  : WanMapColors.textPrimaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          
          // ネットワークエラー時の補足
          if (isNetworkError) ...[
            const SizedBox(height: WanMapSpacing.sm),
            Text(
              'インターネット接続を確認してください',
              style: WanMapTypography.bodySmall.copyWith(
                color: isDark 
                    ? WanMapColors.textSecondaryDark 
                    : WanMapColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          
          // 再試行ボタン
          if (onRetry != null) ...[
            const SizedBox(height: WanMapSpacing.xl),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('再試行'),
              style: ElevatedButton.styleFrom(
                backgroundColor: WanMapColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: WanMapSpacing.xl,
                  vertical: WanMapSpacing.md,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// カード型エラーウィジェット（小さな領域用）
class WanMapErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const WanMapErrorCard({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(WanMapSpacing.lg),
      decoration: BoxDecoration(
        color: isDark 
            ? WanMapColors.surfaceDark.withOpacity(0.5)
            : WanMapColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark 
              ? WanMapColors.borderDark 
              : WanMapColors.borderLight,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 32,
            color: isDark 
                ? WanMapColors.textSecondaryDark 
                : WanMapColors.textSecondaryLight,
          ),
          const SizedBox(height: WanMapSpacing.sm),
          Text(
            message,
            style: WanMapTypography.bodyMedium.copyWith(
              color: isDark 
                  ? WanMapColors.textPrimaryDark 
                  : WanMapColors.textPrimaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: WanMapSpacing.md),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('再試行'),
              style: TextButton.styleFrom(
                foregroundColor: WanMapColors.accent,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 空状態ウィジェット
class WanMapEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;
  final Widget? illustration;

  const WanMapEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.onAction,
    this.actionLabel,
    this.illustration,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(WanMapSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // イラストまたはアイコン
          if (illustration != null)
            illustration!
          else
            Icon(
              icon,
              size: 80,
              color: isDark 
                  ? WanMapColors.textSecondaryDark.withOpacity(0.5)
                  : WanMapColors.textSecondaryLight.withOpacity(0.5),
            ),
          const SizedBox(height: WanMapSpacing.xl),
          
          // タイトル
          Text(
            title,
            style: WanMapTypography.headlineSmall.copyWith(
              color: isDark 
                  ? WanMapColors.textPrimaryDark 
                  : WanMapColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: WanMapSpacing.sm),
          
          // メッセージ
          Text(
            message,
            style: WanMapTypography.bodyMedium.copyWith(
              color: isDark 
                  ? WanMapColors.textSecondaryDark 
                  : WanMapColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          
          // アクションボタン
          if (onAction != null) ...[
            const SizedBox(height: WanMapSpacing.xxl),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add),
              label: Text(actionLabel ?? 'はじめる'),
              style: ElevatedButton.styleFrom(
                backgroundColor: WanMapColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: WanMapSpacing.xxl,
                  vertical: WanMapSpacing.md,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// カード型空状態ウィジェット
class WanMapEmptyCard extends StatelessWidget {
  final String message;
  final IconData icon;

  const WanMapEmptyCard({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(WanMapSpacing.xl),
      decoration: BoxDecoration(
        color: isDark 
            ? WanMapColors.surfaceDark.withOpacity(0.5)
            : WanMapColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark 
              ? WanMapColors.borderDark 
              : WanMapColors.borderLight,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 48,
            color: isDark 
                ? WanMapColors.textSecondaryDark.withOpacity(0.5)
                : WanMapColors.textSecondaryLight.withOpacity(0.5),
          ),
          const SizedBox(height: WanMapSpacing.md),
          Text(
            message,
            style: WanMapTypography.bodyMedium.copyWith(
              color: isDark 
                  ? WanMapColors.textSecondaryDark 
                  : WanMapColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

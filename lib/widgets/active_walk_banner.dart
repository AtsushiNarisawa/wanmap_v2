import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_colors.dart';
import '../config/app_spacing.dart';
import '../config/app_typography.dart';
import '../providers/gps_provider_riverpod.dart';
import '../models/walk_mode.dart';
import '../screens/daily/daily_walking_screen.dart';
import '../screens/outing/walking_screen.dart';
import '../models/official_route.dart';

/// 散歩中バナーウィジェット
/// 
/// 散歩記録中の場合、画面下部に固定表示され、
/// タップすると散歩中画面へ遷移する
class ActiveWalkBanner extends ConsumerWidget {
  /// 現在のルート情報（Outing Walkの場合のみ必要）
  final OfficialRoute? currentRoute;

  const ActiveWalkBanner({
    super.key,
    this.currentRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gpsState = ref.watch(gpsProviderRiverpod);

    // 散歩中でない場合は非表示
    if (!gpsState.isRecording) {
      return const SizedBox.shrink();
    }

    return Material(
      elevation: 8,
      color: AppColors.primary,
      child: InkWell(
        onTap: () => _navigateToWalkingScreen(context, gpsState),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                // アニメーション付きアイコン
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1000),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 1.0 + (value * 0.2),
                      child: Icon(
                        gpsState.isPaused 
                            ? Icons.pause_circle_filled
                            : Icons.directions_walk,
                        color: Colors.white,
                        size: 32,
                      ),
                    );
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
                // 散歩情報
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        gpsState.isPaused 
                            ? '散歩を一時停止中'
                            : '散歩を記録中',
                        style: AppTypography.labelMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            gpsState.formattedDistance,
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '•',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            gpsState.formattedDuration,
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '•',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            gpsState.walkMode == WalkMode.daily
                                ? '日常散歩'
                                : 'おでかけ散歩',
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // 矢印アイコン
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.8),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 散歩中画面へ遷移
  void _navigateToWalkingScreen(BuildContext context, GpsState gpsState) {
    if (gpsState.walkMode == WalkMode.daily) {
      // Daily Walk画面へ遷移
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const DailyWalkingScreen(),
        ),
      );
    } else {
      // Outing Walk画面へ遷移
      if (currentRoute != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => WalkingScreen(route: currentRoute!),
          ),
        );
      } else {
        // currentRouteがない場合は、エラーメッセージを表示
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('散歩中のルート情報が見つかりません'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

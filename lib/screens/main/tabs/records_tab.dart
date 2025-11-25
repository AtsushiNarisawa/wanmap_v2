import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/wanmap_colors.dart';
import '../../../config/wanmap_typography.dart';
import '../../../config/wanmap_spacing.dart';
import '../../../models/walk_history.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/badge_provider.dart';
import '../../../providers/user_statistics_provider.dart';
import '../../../providers/walk_history_provider.dart';
import '../../../services/photo_service.dart';
import '../../../widgets/walk_photo_grid.dart';
import '../../daily/daily_walking_screen.dart';
import '../../history/walk_history_screen.dart';

/// RecordsTab - 日常の散歩記録+統計+バッジ統合
/// 
/// 構成:
/// 1. 今日の統計カード（散歩開始ボタン）
/// 2. 総合統計（4つ）
/// 3. バッジコレクション（サマリー）
/// 4. 最近の散歩
class RecordsTab extends ConsumerWidget {
  const RecordsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userId = ref.watch(currentUserIdProvider);

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('散歩記録')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.directions_walk, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text('ログインして散歩記録を確認しましょう', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }

    final statisticsAsync = ref.watch(userStatisticsProvider(userId));
    final badgeStatsAsync = ref.watch(badgeStatisticsProvider(userId));

    return Scaffold(
      backgroundColor: isDark ? WanMapColors.backgroundDark : WanMapColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '散歩記録',
          style: WanMapTypography.headlineMedium.copyWith(
            color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(WanMapSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 今日の統計カード
              _buildTodayStatsCard(context, isDark),
              
              const SizedBox(height: WanMapSpacing.xxxl),
              
              // 総合統計
              statisticsAsync.when(
                data: (stats) => _buildOverallStats(context, isDark, stats),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => _buildEmptyCard(isDark, '統計の読み込みに失敗しました'),
              ),
              
              const SizedBox(height: WanMapSpacing.xxxl),
              
              // バッジコレクション
              badgeStatsAsync.when(
                data: (badgeStats) => _buildBadgeSummary(context, isDark, badgeStats),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              ),
              
              const SizedBox(height: WanMapSpacing.xxxl),
              
              // 最近の散歩
              _buildRecentWalks(context, isDark),
            ],
          ),
        ),
      ),
    );
  }

  /// 今日の統計カード
  Widget _buildTodayStatsCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(WanMapSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [WanMapColors.accent, WanMapColors.accent.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: WanMapColors.accent.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.today, color: Colors.white, size: 28),
              const SizedBox(width: WanMapSpacing.sm),
              Text(
                '今日の統計',
                style: WanMapTypography.headlineSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: WanMapSpacing.md),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('0回', style: WanMapTypography.headlineMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text('散歩回数', style: WanMapTypography.caption.copyWith(color: Colors.white.withOpacity(0.9))),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('0.0km', style: WanMapTypography.headlineMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text('距離', style: WanMapTypography.caption.copyWith(color: Colors.white.withOpacity(0.9))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: WanMapSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyWalkingScreen())),
              icon: const Icon(Icons.play_circle_filled, size: 24),
              label: const Text('散歩を開始', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: WanMapColors.accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 総合統計
  Widget _buildOverallStats(BuildContext context, bool isDark, dynamic stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '総合統計',
          style: WanMapTypography.headlineSmall.copyWith(
            color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: WanMapSpacing.md),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: WanMapSpacing.md,
          mainAxisSpacing: WanMapSpacing.md,
          childAspectRatio: 1.3,
          children: [
            _StatCard(icon: Icons.star, label: 'レベル', value: 'Lv.${stats.userLevel}', color: Colors.amber, isDark: isDark),
            _StatCard(icon: Icons.route, label: '総距離', value: stats.formattedTotalDistance, color: Colors.blue, isDark: isDark),
            _StatCard(icon: Icons.directions_walk, label: '総散歩', value: '${stats.totalWalks}回', color: Colors.green, isDark: isDark),
            _StatCard(icon: Icons.explore, label: 'エリア', value: '${stats.areasVisited}箇所', color: Colors.orange, isDark: isDark),
          ],
        ),
      ],
    );
  }

  /// バッジコレクション（サマリー）
  Widget _buildBadgeSummary(BuildContext context, bool isDark, dynamic badgeStats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'バッジコレクション',
              style: WanMapTypography.headlineSmall.copyWith(
                color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${badgeStats.unlockedBadges}/17',
              style: WanMapTypography.bodyLarge.copyWith(
                color: WanMapColors.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: WanMapSpacing.md),
        Container(
          padding: const EdgeInsets.all(WanMapSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Icon(badgeStats.unlockedBadges > 0 ? Icons.emoji_events : Icons.emoji_events_outlined, size: 40, color: WanMapColors.accent),
                  Icon(badgeStats.unlockedBadges > 1 ? Icons.emoji_events : Icons.emoji_events_outlined, size: 40, color: Colors.grey),
                  Icon(badgeStats.unlockedBadges > 2 ? Icons.emoji_events : Icons.emoji_events_outlined, size: 40, color: Colors.grey),
                  Icon(badgeStats.unlockedBadges > 3 ? Icons.emoji_events : Icons.emoji_events_outlined, size: 40, color: Colors.grey),
                  Icon(badgeStats.unlockedBadges > 4 ? Icons.emoji_events : Icons.emoji_events_outlined, size: 40, color: Colors.grey),
                  Icon(badgeStats.unlockedBadges > 5 ? Icons.emoji_events : Icons.emoji_events_outlined, size: 40, color: Colors.grey),
                ],
              ),
              const SizedBox(height: WanMapSpacing.md),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('バッジ一覧は準備中です')),
                  );
                },
                child: const Text('すべて見る'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 最近の散歩
  Widget _buildRecentWalks(BuildContext context, bool isDark) {
    return Consumer(
      builder: (context, ref, child) {
        final userId = ref.watch(currentUserIdProvider);
        if (userId == null) {
          return _buildEmptyCard(isDark, 'ログインして散歩記録を確認しましょう');
        }

        final historyAsync = ref.watch(allWalkHistoryProvider(AllHistoryParams(userId: userId, limit: 5)));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '最近の散歩',
                  style: WanMapTypography.headlineSmall.copyWith(
                    color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalkHistoryScreen())),
                  child: const Text('すべて見る'),
                ),
              ],
            ),
            const SizedBox(height: WanMapSpacing.md),
            historyAsync.when(
              data: (walks) {
                if (walks.isEmpty) {
                  return _buildEmptyCard(isDark, 'まだ散歩の記録がありません');
                }
                return Column(
                  children: walks.map((walk) => _buildWalkHistoryCard(context, isDark, walk, userId)).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildEmptyCard(isDark, '散歩記録の読み込みに失敗しました'),
            ),
          ],
        );
      },
    );
  }

  /// 散歩履歴カード（写真表示機能付き - Phase 3拡張）
  Widget _buildWalkHistoryCard(BuildContext context, bool isDark, WalkHistoryItem walk, String userId) {
    // 散歩タイプを判定
    final isOuting = walk.type == WalkHistoryType.outing;
    final walkId = walk.walkId;

    return Card(
      margin: const EdgeInsets.only(bottom: WanMapSpacing.md),
      color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(WanMapSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー（タイプアイコン + タイトル）
            Row(
              children: [
                Icon(
                  isOuting ? Icons.explore : Icons.directions_walk,
                  color: isOuting ? Colors.orange : WanMapColors.accent,
                  size: 24,
                ),
                const SizedBox(width: WanMapSpacing.sm),
                Expanded(
                  child: Text(
                    isOuting ? (walk.routeName ?? 'おでかけ散歩') : '日常散歩',
                    style: WanMapTypography.bodyLarge.copyWith(
                      color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: WanMapSpacing.sm),
            
            // 統計情報
            Row(
              children: [
                Icon(Icons.straighten, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${(walk.distanceMeters / 1000).toStringAsFixed(2)} km',
                  style: WanMapTypography.bodySmall.copyWith(
                    color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(width: WanMapSpacing.md),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${(walk.durationSeconds / 60).ceil()} 分',
                  style: WanMapTypography.bodySmall.copyWith(
                    color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(width: WanMapSpacing.md),
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _formatDate(walk.walkedAt),
                  style: WanMapTypography.bodySmall.copyWith(
                    color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                  ),
                ),
              ],
            ),

            // 写真グリッド（Phase 3拡張機能）
            FutureBuilder<List<WalkPhoto>>(
              future: PhotoService().getWalkPhotos(walkId),
              builder: (context, snapshot) {
                print('📸 Records Tab - Photo FutureBuilder:');
                print('   walkId: $walkId');
                print('   connectionState: ${snapshot.connectionState}');
                print('   hasData: ${snapshot.hasData}');
                print('   hasError: ${snapshot.hasError}');
                if (snapshot.hasError) {
                  print('   ❌ Error: ${snapshot.error}');
                }
                if (snapshot.hasData) {
                  print('   📊 Photos count: ${snapshot.data!.length}');
                  if (snapshot.data!.isNotEmpty) {
                    print('   ✅ Showing photo grid');
                    return Container(
                      color: Colors.pink.withOpacity(0.3), // デバッグ用：ピンク背景
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('📸 写真グリッド（デバッグ）', style: TextStyle(fontSize: 10)),
                          const SizedBox(height: WanMapSpacing.md),
                          WalkPhotoGrid(photos: snapshot.data!, maxPhotosToShow: 3),
                        ],
                      ),
                    );
                  } else {
                    print('   ⚠️ No photos found');
                  }
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 日付フォーマット
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return '今日';
    } else if (diff.inDays == 1) {
      return '昨日';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}日前';
    } else {
      return '${date.month}/${date.day}';
    }
  }

  Widget _buildEmptyCard(bool isDark, String message) {
    return Container(
      padding: const EdgeInsets.all(WanMapSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(child: Text(message, style: WanMapTypography.bodyMedium.copyWith(color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight))),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatCard({required this.icon, required this.label, required this.value, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(WanMapSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: WanMapSpacing.sm),
          Text(value, style: WanMapTypography.headlineSmall.copyWith(color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight, fontWeight: FontWeight.bold)),
          const SizedBox(height: WanMapSpacing.xs),
          Text(label, style: WanMapTypography.caption.copyWith(color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight)),
        ],
      ),
    );
  }
}

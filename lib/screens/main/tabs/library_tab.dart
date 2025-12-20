import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/wanmap_colors.dart';
import '../../../config/wanmap_typography.dart';
import '../../../config/wanmap_spacing.dart';
import '../../../models/walk_history.dart';
import '../../../models/route_pin.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_statistics_provider.dart';
import '../../../providers/walk_history_provider.dart';
import '../../../providers/route_pin_provider.dart';
import '../../../widgets/shimmer/wanmap_shimmer.dart';
import '../../history/walk_history_screen.dart';
import '../../history/outing_walk_detail_screen.dart';
import '../../outing/pin_detail_screen.dart';

/// LibraryTab - 愛犬との散歩の思い出アルバム
/// 
/// 構成:
/// 1. シンプルヘッダー（優しいメッセージ）
/// 2. 今月の散歩回数（控えめ）
/// 3. タブ切り替え（タイムライン/アルバム/お出かけ/日常/ピン投稿）
/// 4. 思い出のタイムライン
/// 5. 写真アルバム
/// 6. ピン投稿履歴
class LibraryTab extends ConsumerStatefulWidget {
  const LibraryTab({super.key});

  @override
  ConsumerState<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends ConsumerState<LibraryTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this); // 5タブに変更
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userId = ref.watch(currentUserIdProvider);

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('ライブラリ')),
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

    return Scaffold(
      backgroundColor: isDark ? WanMapColors.backgroundDark : WanMapColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.collections, color: WanMapColors.accent, size: 28),
            const SizedBox(width: 8),
            Text(
              'ライブラリ',
              style: WanMapTypography.headlineMedium.copyWith(
                color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 今月の散歩回数（控えめ）
          statisticsAsync.when(
            data: (stats) => _buildMonthlyWalkCount(stats, isDark),
            loading: () => const SizedBox(height: 40),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // タブバー
          Container(
            color: isDark ? WanMapColors.backgroundDark : WanMapColors.backgroundLight,
            child: TabBar(
              controller: _tabController,
              labelColor: WanMapColors.accent,
              unselectedLabelColor: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
              indicatorColor: WanMapColors.accent,
              labelStyle: WanMapTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
              unselectedLabelStyle: WanMapTypography.bodySmall,
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              isScrollable: false,
              tabs: const [
                Tab(icon: Icon(Icons.timelapse, size: 18), text: 'すべて'),
                Tab(icon: Icon(Icons.photo_library, size: 18), text: 'アルバム'),
                Tab(icon: Icon(Icons.explore, size: 18), text: 'お出かけ'),
                Tab(icon: Icon(Icons.directions_walk, size: 18), text: '日常'),
                Tab(icon: Icon(Icons.push_pin, size: 18), text: 'ピン'),
              ],
            ),
          ),

          // タブビュー
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildWalkList(null, isDark), // タイムライン（全て）
                _buildAlbumTab(isDark), // アルバム
                _buildWalkList(WalkHistoryType.outing, isDark), // お出かけ
                _buildWalkList(WalkHistoryType.daily, isDark), // 日常
                _buildPinHistoryTab(isDark), // ピン投稿履歴
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 今月の散歩回数（実データ）
  Widget _buildMonthlyWalkCount(dynamic stats, bool isDark) {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const SizedBox.shrink();

    final outingAsync = ref.watch(outingWalkHistoryProvider(OutingHistoryParams(userId: userId)));
    final dailyAsync = ref.watch(dailyWalkHistoryProvider(DailyHistoryParams(userId: userId)));

    // ローディング状態の確認
    if (outingAsync.isLoading || dailyAsync.isLoading) {
      print('📊 月間統計: ローディング中...');
      return Container(
        height: 80,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    // エラー状態の確認
    if (outingAsync.hasError || dailyAsync.hasError) {
      print('❌ 月間統計: エラー発生 - outing: ${outingAsync.hasError}, daily: ${dailyAsync.hasError}');
      return const SizedBox.shrink();
    }

    // データがある場合のみ表示
    final outingWalks = outingAsync.value ?? [];
    final dailyWalks = dailyAsync.value ?? [];

    // 今月の散歩を集計
    final now = DateTime.now();
    final thisMonthOuting = outingWalks.where((w) => 
      w.walkedAt.year == now.year && w.walkedAt.month == now.month
    ).length;
    final thisMonthDaily = dailyWalks.where((w) => 
      w.walkedAt.year == now.year && w.walkedAt.month == now.month
    ).length;
    final monthlyWalkCount = thisMonthOuting + thisMonthDaily;

    // 今月の総距離を計算
    final thisMonthDistance = outingWalks
        .where((w) => w.walkedAt.year == now.year && w.walkedAt.month == now.month)
        .fold<double>(0, (sum, w) => sum + w.distanceMeters) +
      dailyWalks
        .where((w) => w.walkedAt.year == now.year && w.walkedAt.month == now.month)
        .fold<double>(0, (sum, w) => sum + w.distanceMeters);
    
    final formattedDistance = thisMonthDistance < 1000
        ? '${thisMonthDistance.toStringAsFixed(0)}m'
        : '${(thisMonthDistance / 1000).toStringAsFixed(1)}km';

    // デバッグログ
    print('📊 月間統計: 今月の散歩回数=$monthlyWalkCount回, 総距離=$formattedDistance');
    print('📊 お出かけ散歩=$thisMonthOuting回, 日常散歩=$thisMonthDaily回');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg, vertical: WanMapSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            WanMapColors.accent.withOpacity(0.1),
            WanMapColors.accent.withOpacity(0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: isDark ? WanMapColors.borderDark : WanMapColors.borderLight,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: WanMapColors.accent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calendar_today,
              size: 20,
              color: WanMapColors.accent,
            ),
          ),
          const SizedBox(width: WanMapSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '今月の記録',
                  style: WanMapTypography.caption.copyWith(
                    color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '$monthlyWalkCount回',
                      style: WanMapTypography.titleMedium.copyWith(
                        color: WanMapColors.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: WanMapSpacing.sm),
                    Text(
                      '・',
                      style: WanMapTypography.bodyMedium.copyWith(
                        color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(width: WanMapSpacing.xs),
                    Text(
                      formattedDistance,
                      style: WanMapTypography.bodyMedium.copyWith(
                        color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// アルバムタブ（写真グリッド）
  Widget _buildAlbumTab(bool isDark) {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const SizedBox.shrink();

    final outingAsync = ref.watch(outingWalkHistoryProvider(OutingHistoryParams(userId: userId)));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(outingWalkHistoryProvider(OutingHistoryParams(userId: userId)));
      },
      child: outingAsync.when(
        data: (outingWalks) {
          // 全ての写真を収集
          final allPhotos = <Map<String, dynamic>>[];
          for (var walk in outingWalks) {
            for (var photoUrl in walk.photoUrls) {
              allPhotos.add({
                'url': photoUrl,
                'walk': walk,
              });
            }
          }

          if (allPhotos.isEmpty) {
            return _buildEmptyAlbumState(isDark);
          }

          return GridView.builder(
            padding: const EdgeInsets.all(4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: allPhotos.length,
            itemBuilder: (context, index) {
              final photo = allPhotos[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OutingWalkDetailScreen(
                        history: photo['walk'] as OutingWalkHistory,
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    photo['url'] as String,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: isDark ? WanMapColors.backgroundDark : WanMapColors.backgroundLight,
                        child: Icon(
                          Icons.broken_image,
                          color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildEmptyAlbumState(isDark),
      ),
    );
  }

  /// ピン投稿履歴タブ
  Widget _buildPinHistoryTab(bool isDark) {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const SizedBox.shrink();

    final pinsAsync = ref.watch(userPinsProvider(userId));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(userPinsProvider(userId));
      },
      child: pinsAsync.when(
        data: (pins) {
          if (pins.isEmpty) {
            return _buildEmptyPinHistoryState(isDark);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(WanMapSpacing.lg),
            itemCount: pins.length,
            itemBuilder: (context, index) {
              final pin = pins[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: WanMapSpacing.md),
                child: _PinHistoryCard(
                  pin: pin,
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PinDetailScreen(pinId: pin.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildEmptyPinHistoryState(isDark),
      ),
    );
  }

  /// 散歩リスト
  Widget _buildWalkList(WalkHistoryType? filterType, bool isDark) {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const SizedBox.shrink();

    final outingAsync = ref.watch(outingWalkHistoryProvider(OutingHistoryParams(userId: userId)));
    final dailyAsync = ref.watch(dailyWalkHistoryProvider(DailyHistoryParams(userId: userId)));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(outingWalkHistoryProvider(OutingHistoryParams(userId: userId)));
        ref.invalidate(dailyWalkHistoryProvider(DailyHistoryParams(userId: userId)));
      },
      child: outingAsync.when(
        data: (outingWalks) => dailyAsync.when(
          data: (dailyWalks) {
            // フィルタリング
            List<WalkHistoryItem> walks = [];
            if (filterType == null) {
              // 全て：両方の型を統合
              walks = [
                ...outingWalks.map((w) => WalkHistoryItem.fromOuting(w)),
                ...dailyWalks.map((w) => WalkHistoryItem.fromDaily(w)),
              ];
            } else if (filterType == WalkHistoryType.outing) {
              walks = outingWalks.map((w) => WalkHistoryItem.fromOuting(w)).toList();
            } else {
              walks = dailyWalks.map((w) => WalkHistoryItem.fromDaily(w)).toList();
            }

            // 日時でソート
            walks.sort((a, b) => b.walkedAt.compareTo(a.walkedAt));

            if (walks.isEmpty) {
              return _buildEmptyState(filterType, isDark);
            }

            return ListView.builder(
              padding: const EdgeInsets.all(WanMapSpacing.lg),
              itemCount: walks.length,
              itemBuilder: (context, index) {
                final walk = walks[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: WanMapSpacing.md),
                  child: _WalkCard(
                    walk: walk,
                    isDark: isDark,
                    onTap: () {
                      if (walk.type == WalkHistoryType.outing) {
                        // お出かけ散歩詳細画面へ
                        // WalkHistoryItemからOutingWalkHistoryを再構成
                        final outingHistory = OutingWalkHistory(
                          walkId: walk.walkId,
                          routeId: walk.routeId ?? '',
                          routeName: walk.routeName ?? '',
                          areaName: walk.areaName ?? '',
                          walkedAt: walk.walkedAt,
                          distanceMeters: walk.distanceMeters,
                          durationSeconds: walk.durationSeconds,
                          photoCount: walk.photoCount ?? 0,
                          pinCount: walk.pinCount ?? 0,
                          photoUrls: walk.photoUrls ?? [],
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OutingWalkDetailScreen(history: outingHistory),
                          ),
                        );
                      } else {
                        // TODO: 日常散歩詳細画面へ遷移
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('日常散歩詳細画面は準備中です')),
                        );
                      }
                    },
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _buildEmptyState(filterType, isDark),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildEmptyState(filterType, isDark),
      ),
    );
  }

  /// 空状態
  Widget _buildEmptyState(WalkHistoryType? filterType, bool isDark) {
    String message;
    if (filterType == WalkHistoryType.outing) {
      message = 'お出かけ散歩の記録がありません\n公式ルートを歩いて思い出を残しましょう';
    } else if (filterType == WalkHistoryType.daily) {
      message = '日常散歩の記録がありません\nいつもの散歩を記録してみましょう';
    } else {
      message = '散歩の記録がありません\nさっそく散歩に出かけましょう！';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(WanMapSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_walk,
              size: 64,
              color: isDark
                  ? WanMapColors.textSecondaryDark.withOpacity(0.5)
                  : WanMapColors.textSecondaryLight.withOpacity(0.5),
            ),
            const SizedBox(height: WanMapSpacing.lg),
            Text(
              message,
              style: WanMapTypography.bodyMedium.copyWith(
                color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// アルバムが空の状態
  Widget _buildEmptyAlbumState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(WanMapSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: isDark
                  ? WanMapColors.textSecondaryDark.withOpacity(0.5)
                  : WanMapColors.textSecondaryLight.withOpacity(0.5),
            ),
            const SizedBox(height: WanMapSpacing.lg),
            Text(
              'まだ写真がありません\nお出かけ散歩で写真を撮って\n思い出を残しましょう！',
              style: WanMapTypography.bodyMedium.copyWith(
                color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// ピン投稿履歴が空の状態
  Widget _buildEmptyPinHistoryState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(WanMapSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.push_pin_outlined,
              size: 64,
              color: isDark
                  ? WanMapColors.textSecondaryDark.withOpacity(0.5)
                  : WanMapColors.textSecondaryLight.withOpacity(0.5),
            ),
            const SizedBox(height: WanMapSpacing.lg),
            Text(
              'まだピン投稿がありません\n散歩中に素敵な場所を見つけたら\nピンを立ててみましょう！',
              style: WanMapTypography.bodyMedium.copyWith(
                color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }


}

/// 散歩カード
class _WalkCard extends StatelessWidget {
  final WalkHistoryItem walk;
  final bool isDark;
  final VoidCallback onTap;

  const _WalkCard({
    required this.walk,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOuting = walk.type == WalkHistoryType.outing;
    // WalkHistoryItemからoutingデータを直接使用

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 写真（お出かけ散歩のみ）
            if (isOuting && walk.photoUrls != null && walk.photoUrls!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: SizedBox(
                  height: 220, // 200 → 220に拡大
                  width: double.infinity,
                  child: Image.network(
                    walk.photoUrls!.first, // 最初の写真を全幅表示
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: isDark ? WanMapColors.backgroundDark : WanMapColors.backgroundLight,
                      child: const Icon(Icons.broken_image, size: 48),
                    ),
                  ),
                ),
              ),

            // カード情報
            Padding(
              padding: const EdgeInsets.all(WanMapSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // タイトル
                  Row(
                    children: [
                      // 絵文字アイコン
                      Text(
                        _getWalkEmoji(walk, isOuting),
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: WanMapSpacing.sm),
                      Expanded(
                        child: Text(
                          isOuting ? (walk.routeName ?? 'お出かけ散歩') : _formatDateTimeTitle(walk.walkedAt),
                          style: WanMapTypography.bodyLarge.copyWith(
                            color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: WanMapSpacing.sm),

                  // サブ情報
                  Row(
                    children: [
                      if (isOuting && walk.areaName != null) ...[
                        Icon(Icons.location_on, size: 14, color: WanMapColors.accent),
                        const SizedBox(width: WanMapSpacing.xs),
                        Text(
                          walk.areaName!,
                          style: WanMapTypography.bodySmall.copyWith(
                            color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(width: WanMapSpacing.md),
                      ],
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                      ),
                      const SizedBox(width: WanMapSpacing.xs),
                      Text(
                        _formatDate(walk.walkedAt),
                        style: WanMapTypography.bodySmall.copyWith(
                          color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: WanMapSpacing.sm),

                  // 統計
                  Row(
                    children: [
                      _StatChip(
                        icon: Icons.straighten,
                        label: walk.formattedDistance,
                        isDark: isDark,
                      ),
                      const SizedBox(width: WanMapSpacing.sm),
                      _StatChip(
                        icon: Icons.access_time,
                        label: walk.formattedDuration,
                        isDark: isDark,
                      ),
                      if (isOuting && walk.pinCount != null && walk.pinCount! > 0) ...[
                        const SizedBox(width: WanMapSpacing.sm),
                        _StatChip(
                          icon: Icons.push_pin,
                          label: '${walk.pinCount}個',
                          isDark: isDark,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTimeTitle(DateTime date) {
    final hour = date.hour;
    if (hour < 12) {
      return '朝の散歩';
    } else if (hour < 17) {
      return '午後の散歩';
    } else {
      return '夕方の散歩';
    }
  }

  String _getWalkEmoji(WalkHistoryItem walk, bool isOuting) {
    if (isOuting) {
      // エリア名から絵文字を推測
      final areaName = walk.areaName ?? '';
      if (areaName.contains('箱根')) return '🏔️';
      if (areaName.contains('鎌倉')) return '🏯';
      if (areaName.contains('横浜')) return '🏙️';
      if (areaName.contains('湖') || areaName.contains('海')) return '🌊';
      return '🗺️'; // デフォルト
    } else {
      // 時間帯から絵文字を選択
      final hour = walk.walkedAt.hour;
      if (hour < 12) return '🌅'; // 朝
      if (hour < 17) return '☀️'; // 午後
      return '🌆'; // 夕方
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;

    if (diff == 0) {
      return '今日';
    } else if (diff == 1) {
      return '昨日';
    } else if (diff < 7) {
      return '$diff日前';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}

/// 統計チップ
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: WanMapSpacing.sm,
        vertical: WanMapSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: WanMapColors.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: WanMapColors.accent),
          const SizedBox(width: WanMapSpacing.xs),
          Text(
            label,
            style: WanMapTypography.caption.copyWith(
              color: WanMapColors.accent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// ピン投稿履歴カード
class _PinHistoryCard extends StatelessWidget {
  final RoutePin pin;
  final bool isDark;
  final VoidCallback onTap;

  const _PinHistoryCard({
    required this.pin,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? WanMapColors.cardDark : WanMapColors.cardLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 写真（あれば）
            if (pin.hasPhotos)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: SizedBox(
                  height: 220, // 200 → 220に拡大
                  width: double.infinity,
                  child: Image.network(
                    pin.photoUrls.first, // 最初の写真を全幅表示
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: isDark ? WanMapColors.backgroundDark : WanMapColors.backgroundLight,
                      child: const Icon(Icons.broken_image, size: 48),
                    ),
                  ),
                ),
              ),

            // ピン情報
            Padding(
              padding: const EdgeInsets.all(WanMapSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ピンタイプバッジ + タイトル
                  Row(
                    children: [
                      _buildPinTypeBadge(),
                      const SizedBox(width: WanMapSpacing.sm),
                      Expanded(
                        child: Text(
                          pin.title,
                          style: WanMapTypography.bodyLarge.copyWith(
                            color: isDark ? WanMapColors.textPrimaryDark : WanMapColors.textPrimaryLight,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // コメント
                  if (pin.comment.isNotEmpty) ...[
                    const SizedBox(height: WanMapSpacing.sm),
                    Text(
                      pin.comment,
                      style: WanMapTypography.bodyMedium.copyWith(
                        color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: WanMapSpacing.sm),

                  // 投稿時刻 + いいね数
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                      ),
                      const SizedBox(width: WanMapSpacing.xs),
                      Text(
                        pin.relativeTime,
                        style: WanMapTypography.caption.copyWith(
                          color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.favorite_border,
                        size: 16,
                        color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                      ),
                      const SizedBox(width: WanMapSpacing.xs),
                      Text(
                        '${pin.likesCount}',
                        style: WanMapTypography.caption.copyWith(
                          color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(width: WanMapSpacing.md),
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 16,
                        color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                      ),
                      const SizedBox(width: WanMapSpacing.xs),
                      Text(
                        '${pin.commentsCount}',
                        style: WanMapTypography.caption.copyWith(
                          color: isDark ? WanMapColors.textSecondaryDark : WanMapColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ピンタイプバッジ
  Widget _buildPinTypeBadge() {
    Color badgeColor;
    IconData badgeIcon;

    switch (pin.pinType) {
      case PinType.scenery:
        badgeColor = Colors.blue;
        badgeIcon = Icons.landscape;
        break;
      case PinType.shop:
        badgeColor = Colors.orange;
        badgeIcon = Icons.store;
        break;
      case PinType.encounter:
        badgeColor = Colors.green;
        badgeIcon = Icons.pets;
        break;
      case PinType.other:
        badgeColor = Colors.grey;
        badgeIcon = Icons.more_horiz;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: WanMapSpacing.sm,
        vertical: WanMapSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 14, color: badgeColor),
          const SizedBox(width: WanMapSpacing.xs),
          Text(
            pin.pinType.label,
            style: WanMapTypography.caption.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

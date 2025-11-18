import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';
import '../../widgets/wanmap_widgets.dart';
import '../map/map_screen.dart';
import '../routes/routes_list_screen.dart';
import '../routes/public_routes_screen.dart';
import '../routes/favorites_screen.dart';
import '../profile/profile_screen.dart';

/// ホーム画面 (Nike Run Club風リデザイン)
/// 
/// 主な改善点:
/// - ヒーローエリアに大きな統計表示
/// - グラデーション背景
/// - 大きく目立つ「お散歩を開始」ボタン
/// - カード型のクイックアクション
/// - おすすめルートセクション
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark 
          ? WanMapColors.backgroundDark 
          : WanMapColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // ヘッダー
          SliverAppBar(
            floating: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Row(
              children: [
                Icon(
                  Icons.pets,
                  color: WanMapColors.accent,
                  size: 28,
                ),
                const SizedBox(width: WanMapSpacing.sm),
                Text(
                  'WanMap',
                  style: WanMapTypography.headlineMedium.copyWith(
                    color: isDark 
                        ? WanMapColors.textPrimaryDark 
                        : WanMapColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.person),
                tooltip: 'プロフィール',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          // コンテンツ
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ヒーローセクション
                _buildHeroSection(context, user),
                
                const SizedBox(height: WanMapSpacing.xl),
                
                // クイックアクション
                _buildQuickActions(context),
                
                const SizedBox(height: WanMapSpacing.xxxl),
                
                // 今日の統計
                _buildTodayStats(context),
                
                const SizedBox(height: WanMapSpacing.xxxl),
                
                // おすすめルート
                _buildRecommendedRoutes(context),
                
                const SizedBox(height: WanMapSpacing.xxxl),
                
                // 最近のお散歩
                _buildRecentWalks(context),
                
                const SizedBox(height: WanMapSpacing.xxxl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ヒーローセクション
  Widget _buildHeroSection(BuildContext context, User? user) {
    return Container(
      decoration: BoxDecoration(
        gradient: WanMapColors.primaryGradient,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(WanMapSpacing.radiusXXL),
        ),
      ),
      padding: const EdgeInsets.all(WanMapSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 挨拶
          Text(
            'おはよう！',
            style: WanMapTypography.headlineLarge.copyWith(
              color: Colors.white,
            ),
          ),
          if (user?.email != null) ...[
            const SizedBox(height: WanMapSpacing.xs),
            Text(
              user!.email!.split('@')[0], // メールアドレスの@より前を表示
              style: WanMapTypography.bodyLarge.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
          
          const SizedBox(height: WanMapSpacing.xxxl),
          
          // 今日の距離（超大サイズ）
          WanMapHeroStat(
            value: '0.0',
            unit: 'km',
            label: '今日の距離',
            valueColor: Colors.white,
            unitColor: Colors.white.withOpacity(0.9),
            labelColor: Colors.white.withOpacity(0.8),
          ),
          
          const SizedBox(height: WanMapSpacing.xxxl),
          
          // 大きなスタートボタン
          WanMapButton(
            text: 'お散歩を開始',
            icon: Icons.directions_walk,
            size: WanMapButtonSize.large,
            fullWidth: true,
            variant: WanMapButtonVariant.secondary,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const MapScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// クイックアクション
  Widget _buildQuickActions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'クイックアクション',
            style: WanMapTypography.titleLarge.copyWith(
              color: isDark 
                  ? WanMapColors.textPrimaryDark 
                  : WanMapColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: WanMapSpacing.md),
          
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.list,
                  label: 'ルート一覧',
                  color: WanMapColors.secondary,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const RoutesListScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: WanMapSpacing.md),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.public,
                  label: '公開ルート',
                  color: WanMapColors.accent,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const PublicRoutesScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: WanMapSpacing.md),
          
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.favorite,
                  label: 'お気に入り',
                  color: WanMapColors.error,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const FavoritesScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: WanMapSpacing.md),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.map,
                  label: 'マップ',
                  color: WanMapColors.primary,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const MapScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 今日の統計
  Widget _buildTodayStats(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '今日の統計',
            style: WanMapTypography.titleLarge.copyWith(
              color: isDark 
                  ? WanMapColors.textPrimaryDark 
                  : WanMapColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: WanMapSpacing.md),
          
          WanMapStatsRow(
            stats: [
              WanMapStatItem(
                value: '0',
                unit: '回',
                label: 'お散歩',
                icon: Icons.directions_walk,
                color: WanMapColors.accent,
              ),
              WanMapStatItem(
                value: '0',
                unit: '分',
                label: '時間',
                icon: Icons.access_time,
                color: WanMapColors.secondary,
              ),
              WanMapStatItem(
                value: '0',
                unit: 'kcal',
                label: 'カロリー',
                icon: Icons.local_fire_department,
                color: WanMapColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// おすすめルート
  Widget _buildRecommendedRoutes(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'おすすめルート',
                style: WanMapTypography.titleLarge.copyWith(
                  color: isDark 
                      ? WanMapColors.textPrimaryDark 
                      : WanMapColors.textPrimaryLight,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PublicRoutesScreen(),
                    ),
                  );
                },
                child: Text(
                  'すべて見る',
                  style: WanMapTypography.labelLarge.copyWith(
                    color: WanMapColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: WanMapSpacing.md),
        
        SizedBox(
          height: 320,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
            itemCount: 3,
            separatorBuilder: (context, index) => 
                const SizedBox(width: WanMapSpacing.md),
            itemBuilder: (context, index) {
              return SizedBox(
                width: 280,
                child: WanMapRouteCard(
                  title: 'おすすめルート ${index + 1}',
                  subtitle: '近くの公園',
                  distance: 2.5 + index * 0.5,
                  duration: 30 + index * 10,
                  elevation: 50,
                  tags: ['公園', '平坦', '初心者向け'],
                  likeCount: 12 + index * 5,
                  isLiked: false,
                  onTap: () {
                    // TODO: ルート詳細画面へ遷移
                  },
                  onLike: () {
                    // TODO: いいね機能
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 最近のお散歩
  Widget _buildRecentWalks(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: WanMapSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '最近のお散歩',
                style: WanMapTypography.titleLarge.copyWith(
                  color: isDark 
                      ? WanMapColors.textPrimaryDark 
                      : WanMapColors.textPrimaryLight,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const RoutesListScreen(),
                    ),
                  );
                },
                child: Text(
                  'すべて見る',
                  style: WanMapTypography.labelLarge.copyWith(
                    color: WanMapColors.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: WanMapSpacing.md),
          
          // コンパクトなルートカードリスト
          ...List.generate(3, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: WanMapSpacing.md),
              child: WanMapRouteCardCompact(
                title: '最近の散歩 ${index + 1}',
                distance: 1.5 + index * 0.3,
                duration: 20 + index * 5,
                onTap: () {
                  // TODO: ルート詳細画面へ遷移
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// クイックアクションカード
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _QuickActionCard({
    Key? key,
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WanMapCard(
      onTap: onTap,
      size: WanMapCardSize.medium,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(WanMapSpacing.md),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 32,
              color: color,
            ),
          ),
          const SizedBox(height: WanMapSpacing.sm),
          Text(
            label,
            style: WanMapTypography.labelMedium.copyWith(
              color: isDark 
                  ? WanMapColors.textPrimaryDark 
                  : WanMapColors.textPrimaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

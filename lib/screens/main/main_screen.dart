import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/wanmap_colors.dart';
import '../../config/wanmap_typography.dart';
import '../../config/wanmap_spacing.dart';
import '../../providers/active_walk_provider.dart';
import '../../providers/gps_provider_riverpod.dart';
import '../../models/walk_mode.dart';
import 'tabs/home_tab.dart';
import 'tabs/map_tab.dart';
import 'tabs/profile_tab.dart';
import '../daily/daily_walk_landing_screen.dart';
import '../daily/daily_walking_screen.dart';
import '../outing/walking_screen.dart';

/// MainScreen - ビジュアル重視の新UI（BottomNavigationBar採用）
/// 
/// アプリの本来の目的を重視:
/// PRIMARY: おでかけ散歩 - 公式ルート、エリア、コミュニティ
/// SECONDARY: 日常の散歩 - プライベート記録
/// 
/// 4つのタブ:
/// 1. ホーム - ビジュアル重視（マップ、最新ピン、人気ルート）
/// 2. ルート - お出かけ散歩のマップ機能
/// 3. クイック記録 - 日常の散歩を始める・履歴を見る
/// 4. プロフィール - アカウント管理
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;

  // タブページのリスト
  static const List<Widget> _pages = [
    HomeTab(),
    MapTab(),
    DailyWalkLandingScreen(),
    ProfileTab(),
  ];

  // タブ切り替え
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeWalkState = ref.watch(activeWalkProvider);
    final gpsState = ref.watch(gpsProviderRiverpod);

    return Scaffold(
      backgroundColor: isDark 
          ? WanMapColors.backgroundDark 
          : WanMapColors.backgroundLight,
      // AppBarは各タブで個別に実装（タブごとに最適化）
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),
          // 散歩記録中バナー
          if (gpsState.isRecording && activeWalkState.isWalking)
            _buildActiveWalkBanner(context, activeWalkState, gpsState, isDark),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: WanMapColors.accent,
        unselectedItemColor: isDark ? Colors.grey[600] : Colors.grey[500],
        backgroundColor: isDark 
            ? WanMapColors.cardDark 
            : Colors.white,
        elevation: 8,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        selectedLabelStyle: WanMapTypography.caption.copyWith(
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: WanMapTypography.caption,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined, size: 28),
            activeIcon: Icon(Icons.home, size: 28),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.route_outlined, size: 28),
            activeIcon: Icon(Icons.route, size: 28),
            label: 'ルート',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fiber_manual_record_outlined, size: 28),
            activeIcon: Icon(Icons.fiber_manual_record, size: 28),
            label: 'クイック記録',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline, size: 28),
            activeIcon: Icon(Icons.person, size: 28),
            label: 'プロフィール',
          ),
        ],
      ),
    );
  }

  /// 散歩記録中バナー
  Widget _buildActiveWalkBanner(
    BuildContext context,
    ActiveWalkState activeWalkState,
    GpsState gpsState,
    bool isDark,
  ) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: GestureDetector(
          onTap: () {
            // 適切な散歩画面に復帰
            if (activeWalkState.walkMode == WalkMode.daily) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DailyWalkingScreen(),
                ),
              );
            } else if (activeWalkState.walkMode == WalkMode.outing) {
              // お出かけ散歩の場合は、ルート情報が必要なので戻れないケースもある
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('散歩画面に戻るには「クイック記録」タブから再度開いてください'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: WanMapSpacing.md,
              vertical: WanMapSpacing.sm,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  WanMapColors.accent,
                  WanMapColors.accent.withOpacity(0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // 散歩中アイコン
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.directions_walk,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: WanMapSpacing.sm),
                // 散歩情報
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        activeWalkState.walkMode == WalkMode.daily
                            ? '日常散歩 記録中'
                            : 'お出かけ散歩 記録中',
                        style: WanMapTypography.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${gpsState.formattedDistance} • ${gpsState.formattedDuration}',
                        style: WanMapTypography.caption.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                // タップして戻るアイコン
                Icon(
                  Icons.touch_app,
                  color: Colors.white.withOpacity(0.8),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

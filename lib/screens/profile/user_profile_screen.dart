import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wanmap_v2/models/profile_model.dart';
import 'package:wanmap_v2/models/route_model.dart';
import 'package:wanmap_v2/providers/follow_provider.dart';
import 'package:wanmap_v2/services/profile_service.dart';
import 'package:wanmap_v2/services/route_service.dart';
import 'package:wanmap_v2/screens/routes/route_detail_screen.dart';
import 'package:wanmap_v2/screens/social/follow_list_screen.dart';

// プロバイダー
final userProfileProvider = FutureProvider.family<ProfileModel, String>((ref, userId) async {
  final service = ProfileService();
  return await service.getProfileById(userId);
});

final userRoutesProvider = FutureProvider.family<List<RouteModel>, String>((ref, userId) async {
  final service = RouteService();
  return await service.getPublicRoutesByUser(userId);
});

class UserProfileScreen extends ConsumerWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isOwnProfile = currentUserId == userId;

    final profileAsync = ref.watch(userProfileProvider(userId));
    final routesAsync = ref.watch(userRoutesProvider(userId));
    final followStatsAsync = ref.watch(followStatsProvider(userId));
    final isFollowingAsync = !isOwnProfile ? ref.watch(isFollowingProvider(userId)) : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール'),
      ),
      body: profileAsync.when(
        data: (profile) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(userProfileProvider(userId));
            ref.invalidate(userRoutesProvider(userId));
            ref.invalidate(followStatsProvider(userId));
            if (!isOwnProfile) {
              ref.invalidate(isFollowingProvider(userId));
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // プロフィールヘッダー
                Container(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // アバター
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: profile.avatarUrl != null
                            ? NetworkImage(profile.avatarUrl!)
                            : null,
                        child: profile.avatarUrl == null
                            ? Text(
                                profile.displayName?[0].toUpperCase() ?? '?',
                                style: const TextStyle(fontSize: 32),
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // 表示名
                      Text(
                        profile.displayName ?? 'Unknown User',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),

                      // Bio
                      if (profile.bio != null)
                        Text(
                          profile.bio!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      const SizedBox(height: 16),

                      // フォロー統計
                      followStatsAsync.when(
                        data: (stats) => Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _StatButton(
                              label: 'フォロワー',
                              count: stats.followerCount,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FollowListScreen(
                                      userId: userId,
                                      type: FollowListType.followers,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 32),
                            _StatButton(
                              label: 'フォロー中',
                              count: stats.followingCount,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FollowListScreen(
                                      userId: userId,
                                      type: FollowListType.following,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        loading: () => const CircularProgressIndicator(),
                        error: (_, __) => const SizedBox(),
                      ),

                      // フォローボタン（他人のプロフィールのみ）
                      if (!isOwnProfile && isFollowingAsync != null) ...[
                        const SizedBox(height: 16),
                        isFollowingAsync.when(
                          data: (isFollowing) => SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  await ref.read(followActionsProvider).toggleFollow(userId);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isFollowing ? 'フォロー解除しました' : 'フォローしました',
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('エラー: $e')),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isFollowing
                                    ? Theme.of(context).colorScheme.surfaceVariant
                                    : Theme.of(context).colorScheme.primary,
                                foregroundColor: isFollowing
                                    ? Theme.of(context).colorScheme.onSurfaceVariant
                                    : Theme.of(context).colorScheme.onPrimary,
                              ),
                              icon: Icon(isFollowing ? Icons.person_remove : Icons.person_add),
                              label: Text(isFollowing ? 'フォロー解除' : 'フォロー'),
                            ),
                          ),
                          loading: () => const CircularProgressIndicator(),
                          error: (_, __) => const SizedBox(),
                        ),
                      ],
                    ],
                  ),
                ),

                const Divider(),

                // 公開ルート一覧
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    '公開ルート',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),

                routesAsync.when(
                  data: (routes) {
                    if (routes.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text(
                          '公開ルートはありません',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: routes.length,
                      itemBuilder: (context, index) {
                        final route = routes[index];
                        return ListTile(
                          leading: const Icon(Icons.route),
                          title: Text(route.title),
                          subtitle: Text(
                            '${route.formattedDistance} • ${route.formattedDuration}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RouteDetailScreen(
                                  routeId: route.id,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, stack) => Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text('エラー: $error'),
                  ),
                ),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('エラー: $error'),
        ),
      ),
    );
  }
}

class _StatButton extends StatelessWidget {
  final String label;
  final int count;
  final VoidCallback onTap;

  const _StatButton({
    required this.label,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

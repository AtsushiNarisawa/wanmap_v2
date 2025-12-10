import 'package:flutter/material.dart';
import '../../models/badge.dart' as badge_model;
import '../../config/wanmap_colors.dart';

/// Badge Card Widget
/// 
/// Displays individual badge with:
/// - Badge icon with tier color
/// - Badge name and description
/// - Locked/Unlocked state
/// - Unlock date (if unlocked)
class BadgeCard extends StatelessWidget {
  final badge_model.Badge badge;

  const BadgeCard({
    super.key,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: badge.isUnlocked ? 2 : 0,
      color: badge.isUnlocked
          ? (isDark ? Colors.grey[850] : Colors.white)
          : (isDark ? Colors.grey[900]!.withOpacity(0.3) : Colors.grey[200]!.withOpacity(0.5)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: badge.isUnlocked
            ? BorderSide(color: badge.tierColor.withOpacity(0.3), width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Badge Icon (smaller)
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: badge.isUnlocked
                    ? RadialGradient(
                        colors: [
                          badge.tierColor.withOpacity(0.3),
                          badge.tierColor.withOpacity(0.1),
                        ],
                      )
                    : null,
                color: badge.isUnlocked
                    ? null
                    : (isDark ? Colors.grey[800] : Colors.grey[300]),
              ),
              child: Icon(
                badge.icon,
                size: 28,
                color: badge.isUnlocked
                    ? badge.tierColor
                    : (isDark ? Colors.grey[700] : Colors.grey[400]),
              ),
            ),
            
            const SizedBox(height: 6),
            
            // Badge Name (smaller font)
            Text(
              badge.nameJa,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: badge.isUnlocked
                    ? (isDark ? Colors.white : Colors.black87)
                    : (isDark ? Colors.grey[600] : Colors.grey[400]),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 4),
            
            // Tier Badge (compact)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: badge.tierColor.withOpacity(badge.isUnlocked ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge.tier.label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: badge.isUnlocked
                      ? badge.tierColor
                      : badge.tierColor.withOpacity(0.4),
                ),
              ),
            ),
            
            const Spacer(),
            
            // Unlock Status (compact)
            if (badge.isUnlocked && badge.unlockedAt != null)
              Icon(
                Icons.check_circle,
                size: 14,
                color: WanMapColors.accent,
              )
            else
              Icon(
                Icons.lock_outline,
                size: 14,
                color: isDark ? Colors.grey[700] : Colors.grey[400],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeIcon(bool isDark) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: badge.isUnlocked
            ? RadialGradient(
                colors: [
                  badge.tierColor.withOpacity(0.3),
                  badge.tierColor.withOpacity(0.1),
                ],
              )
            : null,
        color: badge.isUnlocked
            ? null
            : (isDark ? Colors.grey[800] : Colors.grey[300]),
      ),
      child: Icon(
        badge.icon,
        size: 36,
        color: badge.isUnlocked
            ? badge.tierColor
            : (isDark ? Colors.grey[700] : Colors.grey[400]),
      ),
    );
  }

  Widget _buildUnlockDate(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.check_circle,
          size: 14,
          color: WanMapColors.accent,
        ),
        const SizedBox(width: 4),
        Text(
          _formatUnlockDate(badge.unlockedAt!),
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.grey[500] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildLockedStatus(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.lock_outline,
          size: 14,
          color: isDark ? Colors.grey[700] : Colors.grey[400],
        ),
        const SizedBox(width: 4),
        Text(
          'ロック中',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.grey[700] : Colors.grey[400],
          ),
        ),
      ],
    );
  }

  String _formatUnlockDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      return '今日獲得';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日前に獲得';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks週間前に獲得';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$monthsヶ月前に獲得';
    } else {
      return '${date.year}/${date.month}/${date.day}に獲得';
    }
  }
}

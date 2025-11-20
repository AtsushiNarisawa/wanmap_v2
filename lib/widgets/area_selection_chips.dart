import 'package:flutter/material.dart';
import '../models/area_info.dart';

/// エリア選択チップ
class AreaSelectionChips extends StatelessWidget {
  final String? selectedArea;
  final Function(String?) onAreaSelected;

  const AreaSelectionChips({
    super.key,
    required this.selectedArea,
    required this.onAreaSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SizedBox(
        height: 56,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            // 「全て」チップ
            _buildChip(
              context: context,
              area: null,
              emoji: '🗺️',
              isSelected: selectedArea == null,
            ),
            
            const SizedBox(width: 8),
            
            // 各エリアチップ
            ...AreaInfo.areas.map((area) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildChip(
                  context: context,
                  area: area,
                  emoji: area.emoji,
                  isSelected: selectedArea == area.id,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// チップを構築（絵文字のみ、シンプル版）
  Widget _buildChip({
    required BuildContext context,
    required AreaInfo? area,
    required String emoji,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => onAreaSelected(area?.id),
      child: Container(
        width: 56,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: RichText(
          text: TextSpan(
            text: emoji,
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}

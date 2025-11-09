import 'package:flutter/material.dart';

import '../services/api_client.dart';
import 'level_bar.dart';

/// 홈 화면에 노출되는 펫 상태 카드.
class PetStatusCard extends StatelessWidget {
  const PetStatusCard({
    super.key,
    required this.petState,
    required this.isLoading,
  });

  final PetState? petState;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return _buildContent(context);
  }

  Widget _buildContent(BuildContext context) {
    if (petState == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            '펫 정보를 불러오는 중입니다.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12),
          LinearProgressIndicator(),
        ],
      );
    }

    final xp = petState!.xp;
    final threshold = petState!.nextLevelThreshold;
    final progress = threshold > 0 ? (xp / threshold).clamp(0.0, 1.0) : 0.0;

    return LevelBar(level: petState!.level, progress: progress);
  }
}

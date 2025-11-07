import 'package:flutter/material.dart';

import '../constants.dart';
import '../services/api_client.dart';

/// 홈 화면에 노출되는 펫 상태 카드.
class PetStatusCard extends StatelessWidget {
  const PetStatusCard({super.key, required this.petState, required this.isLoading});

  final PetState? petState;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (petState == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('펫 정보를 불러오는 중입니다.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          SizedBox(height: 12),
          LinearProgressIndicator(),
        ],
      );
    }

    final xp = petState!.xp;
    final threshold = petState!.nextLevelThreshold;
    final progress = threshold > 0 ? (xp / threshold).clamp(0.0, 1.0) : 0.0;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Lv.${petState!.level}', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 6),
                        Text('XP $xp / $threshold', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 68,
                    height: 68,
                    child: Image.asset('assets/pet.png', fit: BoxFit.contain),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(kSeedColor),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

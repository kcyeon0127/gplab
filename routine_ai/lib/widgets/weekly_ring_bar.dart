import 'package:flutter/material.dart';

import '../constants.dart';
import '../models/weekly_day_status.dart';
import 'progress_ring_painter.dart';

/// 요일별 링 차트를 표시하는 바.
class WeeklyRingBar extends StatelessWidget {
  const WeeklyRingBar({
    super.key,
    required this.weekly,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<WeeklyDayStatus> weekly;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    if (weekly.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Text('주간 데이터가 없어요. 루틴을 완료하면 여기에 표시됩니다.'),
      );
    }

    final items = List<Widget>.generate(weekly.length, (index) {
      final status = weekly[index];
      final isSelected = selectedIndex == index;
      return Padding(
        padding: EdgeInsets.only(right: index == weekly.length - 1 ? 0 : 12),
        child: _DayCircle(
          status: status,
          isSelected: isSelected,
          onTap: () => onSelect(index),
        ),
      );
    });

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: items,
    );
  }
}

class _DayCircle extends StatelessWidget {
  const _DayCircle({required this.status, required this.isSelected, required this.onTap});

  final WeeklyDayStatus status;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = isSelected ? 50.0 : 44.0;
    final completion = status.completionRate.clamp(0.0, 1.0);
    final isPerfect = completion >= 1.0 && !status.failed;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? kSeedColor : Colors.transparent,
                width: isSelected ? 3 : 1,
              ),
            ),
            child: SizedBox(
              width: size,
              height: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    painter: ProgressRingPainter(
                      progress: completion,
                      failed: status.failed,
                      strokeWidth: 6,
                    ),
                    child: const SizedBox.expand(),
                  ),
                  if (status.failed)
                    const Icon(Icons.priority_high, color: Colors.white, size: 18)
                  else
                    Text(
                      '${status.date.day}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  if (isPerfect)
                    const Positioned(
                      bottom: 6,
                      right: 6,
                      child: Icon(Icons.check_circle, color: kSeedColor, size: 16),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(status.weekdayLabel, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// 캘린더 화면에서 사용하는 루틴 카드 위젯.
class RoutineCard extends StatelessWidget {
  const RoutineCard({
    super.key,
    required this.title,
    required this.timeLabel,
    required this.statusLabel,
    required this.statusColor,
    required this.icon,
    required this.difficulty,
    this.repeatDays,
    this.onEdit,
    this.onDelete,
  });

  final String title;
  final String timeLabel;
  final String statusLabel;
  final Color statusColor;
  final IconData icon;
  final String difficulty;
  final List<String>? repeatDays;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withValues(alpha: 0.15),
                  child: Icon(icon, color: statusColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeLabel,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                _DifficultyStars(count: _starCountForDifficulty()),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: '수정',
                  icon: const Icon(Icons.edit),
                  onPressed: onEdit,
                ),
                IconButton(
                  tooltip: '삭제',
                  icon: const Icon(Icons.delete),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (repeatDays != null && repeatDays!.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: repeatDays!
                    .map(
                      (day) => Chip(
                        label: Text(day),
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                const SizedBox.shrink(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _starCountForDifficulty() {
    switch (difficulty) {
      case 'easy':
        return 1;
      case 'hard':
        return 3;
      case 'mid':
      default:
        return 2;
    }
  }
}

class _DifficultyStars extends StatelessWidget {
  const _DifficultyStars({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final filled = index < count;
        return Icon(
          filled ? Icons.star : Icons.star_border,
          size: 18,
          color: filled ? Colors.amber.shade600 : Colors.grey.shade400,
        );
      }),
    );
  }
}

import 'package:flutter/material.dart';

import '../constants.dart';
import '../models/routine_item.dart';
import '../models/weekly_day_status.dart';
import '../models/routine_progress.dart';

/// 오른쪽에서 등장하는 주간 루틴 패널.
class RightSlidePanel extends StatelessWidget {
  const RightSlidePanel({
    super.key,
    required this.isOpen,
    required this.selectedStatus,
    required this.routines,
    required this.progressList,
    required this.onClose,
  });

  final bool isOpen;
  final WeeklyDayStatus? selectedStatus;
  final List<RoutineItem> routines;
  final List<RoutineWeeklyProgress> progressList;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width * 0.85;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      top: 0,
      bottom: 0,
      right: isOpen ? 0 : -width,
      child: _PanelContainer(
        width: width,
        selectedStatus: selectedStatus,
        routines: routines,
        progressList: progressList,
        onClose: onClose,
      ),
    );
  }
}

class _PanelContainer extends StatelessWidget {
  const _PanelContainer({
    required this.width,
    required this.selectedStatus,
    required this.routines,
    required this.progressList,
    required this.onClose,
  });

  final double width;
  final WeeklyDayStatus? selectedStatus;
  final List<RoutineItem> routines;
  final List<RoutineWeeklyProgress> progressList;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < -200) {
          onClose();
        }
      },
      child: SizedBox(
        width: width,
        child: Material(
          color: Colors.white,
          elevation: 8,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            bottomLeft: Radius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '주간 루틴',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (selectedStatus != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: kSeedColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${selectedStatus!.weekdayLabel}요일 · ${selectedStatus!.date.month}/${selectedStatus!.date.day}',
                              style: const TextStyle(
                                color: kSeedColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else
                          const Text('선택된 요일 없음'),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: '닫기',
                      onPressed: onClose,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    children: [
                      _ProgressSection(progressList: progressList),
                      const SizedBox(height: 24),
                      if (routines.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: Text('등록된 루틴이 없습니다.')),
                        )
                      else ...[
                        Text(
                          '선택 요일 루틴',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        ...routines.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == routines.length - 1 ? 0 : 16,
                            ),
                            child: _RoutineTile(item: item),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoutineTile extends StatelessWidget {
  const _RoutineTile({required this.item});

  final RoutineItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: kSeedColor.withValues(alpha: 0.15),
                child: Icon(item.icon, color: kSeedColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item.category,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '시간: ${item.time}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: item.days
                          .map(
                            (day) => Chip(
                              padding: EdgeInsets.zero,
                              labelPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              backgroundColor: dayLabelColor(day),
                              label: Text(day),
                              visualDensity: VisualDensity.compact,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (item.badges.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: item.badges
                  .map(
                    (badge) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(badge, style: const TextStyle(fontSize: 12)),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Color dayLabelColor(String day) {
    switch (day) {
      case '토':
        return const Color(0xFFD1E8FF);
      case '일':
        return const Color(0xFFFFD6D6);
      default:
        return Colors.white;
    }
  }
}

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({required this.progressList});

  final List<RoutineWeeklyProgress> progressList;

  static const _dayHeaders = ['일', '월', '화', '수', '목', '금', '토'];

  @override
  Widget build(BuildContext context) {
    if (progressList.isEmpty) {
      return const Text('주간 진행률 데이터를 불러오는 중입니다.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('전체 주간 진행 체크', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
            border: TableBorder(
              horizontalInside: BorderSide(
                color: Colors.grey.shade300,
                width: 0.5,
              ),
              verticalInside: BorderSide(
                color: Colors.grey.shade200,
                width: 0.5,
              ),
            ),
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade100),
                children: [
                  _buildHeaderCell('루틴'),
                  ..._dayHeaders.map(
                    (day) => _buildHeaderCell(day, centered: true),
                  ),
                ],
              ),
              ...progressList.map(
                (entry) => TableRow(
                  children: [
                    _buildRoutineCell(context, entry),
                    ..._dayHeaders.map(
                      (day) => _buildStatusCell(
                        entry.dayStatuses
                            .firstWhere(
                              (status) => status.dayLabel == day,
                              orElse: () => RoutineDayStatus(
                                dayLabel: day,
                                result: RoutineDayResult.pending,
                              ),
                            )
                            .result,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(String label, {bool centered = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Align(
        alignment: centered ? Alignment.center : Alignment.centerLeft,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildRoutineCell(BuildContext context, RoutineWeeklyProgress entry) {
    final percentage = (entry.completionRate * 100)
        .clamp(0, 100)
        .toStringAsFixed(0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(entry.title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            '$percentage% · ${entry.completedCount}/${entry.totalCount}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCell(RoutineDayResult result) {
    IconData icon;
    Color color;
    switch (result) {
      case RoutineDayResult.done:
        icon = Icons.check_circle;
        color = kSeedColor;
        break;
      case RoutineDayResult.miss:
        icon = Icons.close_rounded;
        color = const Color(0xFFF46D6D);
        break;
      case RoutineDayResult.pending:
        icon = Icons.remove_circle_outline;
        color = Colors.grey;
        break;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(child: Icon(icon, color: color, size: 20)),
    );
  }
}

/// 루틴의 주간 진행률 요약 데이터.
class RoutineWeeklyProgress {
  const RoutineWeeklyProgress({
    required this.title,
    required this.completionRate,
    required this.completedCount,
    required this.totalCount,
    required this.dayStatuses,
  });

  final String title;
  final double completionRate;
  final int completedCount;
  final int totalCount;
  final List<RoutineDayStatus> dayStatuses;
}

/// 주간 루틴 한 칸(요일)의 체크 상태.
class RoutineDayStatus {
  const RoutineDayStatus({required this.dayLabel, required this.result});

  final String dayLabel;
  final RoutineDayResult result;
}

/// 요일별 결과 유형.
enum RoutineDayResult { done, miss, pending }

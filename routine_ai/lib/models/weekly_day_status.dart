/// 주간 요일별 달성 상태 모델.
class WeeklyDayStatus {
  WeeklyDayStatus({
    required this.date,
    required this.weekdayLabel,
    required this.completionRate,
    this.failed = false,
  });

  final DateTime date;
  final String weekdayLabel;
  final double completionRate;
  final bool failed;

  WeeklyDayStatus copyWith({
    DateTime? date,
    String? weekdayLabel,
    double? completionRate,
    bool? failed,
  }) {
    return WeeklyDayStatus(
      date: date ?? this.date,
      weekdayLabel: weekdayLabel ?? this.weekdayLabel,
      completionRate: completionRate ?? this.completionRate,
      failed: failed ?? this.failed,
    );
  }
}

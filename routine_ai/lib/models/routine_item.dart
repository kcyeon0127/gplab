import 'package:flutter/material.dart';

import '../widgets/icon_helper.dart';

/// 캘린더 화면에서 사용하는 루틴 데이터 모델.
class CalendarRoutine {
  const CalendarRoutine({
    required this.id,
    required this.title,
    required this.time,
    required this.status,
    required this.iconKey,
    required this.days,
    required this.difficulty,
  });

  final int id;
  final String title;
  final TimeOfDay time;
  final String status;
  final String iconKey;
  final List<String> days;
  final String difficulty;

  IconData get icon => iconFromKey(iconKey);

  CalendarRoutine copyWith({
    String? title,
    TimeOfDay? time,
    String? status,
    String? iconKey,
    List<String>? days,
    String? difficulty,
  }) {
    return CalendarRoutine(
      id: id,
      title: title ?? this.title,
      time: time ?? this.time,
      status: status ?? this.status,
      iconKey: iconKey ?? this.iconKey,
      days: days ?? this.days,
      difficulty: difficulty ?? this.difficulty,
    );
  }
}

/// 주간 패널에서 사용하는 루틴 요약 모델.
class RoutineItem {
  const RoutineItem({
    required this.id,
    required this.title,
    required this.category,
    required this.icon,
    required this.days,
    required this.time,
    this.badges = const [],
  });

  final int id;
  final String title;
  final String category;
  final IconData icon;
  final List<String> days;
  final String time;
  final List<String> badges;
}

class RoutineRecommendation {
  const RoutineRecommendation({
    required this.title,
    required this.iconKey,
    required this.time,
    required this.days,
    required this.difficulty,
  });

  final String title;
  final String iconKey;
  final String time;
  final List<String> days;
  final String difficulty;

  factory RoutineRecommendation.fromJson(Map<String, dynamic> json) {
    return RoutineRecommendation(
      title: json['title']?.toString() ?? '',
      iconKey: json['icon']?.toString() ?? 'yoga',
      time: json['time']?.toString() ?? '07:00',
      days:
          (json['days'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      difficulty: json['difficulty']?.toString() ?? 'mid',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'icon': iconKey,
      'time': time,
      'days': days,
      'difficulty': difficulty,
    };
  }
}

import 'package:flutter/material.dart';

/// 사전 정의된 아이콘 키 매핑.
const Map<String, IconData> iconOptions = {
  'yoga': Icons.self_improvement,
  'run': Icons.directions_run,
  'book': Icons.menu_book,
  'task': Icons.task_alt,
  'clean': Icons.cleaning_services,
  'sleep': Icons.hotel,
  'focus': Icons.timelapse,
};

/// 아이콘 키를 IconData로 변환한다.
IconData iconFromKey(String key) {
  return iconOptions[key] ?? Icons.auto_awesome;
}

/// IconData를 키 값으로 역변환한다.
String iconKeyFromData(IconData data) {
  return iconOptions.entries.firstWhere(
    (entry) => entry.value == data,
    orElse: () => const MapEntry('yoga', Icons.self_improvement),
  ).key;
}

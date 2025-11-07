import 'package:flutter/material.dart';

import '../models/routine_item.dart';
import '../models/routine_progress.dart';
import '../models/weekly_day_status.dart';
import '../services/api_client.dart';

/// 펫 상태를 전역으로 공유하는 Provider.
class AppState extends ChangeNotifier {
  AppState({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;
  PetState? _petState;
  bool _isLoadingPet = false;

  List<WeeklyDayStatus> _weeklyStatuses = const [];
  List<RoutineItem> _selectedDayRoutines = const [];
  List<RoutineWeeklyProgress> _weeklyRoutineProgress = const [];
  final List<CalendarRoutine> _calendarRoutines = [
    CalendarRoutine(
      id: 1,
      title: '아침 스트레칭',
      time: const TimeOfDay(hour: 7, minute: 0),
      status: 'done',
      icon: Icons.self_improvement,
      days: const ['월', '수', '금'],
    ),
    CalendarRoutine(
      id: 2,
      title: '집중 독서',
      time: const TimeOfDay(hour: 21, minute: 0),
      status: 'partial',
      icon: Icons.menu_book,
      days: const ['화', '목', '토'],
    ),
    CalendarRoutine(
      id: 3,
      title: '정리 정돈',
      time: const TimeOfDay(hour: 10, minute: 0),
      status: 'partial',
      icon: Icons.cleaning_services,
      days: const ['일'],
    ),
  ];
  int _nextRoutineId = 4;
  int _selectedDayIndex = 0;
  bool _isWeeklyPanelOpen = false;

  PetState? get petState => _petState;
  bool get isLoadingPet => _isLoadingPet;

  List<WeeklyDayStatus> get weeklyStatuses => _weeklyStatuses;
  List<RoutineItem> get selectedDayRoutines => _selectedDayRoutines;
  List<RoutineWeeklyProgress> get weeklyRoutineProgress =>
      _weeklyRoutineProgress;
  List<CalendarRoutine> get calendarRoutines =>
      List.unmodifiable(_calendarRoutines);
  int get selectedDayIndex => _selectedDayIndex;
  bool get isWeeklyPanelOpen => _isWeeklyPanelOpen;

  ApiClient get apiClient => _apiClient;

  /// 백엔드에서 펫 상태를 다시 불러온다.
  Future<ApiException?> refreshPetState() async {
    _isLoadingPet = true;
    notifyListeners();
    try {
      final pet = await _apiClient.fetchPetState();
      _petState = pet;
      return null;
    } on ApiException catch (error) {
      return error;
    } finally {
      _isLoadingPet = false;
      notifyListeners();
    }
  }

  /// 외부 호출 결과로 받은 펫 상태를 적용한다.
  void applyPetState(PetState pet) {
    _petState = pet;
    notifyListeners();
  }

  /// 주간 렌더링용 데이터를 초기화한다.
  Future<void> bootstrapWeeklyOverview() async {
    _weeklyStatuses = await _fetchWeeklyStatus();
    if (_weeklyStatuses.isEmpty) {
      _selectedDayIndex = 0;
      _selectedDayRoutines = const [];
      notifyListeners();
      return;
    }
    _selectedDayIndex = _resolveInitialIndex();
    _selectedDayRoutines = _routinesForDate(
      _weeklyStatuses[_selectedDayIndex].date,
    );
    _weeklyRoutineProgress = _generateRoutineProgress();
    notifyListeners();
  }

  /// 요일 선택 변경.
  void selectDay(int index) {
    if (_weeklyStatuses.isEmpty) return;
    if (index < 0 || index >= _weeklyStatuses.length) return;
    if (_selectedDayIndex == index) {
      notifyListeners();
      return;
    }
    _selectedDayIndex = index;
    _selectedDayRoutines = _routinesForDate(_weeklyStatuses[index].date);
    notifyListeners();
  }

  void toggleWeeklyPanel() {
    _isWeeklyPanelOpen = !_isWeeklyPanelOpen;
    notifyListeners();
  }

  void closeWeeklyPanel() {
    if (_isWeeklyPanelOpen) {
      _isWeeklyPanelOpen = false;
      notifyListeners();
    }
  }

  /// 캘린더 루틴 조작
  void addCalendarRoutine({
    required String title,
    required TimeOfDay time,
    required IconData icon,
    required List<String> days,
  }) {
    final routine = CalendarRoutine(
      id: _nextRoutineId++,
      title: title,
      time: time,
      status: 'partial',
      icon: icon,
      days: days,
    );
    _calendarRoutines.add(routine);
    _refreshSelectedDayRoutines();
  }

  void updateCalendarRoutine({
    required int routineId,
    required String title,
    required TimeOfDay time,
    required IconData icon,
    required List<String> days,
  }) {
    final index = _calendarRoutines.indexWhere(
      (element) => element.id == routineId,
    );
    if (index == -1) return;
    _calendarRoutines[index] = _calendarRoutines[index].copyWith(
      title: title,
      time: time,
      icon: icon,
      days: days,
    );
    _refreshSelectedDayRoutines();
  }

  void deleteCalendarRoutine(int routineId) {
    _calendarRoutines.removeWhere((element) => element.id == routineId);
    _refreshSelectedDayRoutines();
  }

  void changeCalendarRoutineStatus(int routineId, String status) {
    final index = _calendarRoutines.indexWhere(
      (element) => element.id == routineId,
    );
    if (index == -1) return;
    _calendarRoutines[index] = _calendarRoutines[index].copyWith(
      status: status,
    );
    notifyListeners();
  }

  int _resolveInitialIndex() {
    final today = DateTime.now();
    for (var i = 0; i < _weeklyStatuses.length; i++) {
      final status = _weeklyStatuses[i];
      if (_isSameDate(status.date, today)) {
        return i;
      }
    }
    return 0;
  }

  Future<List<WeeklyDayStatus>> _fetchWeeklyStatus() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    const sampleCompletion = [0.1, 0.45, 0.82, 0.6, 1.0, 0.0, 0.35];
    const failedDays = {5};

    return List<WeeklyDayStatus>.generate(7, (index) {
      final date = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day + index,
      );
      final completion = sampleCompletion[index % sampleCompletion.length];
      return WeeklyDayStatus(
        date: date,
        weekdayLabel: weekdays[index],
        completionRate: completion,
        failed: failedDays.contains(index),
      );
    });
  }

  List<RoutineItem> _routinesForDate(DateTime date) {
    final label = _weekdayLabel(date.weekday % 7);
    return _calendarRoutines
        .where((routine) => routine.days.contains(label))
        .map(
          (routine) => RoutineItem(
            id: routine.id,
            title: routine.title,
            category: '루틴',
            icon: routine.icon,
            days: routine.days,
            time: _formatTimeOfDay(routine.time),
          ),
        )
        .toList(growable: false);
  }

  void _refreshSelectedDayRoutines() {
    if (_weeklyStatuses.isEmpty) {
      _selectedDayRoutines = const [];
    } else {
      final date = _weeklyStatuses[_selectedDayIndex].date;
      _selectedDayRoutines = _routinesForDate(date);
    }
    notifyListeners();
  }

  String _weekdayLabel(int weekdayZeroBased) {
    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    return weekdays[weekdayZeroBased];
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  List<RoutineWeeklyProgress> _generateRoutineProgress() {
    RoutineWeeklyProgress buildProgress(
      String title,
      Set<int> completed,
      Set<int> missed,
    ) {
      final dayStatuses = _buildDayStatuses(
        completed: completed,
        missed: missed,
      );
      final completedCount = dayStatuses
          .where((status) => status.result == RoutineDayResult.done)
          .length;
      final totalCount = dayStatuses.length;
      final completionRate = totalCount == 0 ? 0.0 : completedCount / totalCount;
      return RoutineWeeklyProgress(
        title: title,
        completionRate: completionRate,
        completedCount: completedCount,
        totalCount: totalCount,
        dayStatuses: dayStatuses,
      );
    }

    return [
      buildProgress('아침 스트레칭', {0, 2, 4}, {5}),
      buildProgress('집중 독서', {1, 3}, {6}),
      buildProgress('정리 정돈', {0}, {2, 5}),
    ];
  }

  List<RoutineDayStatus> _buildDayStatuses({
    required Set<int> completed,
    required Set<int> missed,
  }) {
    return List<RoutineDayStatus>.generate(7, (index) {
      final label = _weekdayLabel(index);
      RoutineDayResult result;
      if (completed.contains(index)) {
        result = RoutineDayResult.done;
      } else if (missed.contains(index)) {
        result = RoutineDayResult.miss;
      } else {
        result = RoutineDayResult.pending;
      }
      return RoutineDayStatus(dayLabel: label, result: result);
    });
  }
}

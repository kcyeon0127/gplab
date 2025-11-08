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
  final List<CalendarRoutine> _calendarRoutines = [];
  bool _isLoadingRoutines = false;
  bool _hasLoadedRoutines = false;
  final Map<String, Map<int, String>> _dailyRoutineStatuses = {};
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
  bool get isLoadingRoutines => _isLoadingRoutines;
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
    _recalculateWeeklyData();
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

  /// 캘린더 루틴 동기화
  Future<ApiException?> ensureCalendarRoutinesLoaded() async {
    if (_hasLoadedRoutines) return null;
    return refreshCalendarRoutines();
  }

  Future<ApiException?> refreshCalendarRoutines() async {
    if (_isLoadingRoutines) return null;
    _isLoadingRoutines = true;
    notifyListeners();
    try {
      final routines = await _apiClient.fetchUserRoutines();
      final statusMap = {for (final routine in _calendarRoutines) routine.id: routine.status};
      _calendarRoutines
        ..clear()
        ..addAll(routines.map((remote) {
          final mapped = _calendarRoutineFromRemote(remote);
          final preserved = statusMap[mapped.id];
          return preserved == null ? mapped : mapped.copyWith(status: preserved);
        }));
      _sortCalendarRoutines();
      _recalculateWeeklyData();
      _hasLoadedRoutines = true;
      _refreshSelectedDayRoutines();
      return null;
    } on ApiException catch (error) {
      return error;
    } finally {
      _isLoadingRoutines = false;
      notifyListeners();
    }
  }

  Future<ApiException?> createRoutine({
    required String title,
    required TimeOfDay time,
    required List<String> days,
    required String iconKey,
  }) async {
    try {
      final remote = await _apiClient.createRoutine(
        title: title,
        time: _formatTimeOfDay(time),
        days: days,
        difficulty: 'mid',
        active: true,
        iconKey: iconKey,
      );
      _calendarRoutines.add(_calendarRoutineFromRemote(remote));
      _sortCalendarRoutines();
      _recalculateWeeklyData();
      _refreshSelectedDayRoutines();
      return null;
    } on ApiException catch (error) {
      return error;
    }
  }

  Future<ApiException?> updateRoutine({
    required int routineId,
    required String title,
    required TimeOfDay time,
    required List<String> days,
    required String iconKey,
  }) async {
    try {
      final remote = await _apiClient.updateRoutine(
        routineId: routineId,
        title: title,
        time: _formatTimeOfDay(time),
        days: days,
        difficulty: 'mid',
        active: true,
        iconKey: iconKey,
      );
      final index = _calendarRoutines.indexWhere((routine) => routine.id == routineId);
      if (index != -1) {
        final preservedStatus = _calendarRoutines[index].status;
        _calendarRoutines[index] =
            _calendarRoutineFromRemote(remote).copyWith(status: preservedStatus);
      }
      _sortCalendarRoutines();
      _recalculateWeeklyData();
      _refreshSelectedDayRoutines();
      return null;
    } on ApiException catch (error) {
      return error;
    }
  }

  Future<ApiException?> removeRoutine(int routineId) async {
    try {
      await _apiClient.deleteRoutine(routineId: routineId);
      _calendarRoutines.removeWhere((routine) => routine.id == routineId);
      _removeRoutineStatuses(routineId);
      _recalculateWeeklyData();
      _refreshSelectedDayRoutines();
      return null;
    } on ApiException catch (error) {
      return error;
    }
  }

  void changeCalendarRoutineStatus(int routineId, String status, {DateTime? date}) {
    final index = _calendarRoutines.indexWhere(
      (element) => element.id == routineId,
    );
    if (index == -1) return;
    _calendarRoutines[index] = _calendarRoutines[index].copyWith(
      status: status,
    );
    _recordRoutineStatus(routineId: routineId, status: status, date: date ?? DateTime.now());
    _recalculateWeeklyData();
    _refreshSelectedDayRoutines();
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


  void _sortCalendarRoutines() {
    _calendarRoutines.sort((a, b) {
      final aKey = _formatTimeOfDay(a.time);
      final bKey = _formatTimeOfDay(b.time);
      return aKey.compareTo(bKey);
    });
  }

  void _recalculateWeeklyData() {
    final dates = _referenceDates();
    _weeklyStatuses = dates.map(_buildWeeklyStatusForDate).toList();
    _weeklyRoutineProgress = _buildRoutineProgress(dates.take(7).toList());
  }

  List<DateTime> _referenceDates() {
    final baseYear = DateTime.now().year;
    final startDate = DateTime(baseYear, 11, 3);
    return List<DateTime>.generate(14, (index) => startDate.add(Duration(days: index)));
  }

  WeeklyDayStatus _buildWeeklyStatusForDate(DateTime date) {
    final weekdayLabel = _weekdayLabel(date.weekday % 7);
    final scheduled = _calendarRoutines
        .where((routine) => routine.days.contains(weekdayLabel))
        .toList();
    if (scheduled.isEmpty) {
      return WeeklyDayStatus(
        date: date,
        weekdayLabel: weekdayLabel,
        completionRate: 0.0,
        failed: false,
      );
    }
    double totalScore = 0;
    bool failed = false;
    for (final routine in scheduled) {
      final status = _statusForRoutineOnDate(routine.id, date);
      totalScore += _scoreForStatus(status);
      if (status == 'miss') {
        failed = true;
      }
    }
    final completion = (totalScore / scheduled.length).clamp(0.0, 1.0);
    return WeeklyDayStatus(
      date: date,
      weekdayLabel: weekdayLabel,
      completionRate: completion,
      failed: failed,
    );
  }

  List<RoutineWeeklyProgress> _buildRoutineProgress(List<DateTime> dates) {
    if (_calendarRoutines.isEmpty) return const [];
    return _calendarRoutines.map((routine) {
      final dayStatuses = dates.map((date) {
        final status = _statusForRoutineOnDate(routine.id, date);
        return RoutineDayStatus(
          dayLabel: _weekdayLabel(date.weekday % 7),
          result: _dayResultFromStatus(status),
        );
      }).toList();
      final completedCount = dayStatuses
          .where((status) => status.result == RoutineDayResult.done)
          .length;
      final completionRate = dayStatuses.isEmpty
          ? 0.0
          : completedCount / dayStatuses.length;
      return RoutineWeeklyProgress(
        title: routine.title,
        completionRate: completionRate,
        completedCount: completedCount,
        totalCount: dayStatuses.length,
        dayStatuses: dayStatuses,
      );
    }).toList();
  }

  void _recordRoutineStatus({required int routineId, required String status, required DateTime date}) {
    final key = _dateKey(date);
    final entries = _dailyRoutineStatuses.putIfAbsent(key, () => {});
    entries[routineId] = status;
    final validKeys = _referenceDates().map(_dateKey).toSet();
    _dailyRoutineStatuses.removeWhere((entryKey, _) => !validKeys.contains(entryKey));
  }

  void _removeRoutineStatuses(int routineId) {
    for (final entries in _dailyRoutineStatuses.values) {
      entries.remove(routineId);
    }
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

  String _statusForRoutineOnDate(int routineId, DateTime date) {
    final key = _dateKey(date);
    return _dailyRoutineStatuses[key]?[routineId] ?? 'pending';
  }

  String _dateKey(DateTime date) => '${date.year}-${date.month}-${date.day}';

  double _scoreForStatus(String status) {
    switch (status) {
      case 'done':
        return 1.0;
      case 'late':
        return 0.7;
      case 'partial':
        return 0.5;
      case 'miss':
        return 0.0;
      default:
        return 0.0;
    }
  }

  RoutineDayResult _dayResultFromStatus(String status) {
    switch (status) {
      case 'done':
        return RoutineDayResult.done;
      case 'miss':
        return RoutineDayResult.miss;
      default:
        return RoutineDayResult.pending;
    }
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

  CalendarRoutine _calendarRoutineFromRemote(RoutineRemote remote) {
    return CalendarRoutine(
      id: remote.id,
      title: remote.title,
      time: _parseTimeOfDayString(remote.time),
      status: 'pending',
      iconKey: remote.iconKey,
      days: remote.days,
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  TimeOfDay _parseTimeOfDayString(String value) {
    final parts = value.split(':');
    final hour = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
    return TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
  }

}

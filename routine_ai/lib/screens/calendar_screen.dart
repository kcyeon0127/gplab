import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/routine_item.dart';
import '../providers/app_state.dart';
import '../services/api_client.dart';
import '../widgets/routine_card.dart';
import 'create_routine_screen.dart';

/// 루틴 관리 탭.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const Map<String, String> _statusLabels = {
    'done': '완료',
    'partial': '부분 완료',
    'miss': '미완료',
    'late': '지각',
  };

  static const Map<String, Color> _statusColors = {
    'done': Color(0xFF4CAF50),
    'partial': Color(0xFFFFB74D),
    'miss': Color(0xFFE57373),
    'late': Color(0xFF64B5F6),
  };

  bool _requestedLoad = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureRoutinesLoaded());
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final routines = appState.calendarRoutines;
    final isLoading = appState.isLoadingRoutines && routines.isEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('루틴 관리')),
      floatingActionButton: FloatingActionButton(
        onPressed: _createRoutine,
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : routines.isEmpty
              ? const Center(child: Text('등록된 루틴이 없습니다. 오른쪽 아래 + 버튼으로 추가해 보세요.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: routines.length,
                  itemBuilder: (context, index) {
                    final routine = routines[index];
                    final statusLabel = _statusLabels[routine.status] ?? '상태 미정';
                    final statusColor = _statusColors[routine.status] ?? Colors.grey;
                    final timeLabel = MaterialLocalizations.of(
                      context,
                    ).formatTimeOfDay(routine.time, alwaysUse24HourFormat: true);
                    return RoutineCard(
                      title: routine.title,
                      timeLabel: '$timeLabel 진행',
                      statusLabel: statusLabel,
                      statusColor: statusColor,
                      icon: routine.icon,
                      repeatDays: routine.days,
                      onEdit: () => _editRoutine(routine),
                      onDelete: () => _deleteRoutine(routine),
                    );
                  },
                ),
    );
  }

  Future<void> _createRoutine() async {
    final result = await Navigator.of(context).push<RoutineFormResult>(
      MaterialPageRoute(builder: (_) => const CreateRoutineScreen()),
    );
    if (!mounted || result == null) return;
    final error = await context.read<AppState>().createRoutine(
      title: result.title,
      time: result.time,
      days: result.days,
      iconKey: result.iconKey,
    );
    if (!mounted) return;
    if (error != null) {
      _showError(error);
    } else {
      _showMessage('루틴이 추가되었습니다.');
    }
  }

  Future<void> _editRoutine(CalendarRoutine routine) async {
    final result = await Navigator.of(context).push<RoutineFormResult>(
      MaterialPageRoute(
        builder: (_) => CreateRoutineScreen(
          initialTitle: routine.title,
          initialTime: routine.time,
          initialIconKey: routine.iconKey,
          initialDays: routine.days,
        ),
      ),
    );
    if (!mounted || result == null) return;
    final error = await context.read<AppState>().updateRoutine(
      routineId: routine.id,
      title: result.title,
      time: result.time,
      days: result.days,
      iconKey: result.iconKey,
    );
    if (!mounted) return;
    if (error != null) {
      _showError(error);
    } else {
      _showMessage('루틴이 수정되었습니다.');
    }
  }

  Future<void> _deleteRoutine(CalendarRoutine routine) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제 확인'),
        content: Text('루틴 "${routine.title}"을(를) 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    final error = await context.read<AppState>().removeRoutine(routine.id);
    if (!mounted) return;
    if (error != null) {
      _showError(error);
    } else {
      _showMessage('루틴이 삭제되었습니다.');
    }
  }

  void _showError(ApiException error) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(error.message)));
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _ensureRoutinesLoaded() async {
    if (_requestedLoad) return;
    _requestedLoad = true;
    final error = await context.read<AppState>().ensureCalendarRoutinesLoaded();
    if (error != null && mounted) {
      _showError(error);
    }
  }
}

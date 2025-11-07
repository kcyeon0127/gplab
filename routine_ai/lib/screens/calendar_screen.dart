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

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final routines = appState.calendarRoutines;
    return Scaffold(
      appBar: AppBar(title: const Text('캘린더')),
      floatingActionButton: FloatingActionButton(
        onPressed: _createRoutine,
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
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
            onStatusTap: () => _changeStatus(routine),
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
    context.read<AppState>().addCalendarRoutine(
      title: result.title,
      time: result.time,
      icon: result.icon,
      days: result.days,
    );
  }

  Future<void> _editRoutine(CalendarRoutine routine) async {
    final result = await Navigator.of(context).push<RoutineFormResult>(
      MaterialPageRoute(
        builder: (_) => CreateRoutineScreen(
          initialTitle: routine.title,
          initialTime: routine.time,
          initialIcon: routine.icon,
          initialDays: routine.days,
        ),
      ),
    );
    if (!mounted || result == null) return;
    context.read<AppState>().updateCalendarRoutine(
      routineId: routine.id,
      title: result.title,
      time: result.time,
      icon: result.icon,
      days: result.days,
    );
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
    context.read<AppState>().deleteCalendarRoutine(routine.id);
  }

  Future<void> _changeStatus(CalendarRoutine routine) async {
    final status = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: _statusLabels.entries
            .map(
              (entry) => ListTile(
                title: Text(entry.value),
                onTap: () => Navigator.pop(context, entry.key),
              ),
            )
            .toList(),
      ),
    );
    if (status == null || status == routine.status) return;
    await _reportCompletion(routine, status);
  }

  Future<void> _reportCompletion(CalendarRoutine routine, String status) async {
    try {
      final api = context.read<ApiClient>();
      final result = await api.reportRoutineCompletion(
        routineId: routine.id,
        status: status,
        startedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        endedAt: DateTime.now(),
      );
      if (!mounted) return;
      context.read<AppState>().changeCalendarRoutineStatus(routine.id, status);
      context.read<AppState>().applyPetState(result.petState);
      final hint = result.coachHint;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            hint == null || hint.isEmpty ? '루틴 상태가 업데이트되었습니다.' : hint,
          ),
        ),
      );
    } on ApiException catch (error) {
      _showError(error);
    }
  }

  void _showError(ApiException error) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(error.message)));
  }
}

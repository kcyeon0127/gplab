import 'package:flutter/material.dart';

import '../models/routine_item.dart';
import '../widgets/icon_helper.dart';

/// 루틴 생성/수정 결과 값.
class RoutineFormResult {
  const RoutineFormResult({
    required this.title,
    required this.time,
    required this.icon,
    required this.days,
  });

  final String title;
  final TimeOfDay time;
  final IconData icon;
  final List<String> days;
}

/// 루틴 생성/수정 화면.
class CreateRoutineScreen extends StatefulWidget {
  const CreateRoutineScreen({
    super.key,
    this.initialTitle,
    this.initialTime,
    this.initialIcon,
    this.initialDays,
    this.initialRoutine,
  });

  final String? initialTitle;
  final TimeOfDay? initialTime;
  final IconData? initialIcon;
  final List<String>? initialDays;
  final RoutineRecommendation? initialRoutine;

  @override
  State<CreateRoutineScreen> createState() => _CreateRoutineScreenState();
}

class _CreateRoutineScreenState extends State<CreateRoutineScreen> {
  static const List<String> _weekdayOptions = ['월', '화', '수', '목', '금', '토', '일'];

  late final TextEditingController _titleController;
  TimeOfDay? _selectedTime;
  late String _selectedIconKey;
  late Set<String> _selectedDays;

  @override
  void initState() {
    super.initState();
    final routine = widget.initialRoutine;
    _titleController = TextEditingController(text: widget.initialTitle ?? routine?.title ?? '');
    _selectedTime = widget.initialTime ?? _parseTime(routine?.time ?? '07:00');
    _selectedIconKey = routine?.iconKey ??
        (widget.initialIcon != null ? iconKeyFromData(widget.initialIcon!) : 'yoga');
    final existingDays = widget.initialDays ?? routine?.days;
    if (existingDays != null && existingDays.isNotEmpty) {
      _selectedDays = existingDays.toSet();
    } else {
      _selectedDays = {_weekdayOptions[DateTime.now().weekday % 7]};
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialTitle != null || widget.initialRoutine != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? '루틴 수정' : '루틴 생성')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: '루틴 제목', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickTime,
              icon: const Icon(Icons.access_time),
              label: Text(_selectedTimeLabel),
            ),
            const SizedBox(height: 16),
            Text('아이콘 선택', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: iconOptions.entries
                  .map(
                    (entry) => ChoiceChip(
                      label: Icon(entry.value),
                      selected: _selectedIconKey == entry.key,
                      onSelected: (_) => setState(() => _selectedIconKey = entry.key),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            Text('반복 요일', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _weekdayOptions
                  .map(
                    (day) => FilterChip(
                      label: Text(day),
                      selected: _selectedDays.contains(day),
                      onSelected: (value) {
                        setState(() {
                          if (value) {
                            _selectedDays.add(day);
                          } else if (_selectedDays.length > 1) {
                            _selectedDays.remove(day);
                          }
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: Text(isEditing ? '수정 완료' : '생성'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _selectedTimeLabel {
    final time = _selectedTime;
    if (time == null) return '시간 선택';
    return '선택된 시간: ${_formatTime(time)}';
  }

  Future<void> _pickTime() async {
    final now = TimeOfDay.now();
    final result = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? now,
      initialEntryMode: TimePickerEntryMode.dial,
    );
    if (result != null) {
      setState(() => _selectedTime = result);
    }
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('루틴 제목을 입력해 주세요.')));
      return;
    }
    final time = _selectedTime;
    if (time == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('시간을 선택해 주세요.')));
      return;
    }
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('반복할 요일을 한 개 이상 선택해 주세요.')));
      return;
    }

    final orderedDays = _selectedDays.toList()
      ..sort((a, b) => _weekdayOptions.indexOf(a).compareTo(_weekdayOptions.indexOf(b)));

    Navigator.of(context).pop(
      RoutineFormResult(
        title: title,
        time: time,
        icon: iconFromKey(_selectedIconKey),
        days: orderedDays,
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    return MaterialLocalizations.of(context).formatTimeOfDay(time, alwaysUse24HourFormat: true);
  }

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return TimeOfDay.now();
    final hour = int.tryParse(parts[0]) ?? 7;
    final minute = int.tryParse(parts[1]) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';

/// AI 루틴 추천 상세 화면.
class RecommendScreen extends StatefulWidget {
  const RecommendScreen({super.key});

  @override
  State<RecommendScreen> createState() => _RecommendScreenState();
}

class _RecommendScreenState extends State<RecommendScreen> {
  static const List<String> _goalOptions = ['운동', '공부', '정리', '수면'];
  static const Map<String, String> _slotLabels = {
    'morning': '아침',
    'noon': '점심',
    'evening': '저녁',
    'night': '밤',
  };

  final Set<String> _selectedGoals = {'운동'};
  final Set<String> _selectedSlots = {'morning'};
  final TextEditingController _promptController = TextEditingController();
  final List<_ChatEntry> _chat = <_ChatEntry>[];

  List<RoutinePlan> _plans = const [];
  bool _isLoading = false;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('루틴 추천')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('목표 선택', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _goalOptions.map((goal) {
                final selected = _selectedGoals.contains(goal);
                return FilterChip(
                  label: Text(goal),
                  selected: selected,
                  onSelected: (value) => setState(() {
                    if (value) {
                      _selectedGoals.add(goal);
                    } else if (_selectedGoals.length > 1) {
                      _selectedGoals.remove(goal);
                    }
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text('선호 시간대', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _slotLabels.entries.map((entry) {
                final selected = _selectedSlots.contains(entry.key);
                return FilterChip(
                  label: Text(entry.value),
                  selected: selected,
                  onSelected: (value) => setState(() {
                    if (value) {
                      _selectedSlots.add(entry.key);
                    } else if (_selectedSlots.length > 1) {
                      _selectedSlots.remove(entry.key);
                    }
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text('AI에게 전하고 싶은 요청(선택)', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _promptController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: '예) 내일은 출근 전에 30분 루틴으로 부탁해요',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isLoading ? null : _requestRecommend,
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('추천 받기'),
              ),
            ),
            const SizedBox(height: 24),
            if (_chat.isNotEmpty) ...[
              Text('AI 대화', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              ..._chat.map((entry) => Align(
                    alignment: entry.isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                      decoration: BoxDecoration(
                        color: entry.isUser ? theme.colorScheme.primary.withValues(alpha: 0.12) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: entry.isUser ? theme.colorScheme.primary : Colors.grey.shade300),
                      ),
                      child: Text(entry.message),
                    ),
                  )),
              const SizedBox(height: 24),
            ],
            if (_plans.isEmpty && !_isLoading)
              const Text('추천 결과가 아직 없습니다. 조건을 선택한 뒤 추천을 받아보세요.')
            else if (_plans.isNotEmpty) ...[
              Text('추천 루틴', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              ..._plans.map((plan) => _PlanCard(plan: plan)),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _requestRecommend() async {
    if (_selectedGoals.isEmpty || _selectedSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('목표와 시간대를 최소 한 개 이상 선택해 주세요.')),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    final promptText = _promptController.text.trim();
    final userMessage = _composeUserMessage(promptText);

    setState(() {
      _isLoading = true;
      _chat.add(_ChatEntry(isUser: true, message: userMessage));
      _promptController.clear();
    });

    List<RoutinePlan> newPlans = _plans;
    String? coachReply;

    try {
      final api = context.read<ApiClient>();
      coachReply = await api.sendCoachMessage(userMessage);
      newPlans = await api.generateRoutineRecommendations(
        goals: _selectedGoals.toList(),
        slots: _selectedSlots.toList(),
      );
    } on ApiException catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        final reply = coachReply;
        setState(() {
          _isLoading = false;
          if (reply != null && reply.isNotEmpty) {
            _chat.add(_ChatEntry(isUser: false, message: reply));
          }
          _plans = newPlans;
        });
      }
    }
  }

  String _composeUserMessage(String freeText) {
    final goalText = _selectedGoals.join(', ');
    final slotText = _selectedSlots.map((slot) => _slotLabels[slot] ?? slot).join(', ');
    final buffer = StringBuffer()
      ..writeln('목표: $goalText')
      ..writeln('선호 시간대: $slotText');
    if (freeText.isNotEmpty) {
      buffer.writeln('추가 요청: $freeText');
    }
    buffer.writeln('위 조건으로 오늘과 내일 추천 루틴을 제안해 주세요.');
    return buffer.toString();
  }

  void _showError(ApiException error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(error.message)));
  }
}

class _ChatEntry {
  const _ChatEntry({required this.isUser, required this.message});

  final bool isUser;
  final String message;
}

/// 추천 루틴 정보를 표시하는 카드.
class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});

  final RoutinePlan plan;

  @override
  Widget build(BuildContext context) {
    final slotText = plan.days.isEmpty ? '추천 요일 정보 없음' : plan.days.join(', ');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plan.title, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text('시간: ${plan.time} · 소요 ${plan.durationMinutes}분 · 난이도 ${_difficultyLabel(plan.difficulty)}'),
                      const SizedBox(height: 4),
                      Text('추천 요일: $slotText'),
                    ],
                  ),
                ),
                TextButton(onPressed: () => _showComingSoon(context), child: const Text('추가')),
              ],
            ),
            const SizedBox(height: 12),
            Text(plan.reason, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  String _difficultyLabel(String value) {
    switch (value) {
      case 'easy':
        return '쉬움';
      case 'mid':
        return '보통';
      case 'hard':
        return '어려움';
      default:
        return value;
    }
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('추가 기능은 준비중입니다.')));
  }
}

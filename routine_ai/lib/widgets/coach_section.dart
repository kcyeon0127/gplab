import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/coach_message.dart';
import 'coach_speech_bubble.dart';
import 'pet_avatar.dart';

/// 코치 말풍선 + 펫 아바타 섹션.
class CoachSection extends StatefulWidget {
  const CoachSection({super.key, this.onGo});

  final VoidCallback? onGo;

  @override
  State<CoachSection> createState() => _CoachSectionState();
}

class _CoachSectionState extends State<CoachSection> {
  CoachMessage? _message;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMessage();
  }

  Future<void> _loadMessage() async {
    try {
      final templateString = await rootBundle.loadString('lib/data/coach_templates.json');
      final templates = CoachMessage.decodeTemplates(templateString);
      if (templates.isEmpty) {
        setState(() => _message = _fallbackMessage());
        return;
      }
      final randomTemplate = templates[Random().nextInt(templates.length)];
      const vars = <String, String>{
        'boost': '30% 높아요',
        'routine': 'Algorithm Study',
        'xp': '5',
        'time': '08:30',
      };
      setState(() {
        _message = CoachMessage.fromTemplate(randomTemplate, vars);
      });
    } catch (error) {
      setState(() {
        _errorMessage = '기본 메시지를 표시합니다.';
        _message = _fallbackMessage();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: CircularProgressIndicator(),
      );
    }
    final message = _message ?? _fallbackMessage();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CoachSpeechBubble(
          message: message.text,
          highlight: message.highlight,
          actionText: message.actionText,
          onActionTap: widget.onGo,
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 12),
        const PetAvatar(),
      ],
    );
  }

  CoachMessage _fallbackMessage() {
    return const CoachMessage(
      patternId: 'fallback',
      text: '오늘도 루틴을 향해 한 걸음 전진해요! 필요한 루틴이 있으면 추천을 눌러보세요.',
      highlight: '루틴',
      actionText: '추천 받기',
    );
  }
}

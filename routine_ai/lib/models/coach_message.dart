import 'dart:convert';

/// 코치 말풍선 메시지 모델.
class CoachMessage {
  const CoachMessage({
    required this.patternId,
    required this.text,
    this.highlight,
    this.actionText,
    this.nextRoutine,
  });

  final String patternId;
  final String text;
  final String? highlight;
  final String? actionText;
  final String? nextRoutine;

  factory CoachMessage.fromTemplate(Map<String, dynamic> json, Map<String, String> vars) {
    String resolve(String? value) {
      if (value == null) return '';
      var resolved = value;
      vars.forEach((key, val) {
        resolved = resolved.replaceAll('{{$key}}', val);
      });
      return resolved;
    }

    final text = resolve(json['text'] as String?);
    final highlight = resolve(json['highlight'] as String?);
    final actionText = resolve(json['actionText'] as String?);
    final nextRoutine = resolve(json['nextRoutine'] as String?);

    return CoachMessage(
      patternId: json['patternId']?.toString() ?? 'generic',
      text: text,
      highlight: highlight.isEmpty ? null : highlight,
      actionText: actionText.isEmpty ? null : actionText,
      nextRoutine: nextRoutine.isEmpty ? null : nextRoutine,
    );
  }

  static List<Map<String, dynamic>> decodeTemplates(String jsonString) {
    final List<dynamic> raw = json.decode(jsonString) as List<dynamic>;
    return raw.whereType<Map<String, dynamic>>().toList();
  }
}

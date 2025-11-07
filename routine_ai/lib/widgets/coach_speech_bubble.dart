import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// 코치 말풍선 UI.
class CoachSpeechBubble extends StatelessWidget {
  const CoachSpeechBubble({
    super.key,
    required this.message,
    this.highlight,
    this.actionText,
    this.onActionTap,
  });

  final String message;
  final String? highlight;
  final String? actionText;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: message,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppTokens.speechBackground,
              borderRadius: BorderRadius.circular(AppTokens.speechRadius),
              border: Border.all(color: AppTokens.speechBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Stack(
              children: [
                _buildMessage(theme),
                if (actionText != null && actionText!.isNotEmpty)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: TextButton(
                      onPressed: onActionTap,
                      style: TextButton.styleFrom(foregroundColor: AppTokens.action, padding: EdgeInsets.zero),
                      child: Text(actionText!),
                    ),
                  ),
              ],
            ),
          ),
          CustomPaint(
            painter: _BubbleTailPainter(color: AppTokens.speechBackground, borderColor: AppTokens.speechBorder),
            child: const SizedBox(width: 24, height: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ThemeData theme) {
    final highlightText = highlight;
    if (highlightText == null || highlightText.isEmpty) {
      return Text(message, style: theme.textTheme.bodyMedium);
    }

    final spans = _buildHighlightedText(theme, highlightText);
    return RichText(text: TextSpan(children: spans, style: theme.textTheme.bodyMedium));
  }

  List<TextSpan> _buildHighlightedText(ThemeData theme, String highlightText) {
    final parts = message.split(highlightText);
    final List<TextSpan> spans = [];
    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (part.isNotEmpty) {
        spans.add(TextSpan(text: part));
      }
      if (i != parts.length - 1) {
        spans.add(TextSpan(
          text: highlightText,
          style: theme.textTheme.bodyMedium?.copyWith(color: AppTokens.highlight, fontWeight: FontWeight.bold),
        ));
      }
    }
    return spans;
  }
}

class _BubbleTailPainter extends CustomPainter {
  _BubbleTailPainter({required this.color, required this.borderColor});

  final Color color;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final fillPaint = Paint()..color = color;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.borderColor != borderColor;
  }
}

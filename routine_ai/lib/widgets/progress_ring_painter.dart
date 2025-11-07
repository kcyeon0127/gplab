import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants.dart';

/// 주간 링 게이지를 그리는 Painter.
class ProgressRingPainter extends CustomPainter {
  ProgressRingPainter({
    required this.progress,
    this.strokeWidth = 6.0,
    this.failed = false,
    this.baseColor = const Color(0xFFE8ECEF),
    this.progressColor = kSeedColor,
    this.failureColor = const Color(0xFFF46D6D),
  });

  final double progress;
  final double strokeWidth;
  final bool failed;
  final Color baseColor;
  final Color progressColor;
  final Color failureColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;

    if (failed) {
      final failurePaint = Paint()..color = failureColor;
      canvas.drawCircle(center, radius, failurePaint);
      return;
    }

    final backgroundPaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, backgroundPaint);

    if (progress <= 0) {
      return;
    }

    final clamped = progress.clamp(0.0, 1.0);
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * clamped, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant ProgressRingPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        strokeWidth != oldDelegate.strokeWidth ||
        failed != oldDelegate.failed ||
        baseColor != oldDelegate.baseColor ||
        progressColor != oldDelegate.progressColor ||
        failureColor != oldDelegate.failureColor;
  }
}

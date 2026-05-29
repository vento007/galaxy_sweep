import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class SignalPanelPainter extends CustomPainter {
  const SignalPanelPainter({required this.time});

  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(10));
    final pulse = math.sin(time * 1.4) * 0.5 + 0.5;

    final fillPaint = Paint()
      ..isAntiAlias = true
      ..shader = ui.Gradient.radial(
        rect.center,
        rect.shortestSide * 0.82,
        [
          const Color(0xff02090b).withValues(alpha: 0.44),
          const Color(0xff02090b).withValues(alpha: 0.18),
          const Color(0xff02090b).withValues(alpha: 0.02),
        ],
        const [0.0, 0.62, 1.0],
      );
    canvas.drawRRect(rrect, fillPaint);

    canvas.save();
    canvas.clipRRect(rrect);
    _paintSoftSignalWash(canvas, rect, pulse);
    _paintScanBands(canvas, rect, pulse);
    _paintMotes(canvas, rect);
    canvas.restore();

    final glowPaint = Paint()
      ..isAntiAlias = true
      ..blendMode = BlendMode.plus
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8 + pulse * 5
      ..color = const Color(0xff42f5dd).withValues(alpha: 0.07);
    canvas.drawRRect(rrect.deflate(1), glowPaint);

    final framePaint = Paint()
      ..isAntiAlias = true
      ..blendMode = BlendMode.plus
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.5
      ..color = const Color(0xffb9fff8).withValues(alpha: 0.58);
    canvas.drawPath(_cornerPath(rect.deflate(1.5), 36), framePaint);
  }

  void _paintSoftSignalWash(Canvas canvas, Rect rect, double pulse) {
    final paint = Paint()
      ..isAntiAlias = true
      ..blendMode = BlendMode.plus
      ..shader = ui.Gradient.radial(
        rect.center,
        rect.shortestSide * 0.70,
        [
          const Color(0xff2ff3df).withValues(alpha: 0.055 + pulse * 0.025),
          const Color(0xff6c80ff).withValues(alpha: 0.035),
          Colors.transparent,
        ],
        const [0.0, 0.45, 1.0],
      );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(10)),
      paint,
    );
  }

  void _paintScanBands(Canvas canvas, Rect rect, double pulse) {
    final paint = Paint()
      ..isAntiAlias = true
      ..blendMode = BlendMode.plus;

    for (var index = 0; index < 5; index++) {
      final y = rect.height * ((index * 0.23 + time * 0.045) % 1.0);
      final bandRect = Rect.fromLTWH(0, y - 8, rect.width, 16);

      paint.shader = ui.Gradient.linear(
        bandRect.centerLeft,
        bandRect.centerRight,
        [
          Colors.transparent,
          const Color(0xff7affef).withValues(alpha: 0.055 + pulse * 0.020),
          const Color(0xff8b9cff).withValues(alpha: 0.045),
          Colors.transparent,
        ],
        const [0.0, 0.36, 0.68, 1.0],
      );
      canvas.drawRect(bandRect, paint);
    }
  }

  void _paintMotes(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..isAntiAlias = true
      ..blendMode = BlendMode.plus;

    for (var index = 0; index < 22; index++) {
      final seed = index * 19.19;
      final x = (_hash(seed) + time * (0.003 + _hash(seed + 1) * 0.004)) % 1.0;
      final y =
          (_hash(seed + 8.2) + math.sin(time * 0.7 + index) * 0.012) % 1.0;
      final twinkle = math.sin(time * 1.8 + index * 0.61) * 0.5 + 0.5;

      paint.color =
          (index.isEven ? const Color(0xffd8fff8) : const Color(0xffb9c6ff))
              .withValues(alpha: 0.08 + twinkle * 0.09);
      canvas.drawCircle(
        Offset(rect.left + x * rect.width, rect.top + y * rect.height),
        0.8 + _hash(seed + 4.0) * 1.2,
        paint,
      );
    }
  }

  Path _cornerPath(Rect rect, double corner) {
    return Path()
      ..moveTo(rect.left, rect.top + corner)
      ..lineTo(rect.left, rect.top)
      ..lineTo(rect.left + corner, rect.top)
      ..moveTo(rect.right - corner, rect.top)
      ..lineTo(rect.right, rect.top)
      ..lineTo(rect.right, rect.top + corner)
      ..moveTo(rect.right, rect.bottom - corner)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.right - corner, rect.bottom)
      ..moveTo(rect.left + corner, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.bottom - corner);
  }

  double _hash(num value) {
    return (math.sin(value * 12.9898) * 43758.5453).abs() % 1.0;
  }

  @override
  bool shouldRepaint(covariant SignalPanelPainter oldDelegate) {
    return oldDelegate.time != time;
  }
}

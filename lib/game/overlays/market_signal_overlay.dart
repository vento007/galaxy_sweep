import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:galaxy_sweep/models/market_signal.dart';

class MarketSignalOverlay extends StatelessWidget {
  const MarketSignalOverlay({
    super.key,
    required this.signal,
    required this.elapsedSeconds,
  });

  final MarketSignal signal;
  final ValueListenable<double> elapsedSeconds;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Material(
        color: Colors.transparent,
        child: ValueListenableBuilder<double>(
          valueListenable: elapsedSeconds,
          builder: (context, now, _) {
            final age = (now - signal.startedAt).clamp(
              0.0,
              MarketSignal.durationSeconds,
            );
            final progress = age / MarketSignal.durationSeconds;
            if (progress >= 1) {
              return const SizedBox.shrink();
            }

            final fade = progress < 0.72
                ? 1.0
                : 1 - ((progress - 0.72) / 0.28).clamp(0.0, 1.0);
            final textSlide = (1 - fade) * 10;

            return Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: _MarketSignalPainter(age: age, progress: progress),
                ),
                Align(
                  alignment: const Alignment(0, -0.22),
                  child: Transform.translate(
                    offset: Offset(0, textSlide),
                    child: Opacity(
                      opacity: fade.clamp(0.0, 1.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            signal.message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xffedfffb),
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                              shadows: [
                                Shadow(
                                  color: Color(0xff2ff7df),
                                  blurRadius: 18,
                                ),
                                Shadow(
                                  color: Color(0xff4d7eff),
                                  blurRadius: 32,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'BTC ${signal.wholePrice}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.72),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MarketSignalPainter extends CustomPainter {
  const _MarketSignalPainter({required this.age, required this.progress});

  final double age;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.54);
    final fade = math.sin(progress * math.pi).clamp(0.0, 1.0);
    final baseRadius = math.min(size.width, size.height) * 0.12;

    final haloPaint = Paint()
      ..isAntiAlias = true
      ..blendMode = BlendMode.plus
      ..shader = ui.Gradient.radial(
        center,
        baseRadius * 1.85,
        [
          const Color(0xff5af8ea).withValues(alpha: 0.18 * fade),
          const Color(0xff4d7eff).withValues(alpha: 0.12 * fade),
          const Color(0xff000000).withValues(alpha: 0),
        ],
        const [0, 0.58, 1],
      );
    canvas.drawCircle(center, baseRadius * 1.9, haloPaint);

    final ringPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..blendMode = BlendMode.plus
      ..strokeWidth = 2.2;

    for (var ring = 0; ring < 2; ring++) {
      final radius = baseRadius * (0.95 + ring * 0.42) + progress * 18;
      ringPaint.color =
          (ring == 0 ? const Color(0xff78fff1) : const Color(0xff77a4ff))
              .withValues(alpha: (0.22 - ring * 0.05) * fade);
      canvas.drawCircle(center, radius, ringPaint);
    }

    final spiralPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..blendMode = BlendMode.plus;

    for (var arm = 0; arm < 3; arm++) {
      final path = Path();
      final armOffset = arm * math.pi * 2 / 3 + age * 1.55;

      for (var i = 0; i <= 44; i++) {
        final t = i / 44;
        final angle = armOffset + t * 2.6;
        final radius = baseRadius * (0.18 + t * 1.16);
        final wobble = math.sin(age * 2.6 + t * 8 + arm) * baseRadius * 0.05;
        final point =
            center +
            Offset(math.cos(angle), math.sin(angle)) * (radius + wobble);

        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }

      spiralPaint
        ..strokeWidth = 3.4 - arm * 0.5
        ..color =
            (arm.isEven ? const Color(0xff6cfff1) : const Color(0xff6e91ff))
                .withValues(alpha: (0.24 - arm * 0.04) * fade);
      canvas.drawPath(path, spiralPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MarketSignalPainter oldDelegate) {
    return oldDelegate.age != age || oldDelegate.progress != progress;
  }
}

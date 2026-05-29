import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:galaxy_sweep/game/board/board_layout.dart';
import 'package:galaxy_sweep/models/market_signal.dart';

class MarketSignalRegionRenderer {
  const MarketSignalRegionRenderer();

  void paint(
    Canvas canvas, {
    required BoardLayout layout,
    required MarketSignal? signal,
    required double time,
  }) {
    final region = signal?.region;
    if (signal == null || region == null) {
      return;
    }

    final age = (time - signal.startedAt).clamp(
      0.0,
      MarketSignal.durationSeconds,
    );
    final progress = age / MarketSignal.durationSeconds;
    if (progress >= 1) {
      return;
    }

    final appear = Curves.easeOutCubic.transform(
      (progress / 0.18).clamp(0.0, 1.0).toDouble(),
    );
    final disappear =
        1 -
        Curves.easeInCubic.transform(
          ((progress - 0.68) / 0.32).clamp(0.0, 1.0).toDouble(),
        );
    final fade = (appear * disappear).clamp(0.0, 1.0).toDouble();
    final rect = _regionRect(
      layout,
      region,
    ).inflate(layout.cellSize * (0.04 + math.sin(age * 1.7) * 0.012));
    final radius = Radius.circular(layout.cellSize * 0.34);
    final rrect = RRect.fromRectAndRadius(rect, radius);

    _paintRegionGlow(canvas, rect, rrect, fade, age);
    _paintSignalDistortion(canvas, rect, rrect, fade, age, signal.wholePrice);
    _paintScanStreaks(canvas, rect, rrect, fade, age, signal.wholePrice);
    _paintCornerFrame(canvas, rect, fade, age, layout.cellSize);
    _paintMotes(canvas, rect, fade, age, signal.wholePrice);
    _paintSignalLabel(canvas, layout, rect, region, signal, fade, age);
  }

  Rect _regionRect(BoardLayout layout, MarketSignalRegion region) {
    final endRow = region.startRow + region.size - 1;
    final endColumn = region.startColumn + region.size - 1;
    final topLeft = layout.rectForCell(region.startRow, region.startColumn);
    final bottomRight = layout.rectForCell(endRow, endColumn);

    return Rect.fromLTRB(
      topLeft.left,
      topLeft.top,
      bottomRight.right,
      bottomRight.bottom,
    ).inflate(layout.gap * 0.8);
  }

  void _paintRegionGlow(
    Canvas canvas,
    Rect rect,
    RRect rrect,
    double fade,
    double age,
  ) {
    final pulse = math.sin(age * math.pi * 1.4) * 0.5 + 0.5;
    final fillPaint = Paint()
      ..isAntiAlias = true
      ..blendMode = BlendMode.plus
      ..shader = ui.Gradient.linear(
        rect.topLeft,
        rect.bottomRight,
        [
          const Color(0xff28f7de).withValues(alpha: 0.05 * fade),
          const Color(0xff6d87ff).withValues(alpha: 0.08 * fade),
          const Color(0xffc894ff).withValues(alpha: 0.04 * fade),
        ],
        const [0.0, 0.58, 1.0],
      );
    canvas.drawRRect(rrect, fillPaint);

    final haloPaint = Paint()
      ..isAntiAlias = true
      ..blendMode = BlendMode.plus
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10 + pulse * 8
      ..color = const Color(0xff42f5dd).withValues(alpha: 0.06 * fade);
    canvas.drawRRect(rrect, haloPaint);
  }

  void _paintScanStreaks(
    Canvas canvas,
    Rect rect,
    RRect rrect,
    double fade,
    double age,
    int wholePrice,
  ) {
    canvas.save();
    canvas.clipRRect(rrect);

    final paint = Paint()
      ..isAntiAlias = true
      ..blendMode = BlendMode.plus
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.7;

    for (var i = 0; i < 5; i++) {
      final seed = _hash(wholePrice * 0.013 + i * 8.21);
      final y = rect.top + rect.height * ((seed + age * 0.055) % 1.0);
      final start = rect.left + rect.width * (0.06 + _hash(seed * 31) * 0.18);
      final end = rect.right - rect.width * (0.08 + _hash(seed * 47) * 0.22);
      final localPulse = math.sin(age * 1.8 + i * 1.3) * 0.5 + 0.5;

      paint.color =
          (i.isEven ? const Color(0xff8dfff3) : const Color(0xff8ba4ff))
              .withValues(alpha: (0.16 + localPulse * 0.14) * fade);
      canvas.drawLine(Offset(start, y), Offset(end, y), paint);
    }

    canvas.restore();
  }

  void _paintSignalDistortion(
    Canvas canvas,
    Rect rect,
    RRect rrect,
    double fade,
    double age,
    int wholePrice,
  ) {
    canvas.save();
    canvas.clipRRect(rrect);

    final bandPaint = Paint()
      ..isAntiAlias = true
      ..blendMode = BlendMode.plus;
    final shadowPaint = Paint()
      ..isAntiAlias = true
      ..blendMode = BlendMode.multiply;
    final bandHeight = rect.height / 8;

    for (var band = 0; band < 11; band++) {
      final seed = _hash(wholePrice * 0.011 + band * 4.73);
      final y =
          rect.top + rect.height * ((seed + age * (0.035 + seed * 0.018)) % 1);
      final wave = math.sin(age * 2.2 + band * 0.9);
      final offset = wave * rect.width * 0.032;
      final stretch = rect.width * (0.05 + _hash(seed * 23) * 0.07);
      final bandRect = Rect.fromLTWH(
        rect.left + offset,
        y - bandHeight * 0.5,
        rect.width + stretch,
        bandHeight,
      );

      bandPaint.shader = ui.Gradient.linear(
        bandRect.centerLeft,
        bandRect.centerRight,
        [
          const Color(0xff000000).withValues(alpha: 0),
          const Color(0xff7affef).withValues(alpha: 0.11 * fade),
          const Color(0xff8b9cff).withValues(alpha: 0.14 * fade),
          const Color(0xff000000).withValues(alpha: 0),
        ],
        const [0, 0.32, 0.68, 1],
      );
      canvas.drawRect(bandRect, bandPaint);

      shadowPaint.shader = ui.Gradient.linear(
        bandRect.centerLeft,
        bandRect.centerRight,
        [
          const Color(0xff000000).withValues(alpha: 0),
          const Color(0xff00191f).withValues(alpha: 0.08 * fade),
          const Color(0xff000000).withValues(alpha: 0),
        ],
        const [0, 0.5, 1],
      );
      canvas.drawRect(
        bandRect.translate(-offset * 0.45, bandHeight * 0.22),
        shadowPaint,
      );
    }

    canvas.restore();
  }

  void _paintCornerFrame(
    Canvas canvas,
    Rect rect,
    double fade,
    double age,
    double cellSize,
  ) {
    final corner = math.min(rect.shortestSide * 0.22, cellSize * 0.82);
    final drift = math.sin(age * 1.45) * cellSize * 0.025;
    final animatedRect = rect.deflate(drift.abs());
    final paint = Paint()
      ..isAntiAlias = true
      ..blendMode = BlendMode.plus
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.6, cellSize * 0.026)
      ..color = const Color(0xffb9fff8).withValues(alpha: 0.46 * fade);

    final glowPaint = Paint()
      ..isAntiAlias = true
      ..blendMode = BlendMode.plus
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = paint.strokeWidth * 3.2
      ..color = const Color(0xff58f6df).withValues(alpha: 0.12 * fade);

    final path = _cornerPath(animatedRect, corner);
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
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

  void _paintMotes(
    Canvas canvas,
    Rect rect,
    double fade,
    double age,
    int wholePrice,
  ) {
    final paint = Paint()
      ..isAntiAlias = true
      ..blendMode = BlendMode.plus;

    for (var i = 0; i < 18; i++) {
      final seed = wholePrice * 0.001 + i * 19.19;
      final x = (_hash(seed) + age * (0.006 + _hash(seed + 2) * 0.01)) % 1.0;
      final y = (_hash(seed + 11.7) + math.sin(age * 0.8 + i) * 0.018) % 1.0;
      final twinkle = math.sin(age * 2.1 + i * 0.77) * 0.5 + 0.5;
      final radius = 0.8 + _hash(seed + 4.1) * 1.6;
      final point = Offset(
        rect.left + x * rect.width,
        rect.top + y * rect.height,
      );

      paint.color =
          (i.isEven ? const Color(0xffd8fff8) : const Color(0xffb9c6ff))
              .withValues(alpha: (0.12 + twinkle * 0.22) * fade);
      canvas.drawCircle(point, radius, paint);
    }
  }

  void _paintSignalLabel(
    Canvas canvas,
    BoardLayout layout,
    Rect regionRect,
    MarketSignalRegion region,
    MarketSignal signal,
    double fade,
    double age,
  ) {
    final slide = (1 - fade) * layout.cellSize * 0.18;
    final sectorAu = region.size * 2;
    final titleText = signal.wholePrice > 0
        ? 'BTC ${signal.wholePrice} SIGNAL'
        : signal.message.toUpperCase();
    final title = TextPainter(
      text: TextSpan(
        text: titleText,
        style: TextStyle(
          color: const Color(0xffeffffc).withValues(alpha: 0.96 * fade),
          fontSize: (layout.cellSize * 0.16).clamp(10.0, 14.0),
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
          shadows: [
            Shadow(
              color: const Color(0xff36ffe8).withValues(alpha: 0.55 * fade),
              blurRadius: 9,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final subtitle = TextPainter(
      text: TextSpan(
        text: 'approx $sectorAu AU sector',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.70 * fade),
          fontSize: (layout.cellSize * 0.13).clamp(8.0, 11.0),
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    final padding = EdgeInsets.symmetric(
      horizontal: layout.cellSize * 0.12,
      vertical: layout.cellSize * 0.08,
    );
    final labelSize = Size(
      math.max(title.width, subtitle.width) + padding.horizontal,
      title.height + subtitle.height + padding.vertical + 2,
    );
    final labelTop = regionRect.top - labelSize.height - layout.cellSize * 0.10;
    final fallbackTop = regionRect.top + layout.cellSize * 0.12;
    final left = (regionRect.left + layout.cellSize * 0.12).clamp(
      layout.boardRect.left + 2,
      layout.boardRect.right - labelSize.width - 2,
    );
    final top =
        (labelTop >= layout.boardRect.top ? labelTop : fallbackTop) + slide;
    final labelRect = Rect.fromLTWH(
      left,
      top,
      labelSize.width,
      labelSize.height,
    );
    final labelRRect = RRect.fromRectAndRadius(
      labelRect,
      Radius.circular(layout.cellSize * 0.12),
    );

    final backPaint = Paint()
      ..isAntiAlias = true
      ..color = const Color(0xff031114).withValues(alpha: 0.54 * fade);
    canvas.drawRRect(labelRRect, backPaint);

    final strokePulse = math.sin(age * 2.1) * 0.5 + 0.5;
    final strokePaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..blendMode = BlendMode.plus
      ..color = const Color(
        0xff75fff1,
      ).withValues(alpha: (0.24 + strokePulse * 0.16) * fade);
    canvas.drawRRect(labelRRect, strokePaint);

    final textOffset = Offset(
      labelRect.left + padding.left,
      labelRect.top + padding.top,
    );
    title.paint(canvas, textOffset);
    subtitle.paint(canvas, textOffset + Offset(0, title.height + 2));
  }

  double _hash(num value) {
    return (math.sin(value * 12.9898) * 43758.5453).abs() % 1.0;
  }
}

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class PiecePipRenderer {
  const PiecePipRenderer();

  void paint(
    ui.Canvas canvas, {
    required int? value,
    required int? previousValue,
    required double transition,
    required double cellSize,
    required double time,
    required bool lifted,
    required ui.Color color,
    required ui.Offset Function(ui.Offset local) pointAt,
  }) {
    final blobs = _flowingPips(
      value: value,
      previousValue: previousValue,
      transition: transition,
    );

    _paintField(
      canvas,
      blobs: blobs,
      cellSize: cellSize,
      time: time,
      lifted: lifted,
      color: color,
      pointAt: pointAt,
    );
  }

  void _paintField(
    ui.Canvas canvas, {
    required List<_PipBlob> blobs,
    required double cellSize,
    required double time,
    required bool lifted,
    required ui.Color color,
    required ui.Offset Function(ui.Offset local) pointAt,
  }) {
    if (blobs.isEmpty) {
      return;
    }

    const minX = 0.23;
    const maxX = 0.77;
    const minY = 0.18;
    const maxY = 0.82;
    final columns = _fieldSegments(
      cellSize: cellSize,
      span: maxX - minX,
      min: 22,
      max: 40,
    );
    final rows = _fieldSegments(
      cellSize: cellSize,
      span: maxY - minY,
      min: 26,
      max: 48,
    );
    final positions = <ui.Offset>[];
    final colors = <ui.Color>[];
    final indices = <int>[];

    for (var row = 0; row <= rows; row++) {
      final y = minY + (maxY - minY) * row / rows;

      for (var column = 0; column <= columns; column++) {
        final x = minX + (maxX - minX) * column / columns;
        final local = ui.Offset(x, y);
        final warped = _animatedLocal(local, blobs, time);
        final field = _fieldAt(warped, blobs, time);
        final ripple = math.sin(time * 0.72 + x * 13.0 + y * 17.0) * 0.035;
        final alpha = _smoothStep(0.30 + ripple, 0.98 + ripple, field);

        positions.add(pointAt(warped));
        colors.add(_fieldColor(color, lifted: lifted, opacity: alpha));
      }
    }

    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        final topLeft = row * (columns + 1) + column;
        final topRight = topLeft + 1;
        final bottomLeft = topLeft + columns + 1;
        final bottomRight = bottomLeft + 1;

        indices.addAll([topLeft, bottomLeft, topRight]);
        indices.addAll([topRight, bottomLeft, bottomRight]);
      }
    }

    canvas.drawVertices(
      ui.Vertices(
        ui.VertexMode.triangles,
        positions,
        colors: colors,
        indices: indices,
      ),
      ui.BlendMode.dst,
      ui.Paint()
        ..isAntiAlias = true
        ..blendMode = ui.BlendMode.plus,
    );
  }

  ui.Color _fieldColor(
    ui.Color color, {
    required bool lifted,
    double opacity = 1,
  }) {
    final baseAlpha = lifted ? 0.66 : 0.42;

    return color.withValues(alpha: baseAlpha * opacity);
  }

  int _fieldSegments({
    required double cellSize,
    required double span,
    required int min,
    required int max,
  }) {
    const targetSamplePixels = 1.75;
    final segments = (cellSize * span / targetSamplePixels).round();

    return segments.clamp(min, max).toInt();
  }

  List<ui.Offset> _pipCenters(int value) {
    const topLeft = ui.Offset(0.36, 0.29);
    const topRight = ui.Offset(0.64, 0.29);
    const middleLeft = ui.Offset(0.36, 0.50);
    const middle = ui.Offset(0.50, 0.50);
    const middleRight = ui.Offset(0.64, 0.50);
    const bottomLeft = ui.Offset(0.36, 0.71);
    const bottomRight = ui.Offset(0.64, 0.71);

    return switch (value) {
      1 => const [middle],
      2 => const [topLeft, bottomRight],
      3 => const [topLeft, middle, bottomRight],
      4 => const [topLeft, topRight, bottomLeft, bottomRight],
      5 => const [topLeft, topRight, middle, bottomLeft, bottomRight],
      6 => const [
        topLeft,
        topRight,
        middleLeft,
        middleRight,
        bottomLeft,
        bottomRight,
      ],
      _ => const [],
    };
  }

  List<_PipBlob> _flowingPips({
    required int? value,
    required int? previousValue,
    required double transition,
  }) {
    final targetCenters = _validPipValue(value)
        ? _pipCenters(value!)
        : const <ui.Offset>[];
    final previousCenters = _validPipValue(previousValue)
        ? _pipCenters(previousValue!)
        : const <ui.Offset>[];
    final t = transition.clamp(0.0, 1.0).toDouble();

    if (previousCenters.isEmpty || previousValue == value || t >= 1) {
      return [
        for (final center in targetCenters)
          _PipBlob(center: center, radiusScale: 1, opacity: 1),
      ];
    }

    if (targetCenters.isEmpty) {
      final moveT = Curves.easeInOutCubic.transform(t);

      return [
        for (final center in previousCenters)
          _PipBlob(
            center: ui.Offset.lerp(center, const ui.Offset(0.5, 0.5), moveT)!,
            radiusScale: 1 - t * 0.45,
            opacity: 1 - t,
          ),
      ];
    }

    if (previousCenters.length > targetCenters.length) {
      return _mergingPips(
        previousCenters: previousCenters,
        targetCenters: targetCenters,
        transition: t,
      );
    }

    final moveT = Curves.easeInOutCubic.transform(math.pow(t, 1.55).toDouble());
    final bloom = math.sin(t * math.pi);
    final blobs = <_PipBlob>[];
    final usedPrevious = <int>{};
    final consumePrevious = previousCenters.length >= targetCenters.length;

    for (final target in targetCenters) {
      final sourceIndex = _nearestPipIndex(
        target,
        previousCenters,
        excluded: consumePrevious ? usedPrevious : const {},
      );
      final source = sourceIndex == null
          ? const ui.Offset(0.5, 0.5)
          : previousCenters[sourceIndex];

      if (sourceIndex != null && consumePrevious) {
        usedPrevious.add(sourceIndex);
      }

      final current = ui.Offset.lerp(source, target, moveT)!;
      final travel = (target - source).distance;

      if (travel > 0.02 && bloom > 0.001) {
        blobs.addAll(
          _pipNeck(
            from: source,
            to: current,
            transition: t,
            bloom: bloom,
            travel: travel,
          ),
        );
      }

      blobs.add(
        _PipBlob(
          center: current,
          radiusScale: (0.98 + t * 0.04 + bloom * travel * 0.22).clamp(
            0.0,
            1.28,
          ),
          opacity: (0.36 + t * 0.64).clamp(0.0, 1.0),
        ),
      );
    }

    if (consumePrevious) {
      for (var index = 0; index < previousCenters.length; index++) {
        if (usedPrevious.contains(index)) {
          continue;
        }

        final source = previousCenters[index];
        final target =
            targetCenters[_nearestPipIndex(source, targetCenters) ?? 0];

        blobs.add(
          _PipBlob(
            center: ui.Offset.lerp(source, target, moveT)!,
            radiusScale: (1 - t * 0.35).clamp(0.0, 1.0),
            opacity: ((1 - t) * 0.82).clamp(0.0, 1.0),
          ),
        );
      }
    }

    return blobs;
  }

  List<_PipBlob> _mergingPips({
    required List<ui.Offset> previousCenters,
    required List<ui.Offset> targetCenters,
    required double transition,
  }) {
    final t = transition.clamp(0.0, 1.0).toDouble();
    final moveT = Curves.easeInOutCubic.transform(math.pow(t, 1.28).toDouble());
    final bloom = math.sin(t * math.pi);
    final release = _smoothStep(0.72, 1.0, t);
    final targetBuild = _smoothStep(0.52, 1.0, t);
    final blobs = <_PipBlob>[];

    for (final source in previousCenters) {
      final target =
          targetCenters[_nearestPipIndex(source, targetCenters) ?? 0];
      final current = ui.Offset.lerp(source, target, moveT)!;
      final travel = (target - source).distance;

      if (travel > 0.02 && bloom > 0.001) {
        blobs.addAll(
          _pipNeck(
            from: source,
            to: current,
            transition: (t * 0.90).clamp(0.0, 1.0).toDouble(),
            bloom: bloom,
            travel: travel,
          ),
        );
      }

      blobs.add(
        _PipBlob(
          center: current,
          radiusScale: (1.02 - release * 0.26 + bloom * travel * 0.16).clamp(
            0.0,
            1.18,
          ),
          opacity: (0.94 * (1 - release)).clamp(0.0, 1.0),
        ),
      );
    }

    for (final target in targetCenters) {
      blobs.add(
        _PipBlob(
          center: target,
          radiusScale: (0.78 + targetBuild * 0.24).clamp(0.0, 1.04),
          opacity: targetBuild,
        ),
      );
    }

    return blobs;
  }

  List<_PipBlob> _pipNeck({
    required ui.Offset from,
    required ui.Offset to,
    required double transition,
    required double bloom,
    required double travel,
  }) {
    final sticky = 1 - _smoothStep(0.56, 1.0, transition);
    final pull = _smoothStep(0.08, 0.82, transition);
    final neckEnd = ui.Offset.lerp(from, to, (0.34 + pull * 0.66))!;
    final neckOpacity = (0.28 + bloom * 0.38) * sticky;
    final neckRadius = 0.82 + travel * 0.24;

    return [
      for (var step = 1; step <= 8; step++)
        _PipBlob(
          center: ui.Offset.lerp(from, neckEnd, step / 9)!,
          radiusScale: (neckRadius - step * 0.025).clamp(0.0, 1.12),
          opacity: (neckOpacity * (1 - step * 0.045)).clamp(0.0, 1.0),
        ),
    ];
  }

  double _fieldAt(ui.Offset local, List<_PipBlob> blobs, double time) {
    var field = 0.0;

    for (var index = 0; index < blobs.length; index++) {
      final blob = blobs[index];
      final phase = _pipPhase(blob, index);
      final center = _aliveCenter(blob.center, phase, time);
      final delta = local - center;
      final breathe = 1 + math.sin(time * 0.63 + phase) * 0.09;
      final radius = 0.058 * blob.radiusScale * breathe;
      final radiusSquared = radius * radius;
      final distanceSquared = delta.distanceSquared;
      final contribution = math.exp(-distanceSquared / (radiusSquared * 1.10));

      field += contribution * blob.opacity;
    }

    return field;
  }

  ui.Offset _animatedLocal(ui.Offset local, List<_PipBlob> blobs, double time) {
    var warp = ui.Offset.zero;

    for (var index = 0; index < blobs.length; index++) {
      final blob = blobs[index];
      final phase = _pipPhase(blob, index);
      final center = _aliveCenter(blob.center, phase, time);
      final delta = local - center;
      final radius = 0.088 * blob.radiusScale;
      final influence = math.exp(-delta.distanceSquared / (radius * radius));
      final tangent = ui.Offset(-delta.dy, delta.dx);
      final swirl = math.sin(time * 0.57 + phase) * 0.018;
      final pulse = math.cos(time * 0.41 + phase) * 0.012;

      warp += (tangent * swirl + delta * pulse) * influence * blob.opacity;
    }

    final warped = local + warp;

    return ui.Offset(
      warped.dx.clamp(0.18, 0.82).toDouble(),
      warped.dy.clamp(0.14, 0.86).toDouble(),
    );
  }

  ui.Offset _aliveCenter(ui.Offset center, double phase, double time) {
    final orbit = ui.Offset(
      math.cos(time * 0.47 + phase),
      math.sin(time * 0.37 + phase * 1.37),
    );

    return center + orbit * 0.006;
  }

  double _pipPhase(_PipBlob blob, int index) {
    return blob.center.dx * 31.0 + blob.center.dy * 47.0 + index * 1.7;
  }

  double _smoothStep(double edge0, double edge1, double value) {
    final t = ((value - edge0) / (edge1 - edge0)).clamp(0.0, 1.0).toDouble();

    return t * t * (3 - 2 * t);
  }

  int? _nearestPipIndex(
    ui.Offset origin,
    List<ui.Offset> centers, {
    Set<int> excluded = const {},
  }) {
    int? nearest;
    var shortest = double.infinity;

    for (var index = 0; index < centers.length; index++) {
      if (excluded.contains(index)) {
        continue;
      }

      final distance = (centers[index] - origin).distanceSquared;

      if (distance < shortest) {
        shortest = distance;
        nearest = index;
      }
    }

    return nearest;
  }

  bool _validPipValue(int? value) {
    return value != null && value >= 1 && value <= 6;
  }
}

class _PipBlob {
  const _PipBlob({
    required this.center,
    required this.radiusScale,
    required this.opacity,
  });

  final ui.Offset center;
  final double radiusScale;
  final double opacity;
}

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:galaxy_sweep/render/board_renderer.dart';

class PieceRenderer {
  const PieceRenderer();

  void paintPieceInFrame(
    ui.Canvas canvas, {
    required TileFrame frame,
    required double cellSize,
    required double pieceScale,
    required Color accentColor,
    bool lifted = false,
    bool applyLiftOffset = true,
    ui.Offset travelVector = ui.Offset.zero,
    double distortion = 0,
    int? distanceToNearestGalaxy,
    int? previousDistanceToNearestGalaxy,
    double pipTransition = 1,
  }) {
    final lift = lifted && applyLiftOffset
        ? _pieceLift(cellSize)
        : ui.Offset.zero;
    final pieceFrame = _shiftFrame(frame, lift);
    final pieceCenter = _sampleFramePoint(
      pieceFrame,
      const ui.Offset(0.5, 0.5),
    );
    final path = _superellipseFramePath(
      pieceFrame,
      exponent: 4.8,
      radius: pieceScale / 2,
      travelVector: travelVector,
      distortion: distortion,
    );
    final strokeWidth = math.max(0.8, cellSize * (lifted ? 0.030 : 0.018));

    _paintPieceBody(
      canvas,
      path: path,
      pieceCenter: pieceCenter,
      cellSize: cellSize,
      strokeWidth: strokeWidth,
      lifted: lifted,
      accentColor: accentColor,
    );

    _paintPipsInFrame(
      canvas,
      frame: pieceFrame,
      cellSize: cellSize,
      lifted: lifted,
      value: distanceToNearestGalaxy,
      previousValue: previousDistanceToNearestGalaxy,
      transition: pipTransition,
      accentColor: accentColor,
      travelVector: travelVector,
      distortion: distortion,
    );
  }

  void _paintPipsInFrame(
    ui.Canvas canvas, {
    required TileFrame frame,
    required double cellSize,
    required bool lifted,
    required int? value,
    required int? previousValue,
    required double transition,
    required Color accentColor,
    required ui.Offset travelVector,
    required double distortion,
  }) {
    final t = transition.clamp(0.0, 1.0).toDouble();

    if (previousValue != null && previousValue != value && t < 1) {
      for (final pipCenter in _pipCenters(previousValue)) {
        final pipPath = _pipPathInFrame(
          frame,
          center: pipCenter,
          radius: (lifted ? 0.062 : 0.056) * (1.0 - t * 0.22),
          travelVector: travelVector,
          distortion: distortion,
        );

        _paintPipPath(
          canvas,
          pipPath,
          lifted: lifted,
          color: accentColor,
          alpha: 1.0 - t,
        );
      }
    }

    if (value != null && value >= 1 && value <= 6) {
      final scale = previousValue == null || previousValue == value
          ? 1.0
          : 0.76 + t * 0.24;

      for (final pipCenter in _pipCenters(value)) {
        final pipPath = _pipPathInFrame(
          frame,
          center: pipCenter,
          radius: (lifted ? 0.062 : 0.056) * scale,
          travelVector: travelVector,
          distortion: distortion,
        );

        _paintPipPath(
          canvas,
          pipPath,
          lifted: lifted,
          color: accentColor,
          alpha: t,
        );
      }
    }
  }

  void paintPieceOnMesh(
    ui.Canvas canvas, {
    required VertexBoardControlMesh mesh,
    required ui.Offset gridPosition,
    required double cellSize,
    required double pieceScale,
    required Color accentColor,
    bool lifted = false,
    int? distanceToNearestGalaxy,
    int? previousDistanceToNearestGalaxy,
    double pipTransition = 1,
  }) {
    final lift = lifted ? _pieceLift(cellSize) : ui.Offset.zero;
    final pieceCenter =
        _sampleMeshPoint(mesh, gridPosition.dx + 0.5, gridPosition.dy + 0.5) +
        lift;
    final path = _superellipseMeshPath(
      mesh,
      gridPosition: gridPosition,
      exponent: 4.8,
      radius: pieceScale / 2,
      lift: lift,
    );
    final strokeWidth = math.max(0.8, cellSize * (lifted ? 0.030 : 0.018));

    _paintPieceBody(
      canvas,
      path: path,
      pieceCenter: pieceCenter,
      cellSize: cellSize,
      strokeWidth: strokeWidth,
      lifted: lifted,
      accentColor: accentColor,
    );

    _paintPipsOnMesh(
      canvas,
      mesh: mesh,
      gridPosition: gridPosition,
      cellSize: cellSize,
      lifted: lifted,
      lift: lift,
      value: distanceToNearestGalaxy,
      previousValue: previousDistanceToNearestGalaxy,
      transition: pipTransition,
      accentColor: accentColor,
    );
  }

  void _paintPipsOnMesh(
    ui.Canvas canvas, {
    required VertexBoardControlMesh mesh,
    required ui.Offset gridPosition,
    required double cellSize,
    required bool lifted,
    required ui.Offset lift,
    required int? value,
    required int? previousValue,
    required double transition,
    required Color accentColor,
  }) {
    final t = transition.clamp(0.0, 1.0).toDouble();

    if (previousValue != null && previousValue != value && t < 1) {
      for (final pipCenter in _pipCenters(previousValue)) {
        final pipPath = _pipPathOnMesh(
          mesh,
          gridPosition: gridPosition,
          center: pipCenter,
          radius: (lifted ? 0.062 : 0.056) * (1.0 - t * 0.22),
          lift: lift,
        );

        _paintPipPath(
          canvas,
          pipPath,
          lifted: lifted,
          color: accentColor,
          alpha: 1.0 - t,
        );
      }
    }

    if (value != null && value >= 1 && value <= 6) {
      final scale = previousValue == null || previousValue == value
          ? 1.0
          : 0.76 + t * 0.24;

      for (final pipCenter in _pipCenters(value)) {
        final pipPath = _pipPathOnMesh(
          mesh,
          gridPosition: gridPosition,
          center: pipCenter,
          radius: (lifted ? 0.062 : 0.056) * scale,
          lift: lift,
        );

        _paintPipPath(
          canvas,
          pipPath,
          lifted: lifted,
          color: accentColor,
          alpha: t,
        );
      }
    }
  }

  void _paintPieceBody(
    ui.Canvas canvas, {
    required Path path,
    required ui.Offset pieceCenter,
    required double cellSize,
    required double strokeWidth,
    required bool lifted,
    required Color accentColor,
  }) {
    canvas.drawPath(
      path.shift(ui.Offset(cellSize * 0.030, cellSize * 0.042)),
      Paint()
        ..isAntiAlias = true
        ..color = Colors.black.withValues(alpha: lifted ? 0.34 : 0.18)
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, lifted ? 9 : 5),
    );

    canvas.drawPath(
      path,
      Paint()
        ..isAntiAlias = true
        ..shader = ui.Gradient.linear(
          pieceCenter + ui.Offset(-cellSize * 0.30, -cellSize * 0.36),
          pieceCenter + ui.Offset(cellSize * 0.30, cellSize * 0.34),
          [
            const Color(0xfff7fffa).withValues(alpha: lifted ? 0.42 : 0.26),
            const Color(0xff8fffea).withValues(alpha: lifted ? 0.25 : 0.16),
            const Color(0xff0b4248).withValues(alpha: lifted ? 0.26 : 0.15),
          ],
          const [0, 0.52, 1],
        ),
    );

    canvas.drawPath(
      path,
      Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = strokeWidth
        ..color = _accentColor(accentColor, lifted: lifted)
        ..blendMode = BlendMode.plus,
    );
  }

  void _paintPipPath(
    ui.Canvas canvas,
    Path pipPath, {
    required bool lifted,
    required Color color,
    required double alpha,
  }) {
    canvas.drawPath(
      pipPath,
      Paint()
        ..isAntiAlias = true
        ..color = _pipColor(color, lifted: lifted, opacity: alpha)
        ..blendMode = BlendMode.plus,
    );
  }

  Color _accentColor(Color color, {required bool lifted, double opacity = 1}) {
    final baseAlpha = lifted ? 0.42 : 0.22;

    return color.withValues(alpha: baseAlpha * opacity);
  }

  Color _pipColor(Color color, {required bool lifted, double opacity = 1}) {
    final baseAlpha = lifted ? 0.58 : 0.34;

    return color.withValues(alpha: baseAlpha * opacity);
  }

  ui.Offset _pieceLift(double cellSize) {
    return ui.Offset(cellSize * 0.018, -cellSize * 0.075);
  }

  Path _superellipseFramePath(
    TileFrame frame, {
    required double exponent,
    required double radius,
    required ui.Offset travelVector,
    required double distortion,
  }) {
    final path = Path();
    const samples = 36;

    for (var sample = 0; sample < samples; sample++) {
      final local = _superellipseLocalPoint(
        sample / samples,
        exponent: exponent,
        radius: radius,
      );
      final point = _sampleFramePoint(
        frame,
        _distortedLocalPoint(
          local,
          travelVector: travelVector,
          distortion: distortion,
        ),
      );

      if (sample == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    return path..close();
  }

  Path _pipPathInFrame(
    TileFrame frame, {
    required ui.Offset center,
    required double radius,
    required ui.Offset travelVector,
    required double distortion,
  }) {
    final path = Path();
    const samples = 14;

    for (var sample = 0; sample < samples; sample++) {
      final angle = sample / samples * math.pi * 2;
      final local =
          center +
          ui.Offset(math.cos(angle) * radius, math.sin(angle) * radius);
      final point = _sampleFramePoint(
        frame,
        _distortedLocalPoint(
          local,
          travelVector: travelVector,
          distortion: distortion,
        ),
      );

      if (sample == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    return path..close();
  }

  Path _superellipseMeshPath(
    VertexBoardControlMesh mesh, {
    required ui.Offset gridPosition,
    required double exponent,
    required double radius,
    required ui.Offset lift,
  }) {
    final path = Path();
    const samples = 36;

    for (var sample = 0; sample < samples; sample++) {
      final local = _superellipseLocalPoint(
        sample / samples,
        exponent: exponent,
        radius: radius,
      );
      final gridX = gridPosition.dx + local.dx;
      final gridY = gridPosition.dy + local.dy;
      final point = _sampleMeshPoint(mesh, gridX, gridY) + lift;

      if (sample == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    return path..close();
  }

  Path _pipPathOnMesh(
    VertexBoardControlMesh mesh, {
    required ui.Offset gridPosition,
    required ui.Offset center,
    required double radius,
    required ui.Offset lift,
  }) {
    final path = Path();
    const samples = 14;

    for (var sample = 0; sample < samples; sample++) {
      final angle = sample / samples * math.pi * 2;
      final point =
          _sampleMeshPoint(
            mesh,
            gridPosition.dx + center.dx + math.cos(angle) * radius,
            gridPosition.dy + center.dy + math.sin(angle) * radius,
          ) +
          lift;

      if (sample == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    return path..close();
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

  ui.Offset _superellipseLocalPoint(
    double t, {
    required double exponent,
    required double radius,
  }) {
    final angle = -math.pi / 2 + t * math.pi * 2;
    final cosValue = math.cos(angle);
    final sinValue = math.sin(angle);
    final power = 2 / exponent;

    return ui.Offset(
      0.5 + radius * cosValue.sign * math.pow(cosValue.abs(), power).toDouble(),
      0.5 + radius * sinValue.sign * math.pow(sinValue.abs(), power).toDouble(),
    );
  }

  ui.Offset _sampleFramePoint(TileFrame frame, ui.Offset local) {
    final top = ui.Offset.lerp(frame.topLeft, frame.topRight, local.dx)!;
    final bottom = ui.Offset.lerp(
      frame.bottomLeft,
      frame.bottomRight,
      local.dx,
    )!;

    return ui.Offset.lerp(top, bottom, local.dy)!;
  }

  ui.Offset _sampleMeshPoint(
    VertexBoardControlMesh mesh,
    double gridX,
    double gridY,
  ) {
    final boardSize = mesh.dimension;
    final clampedX = gridX.clamp(0.0, boardSize.toDouble());
    final clampedY = gridY.clamp(0.0, boardSize.toDouble());
    final column = clampedX.floor().clamp(0, boardSize - 1);
    final row = clampedY.floor().clamp(0, boardSize - 1);
    final tx = clampedX - column;
    final ty = clampedY - row;
    final vertexStart = (row * boardSize + column) * 4;
    final topLeft = mesh.positions[vertexStart];
    final topRight = mesh.positions[vertexStart + 1];
    final bottomLeft = mesh.positions[vertexStart + 2];
    final bottomRight = mesh.positions[vertexStart + 3];
    final top = ui.Offset.lerp(topLeft, topRight, tx)!;
    final bottom = ui.Offset.lerp(bottomLeft, bottomRight, tx)!;

    return ui.Offset.lerp(top, bottom, ty)!;
  }

  ui.Offset _distortedLocalPoint(
    ui.Offset local, {
    required ui.Offset travelVector,
    required double distortion,
  }) {
    final distance = travelVector.distance;

    if (distortion <= 0.001 || distance <= 0.001) {
      return local;
    }

    final direction = ui.Offset(
      travelVector.dx / distance,
      travelVector.dy / distance,
    );
    final normal = ui.Offset(-direction.dy, direction.dx);
    final centered = local - const ui.Offset(0.5, 0.5);
    final along = centered.dx * direction.dx + centered.dy * direction.dy;
    final across = centered.dx * normal.dx + centered.dy * normal.dy;
    final elasticPull = direction * (-along * distortion * 0.34);
    final ripple =
        normal * (math.sin(across * math.pi * 2.0) * distortion * 0.12);
    final distorted = local + elasticPull + ripple;

    return ui.Offset(
      distorted.dx.clamp(-0.15, 1.15).toDouble(),
      distorted.dy.clamp(-0.15, 1.15).toDouble(),
    );
  }

  TileFrame _shiftFrame(TileFrame frame, ui.Offset offset) {
    return TileFrame(
      center: frame.center + offset,
      topLeft: frame.topLeft + offset,
      topRight: frame.topRight + offset,
      bottomLeft: frame.bottomLeft + offset,
      bottomRight: frame.bottomRight + offset,
    );
  }
}

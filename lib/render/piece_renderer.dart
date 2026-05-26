import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:galaxy_sweep/render/board_renderer.dart';
import 'package:galaxy_sweep/render/piece_pip_renderer.dart';

class PieceRenderer {
  const PieceRenderer();

  static const _pipRenderer = PiecePipRenderer();

  void paintPieceInFrame(
    ui.Canvas canvas, {
    required TileFrame frame,
    required double cellSize,
    required double time,
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
      time: time,
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
    required double time,
    required bool lifted,
    required int? value,
    required int? previousValue,
    required double transition,
    required Color accentColor,
    required ui.Offset travelVector,
    required double distortion,
  }) {
    _pipRenderer.paint(
      canvas,
      value: value,
      previousValue: previousValue,
      transition: transition,
      cellSize: cellSize,
      time: time,
      lifted: lifted,
      color: accentColor,
      pointAt: (local) => _sampleFramePoint(
        frame,
        _distortedLocalPoint(
          local,
          travelVector: travelVector,
          distortion: distortion,
        ),
      ),
    );
  }

  void paintPieceOnMesh(
    ui.Canvas canvas, {
    required VertexBoardControlMesh mesh,
    required ui.Offset gridPosition,
    required double cellSize,
    required double time,
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
      time: time,
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
    required double time,
    required bool lifted,
    required ui.Offset lift,
    required int? value,
    required int? previousValue,
    required double transition,
    required Color accentColor,
  }) {
    _pipRenderer.paint(
      canvas,
      value: value,
      previousValue: previousValue,
      transition: transition,
      cellSize: cellSize,
      time: time,
      lifted: lifted,
      color: accentColor,
      pointAt: (local) =>
          _sampleMeshPoint(
            mesh,
            gridPosition.dx + local.dx,
            gridPosition.dy + local.dy,
          ) +
          lift,
    );
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

  Color _accentColor(Color color, {required bool lifted, double opacity = 1}) {
    final baseAlpha = lifted ? 0.42 : 0.22;

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

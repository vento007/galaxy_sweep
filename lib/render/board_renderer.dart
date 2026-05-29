import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/animation.dart';

typedef VertexTileMorphProvider =
    VertexTileMorph Function(int row, int column, double time);

enum VertexTileShape { roundedSquare, circle }

class VertexTileMorph {
  const VertexTileMorph({required this.shape, required this.amount});

  static const none = VertexTileMorph(
    shape: VertexTileShape.roundedSquare,
    amount: 0,
  );

  final VertexTileShape shape;
  final double amount;
}

class VertexBoardControlMesh {
  const VertexBoardControlMesh({
    required this.dimension,
    required this.boardRect,
    required this.positions,
    required this.colors,
    required this.frames,
  });

  final int dimension;
  final ui.Rect boardRect;
  final List<ui.Offset> positions;
  final List<ui.Color> colors;
  final List<TileFrame> frames;
}

class TileFrame {
  const TileFrame({
    required this.center,
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  });

  final ui.Offset center;
  final ui.Offset topLeft;
  final ui.Offset topRight;
  final ui.Offset bottomLeft;
  final ui.Offset bottomRight;
}

class VertexBoardGeometry {
  const VertexBoardGeometry({
    required this.positions,
    required this.colors,
    required this.indices,
  });

  final List<ui.Offset> positions;
  final List<ui.Color> colors;
  final List<int> indices;

  bool get isDrawable =>
      positions.isNotEmpty &&
      positions.length == colors.length &&
      indices.length >= 3 &&
      indices.length % 3 == 0 &&
      indices.every((index) => index >= 0 && index < positions.length) &&
      positions.every(_isFiniteOffset);
}

class VertexBoardRenderer {
  const VertexBoardRenderer({this.tileFanSegments = defaultTileFanSegments});

  static const defaultTileFanSegments = 24;

  final int tileFanSegments;

  int get tileVertexCountPerCell => 1 + tileFanSegments * 3;

  int get tileTriangleCountPerCell => tileFanSegments * 5;

  void paintTiles(
    ui.Canvas canvas,
    VertexBoardControlMesh mesh,
    double time, {
    required VertexTileMorphProvider morphAt,
    double edgeVignette = 0,
    bool useSquircleTiles = false,
  }) {
    final geometry = buildTileGeometry(
      mesh,
      time,
      morphAt: morphAt,
      edgeVignette: edgeVignette,
      useSquircleTiles: useSquircleTiles,
    );

    if (!geometry.isDrawable) {
      return;
    }

    canvas.drawVertices(
      ui.Vertices(
        ui.VertexMode.triangles,
        geometry.positions,
        colors: geometry.colors,
        indices: geometry.indices,
      ),
      ui.BlendMode.dst,
      ui.Paint()..isAntiAlias = true,
    );
  }

  VertexBoardGeometry buildTileGeometry(
    VertexBoardControlMesh mesh,
    double time, {
    required VertexTileMorphProvider morphAt,
    double edgeVignette = 0,
    bool useSquircleTiles = false,
  }) {
    final positions = <ui.Offset>[];
    final colors = <ui.Color>[];
    final indices = <int>[];
    final dimension = mesh.dimension;
    final cellSize = mesh.boardRect.width / dimension;
    final edgeFeather = (1.15 / cellSize).clamp(0.009, 0.025).toDouble();

    for (
      var vertexStart = 0;
      vertexStart + 3 < mesh.positions.length;
      vertexStart += 4
    ) {
      if (vertexStart + 3 >= mesh.colors.length) {
        break;
      }

      final tileIndex = vertexStart ~/ 4;
      final row = tileIndex ~/ dimension;
      final column = tileIndex % dimension;

      if (row >= dimension) {
        break;
      }

      _appendTile(
        positions,
        colors,
        indices,
        topLeft: mesh.positions[vertexStart],
        topRight: mesh.positions[vertexStart + 1],
        bottomLeft: mesh.positions[vertexStart + 2],
        bottomRight: mesh.positions[vertexStart + 3],
        topLeftColor: mesh.colors[vertexStart],
        topRightColor: mesh.colors[vertexStart + 1],
        bottomLeftColor: mesh.colors[vertexStart + 2],
        bottomRightColor: mesh.colors[vertexStart + 3],
        time: time,
        morph: morphAt(row, column, time),
        edgeFeather: edgeFeather,
        edgeVignette: edgeVignette,
        useSquircleTiles: useSquircleTiles,
      );
    }

    return VertexBoardGeometry(
      positions: positions,
      colors: colors,
      indices: indices,
    );
  }

  void _appendTile(
    List<ui.Offset> positions,
    List<ui.Color> colors,
    List<int> indices, {
    required ui.Offset topLeft,
    required ui.Offset topRight,
    required ui.Offset bottomLeft,
    required ui.Offset bottomRight,
    required ui.Color topLeftColor,
    required ui.Color topRightColor,
    required ui.Color bottomLeftColor,
    required ui.Color bottomRightColor,
    required double time,
    required VertexTileMorph morph,
    required double edgeFeather,
    required double edgeVignette,
    required bool useSquircleTiles,
  }) {
    const centerLocal = ui.Offset(0.5, 0.5);
    final center = _mapTileLocalPoint(
      topLeft,
      topRight,
      bottomRight,
      bottomLeft,
      centerLocal,
    );

    if (!_isFiniteOffset(center)) {
      return;
    }

    final centerColor = _tileColorAtLocal(
      topLeftColor,
      topRightColor,
      bottomRightColor,
      bottomLeftColor,
      centerLocal,
    );
    final centerIndex = positions.length;
    final innerStart = centerIndex + 1;
    final midStart = innerStart + tileFanSegments;
    final outerStart = midStart + tileFanSegments;

    positions.add(center);
    colors.add(centerColor);

    for (var sample = 0; sample < tileFanSegments; sample++) {
      final edgeT = sample / tileFanSegments;
      final innerLocal = _morphedTileLocalPoint(morph, edgeT, useSquircleTiles);
      final roughness = _edgeVignetteRoughness(innerLocal, edgeT, time);
      final inner = _mapTileLocalPoint(
        topLeft,
        topRight,
        bottomRight,
        bottomLeft,
        innerLocal,
      );

      if (!_isFiniteOffset(inner)) {
        positions.length = centerIndex;
        colors.length = centerIndex;
        return;
      }

      positions.add(inner);
      colors.add(
        _vignetteEdgeColor(
          _tileColorAtLocal(
            topLeftColor,
            topRightColor,
            bottomRightColor,
            bottomLeftColor,
            innerLocal,
          ),
          edgeVignette,
          roughness: roughness,
          alphaScale: 0.40,
        ),
      );
    }

    for (var sample = 0; sample < tileFanSegments; sample++) {
      final edgeT = sample / tileFanSegments;
      final innerLocal = _morphedTileLocalPoint(morph, edgeT, useSquircleTiles);
      final midLocal = ui.Offset.lerp(
        const ui.Offset(0.5, 0.5),
        innerLocal,
        0.58,
      )!;
      final mid = _mapTileLocalPoint(
        topLeft,
        topRight,
        bottomRight,
        bottomLeft,
        midLocal,
      );

      if (!_isFiniteOffset(mid)) {
        positions.length = centerIndex;
        colors.length = centerIndex;
        return;
      }

      positions.add(mid);
      colors.add(
        _vignetteEdgeColor(
          _tileColorAtLocal(
            topLeftColor,
            topRightColor,
            bottomRightColor,
            bottomLeftColor,
            midLocal,
          ),
          edgeVignette,
          roughness: _edgeVignetteRoughness(innerLocal, edgeT, time),
          alphaScale: 0.13,
        ),
      );
    }

    for (var sample = 0; sample < tileFanSegments; sample++) {
      final innerLocal = _morphedTileLocalPoint(
        morph,
        sample / tileFanSegments,
        useSquircleTiles,
      );
      final outerLocal = _expandTileLocalFromCenter(innerLocal, edgeFeather);
      final outer = _mapTileLocalPoint(
        topLeft,
        topRight,
        bottomRight,
        bottomLeft,
        outerLocal,
      );

      if (!_isFiniteOffset(outer)) {
        positions.length = centerIndex;
        colors.length = centerIndex;
        return;
      }

      positions.add(outer);
      colors.add(
        _tileColorAtLocal(
          topLeftColor,
          topRightColor,
          bottomRightColor,
          bottomLeftColor,
          innerLocal,
        ).withValues(alpha: 0),
      );
    }

    for (var sample = 0; sample < tileFanSegments; sample++) {
      final next = (sample + 1) % tileFanSegments;
      final inner = innerStart + sample;
      final nextInner = innerStart + next;
      final mid = midStart + sample;
      final nextMid = midStart + next;
      final outer = outerStart + sample;
      final nextOuter = outerStart + next;

      indices.addAll([centerIndex, mid, nextMid]);
      indices.addAll([mid, inner, nextMid]);
      indices.addAll([nextMid, inner, nextInner]);
      indices.addAll([inner, outer, nextInner]);
      indices.addAll([nextInner, outer, nextOuter]);
    }
  }

  ui.Offset _morphedTileLocalPoint(
    VertexTileMorph morph,
    double t,
    bool useSquircleTiles,
  ) {
    final morphAmount = morph.amount.clamp(0.0, 1.0).toDouble();
    final easedMorph = Curves.easeOutCubic.transform(morphAmount);
    final from = _tileShapePoint(
      VertexTileShape.roundedSquare,
      t,
      useSquircleTiles,
    );
    final to = _tileShapePoint(morph.shape, t, useSquircleTiles);

    return ui.Offset.lerp(from, to, easedMorph)!;
  }

  ui.Offset _tileShapePoint(
    VertexTileShape shape,
    double t,
    bool useSquircleTiles,
  ) {
    return switch (shape) {
      VertexTileShape.roundedSquare => _superellipsePoint(
        t,
        useSquircleTiles ? 4.0 : 5.4,
        0.48,
      ),
      VertexTileShape.circle => _superellipsePoint(t, 2.0, 0.47),
    };
  }

  ui.Offset _superellipsePoint(double t, double exponent, double radius) {
    final angle = -math.pi / 2 + t * math.pi * 2;
    final cosValue = math.cos(angle);
    final sinValue = math.sin(angle);
    final power = 2 / exponent;

    return ui.Offset(
      0.5 + radius * cosValue.sign * math.pow(cosValue.abs(), power).toDouble(),
      0.5 + radius * sinValue.sign * math.pow(sinValue.abs(), power).toDouble(),
    );
  }

  ui.Offset _expandTileLocalFromCenter(ui.Offset local, double amount) {
    const center = ui.Offset(0.5, 0.5);
    final vector = local - center;
    final distance = vector.distance;

    if (distance <= 0.001) {
      return local;
    }

    return center + vector * ((distance + amount) / distance);
  }

  ui.Offset _mapTileLocalPoint(
    ui.Offset topLeft,
    ui.Offset topRight,
    ui.Offset bottomRight,
    ui.Offset bottomLeft,
    ui.Offset local,
  ) {
    final top = ui.Offset.lerp(topLeft, topRight, local.dx)!;
    final bottom = ui.Offset.lerp(bottomLeft, bottomRight, local.dx)!;

    return ui.Offset.lerp(top, bottom, local.dy)!;
  }

  ui.Color _tileColorAtLocal(
    ui.Color topLeft,
    ui.Color topRight,
    ui.Color bottomRight,
    ui.Color bottomLeft,
    ui.Offset local,
  ) {
    final top = ui.Color.lerp(topLeft, topRight, local.dx)!;
    final bottom = ui.Color.lerp(bottomLeft, bottomRight, local.dx)!;

    return ui.Color.lerp(top, bottom, local.dy)!;
  }

  ui.Color _vignetteEdgeColor(
    ui.Color color,
    double edgeVignette, {
    required double roughness,
    required double alphaScale,
  }) {
    if (edgeVignette <= 0) {
      return color;
    }

    return ui.Color.alphaBlend(
      const ui.Color(0xff061013).withValues(
        alpha: (edgeVignette * alphaScale * roughness).clamp(0.0, 0.74),
      ),
      color,
    );
  }

  double _edgeVignetteRoughness(ui.Offset local, double t, double time) {
    final centered = local - const ui.Offset(0.5, 0.5);
    final cornerWeight = (centered.dx.abs() * centered.dy.abs() * 4.8).clamp(
      0.0,
      1.0,
    );
    final broadWave = math.sin(t * math.pi * 4.0 + time * 0.18) * 0.5 + 0.5;
    final grain =
        math.sin(local.dx * 31.0 + local.dy * 43.0 + time * 0.11) * 0.5 + 0.5;

    return (0.68 + broadWave * 0.20 + grain * 0.18 + cornerWeight * 0.26)
        .clamp(0.58, 1.24)
        .toDouble();
  }
}

bool _isFiniteOffset(ui.Offset offset) =>
    offset.dx.isFinite && offset.dy.isFinite;

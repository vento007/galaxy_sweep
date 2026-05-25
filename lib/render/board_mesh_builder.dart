import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:galaxy_sweep/game/board/board_layout.dart';
import 'package:galaxy_sweep/models/board_model.dart';
import 'package:galaxy_sweep/render/board_renderer.dart';
import 'package:galaxy_sweep/render/galaxy_explosion.dart';

class BoardMeshBuilder {
  const BoardMeshBuilder();

  static const _palette = [
    Color(0xff6b214d),
    Color(0xff8b4737),
    Color(0xff896b37),
    Color(0xff477a54),
    Color(0xff047a71),
    Color(0xff195f7a),
    Color(0xff3c4a74),
    Color(0xff56325f),
  ];

  VertexBoardControlMesh build({
    required BoardModel board,
    required BoardLayout layout,
    required double time,
    required double surfaceBoost,
    required List<ActiveBlast> blasts,
    required List<TileInfluence> influences,
  }) {
    final positions = <Offset>[];
    final colors = <Color>[];
    final frames = <TileFrame>[];

    for (final cell in board.cells) {
      final row = cell.row;
      final column = cell.column;
      final index = board.findIndex(row, column);
      final u = (column + 0.5) / board.boardSize;
      final v = (row + 0.5) / board.boardSize;
      final energy = _tileEnergy(
        row: row,
        column: column,
        u: u,
        v: v,
        time: time,
        revealed: board.isGalaxyRevealedAtCell(index),
      );

      final frame = _tileFrame(
        layout: layout,
        row: row,
        column: column,
        time: time,
        energy: energy,
        blasts: blasts,
        influences: influences,
      );

      frames.add(frame);
      positions.addAll([
        frame.topLeft,
        frame.topRight,
        frame.bottomLeft,
        frame.bottomRight,
      ]);
      colors.addAll(
        _tileColors(
          u: u,
          v: v,
          time: time,
          energy: energy,
          surfaceBoost: surfaceBoost,
        ),
      );
    }

    return VertexBoardControlMesh(
      dimension: board.boardSize,
      boardRect: layout.boardRect,
      positions: positions,
      colors: colors,
      frames: frames,
    );
  }

  double _tileEnergy({
    required int row,
    required int column,
    required double u,
    required double v,
    required double time,
    required bool revealed,
  }) {
    final baseX = u * 2 - 1;
    final baseY = v * 2 - 1;
    final scan = math.sin((row + column) * 0.62 - time * 2.15);
    final ripple = math.cos(
      math.sqrt(baseX * baseX + baseY * baseY) * 8.2 - time * 2.8,
    );
    final drift =
        math.sin(row * 0.84 + time * 0.86) * 0.5 +
        math.cos(column * 0.72 - time * 0.74) * 0.5;
    final revealBoost = revealed ? 0.28 : 0.0;

    return ((scan * 0.45 + ripple * 0.35 + drift * 0.20).abs() + revealBoost)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  TileFrame _tileFrame({
    required BoardLayout layout,
    required int row,
    required int column,
    required double time,
    required double energy,
    required List<ActiveBlast> blasts,
    required List<TileInfluence> influences,
  }) {
    final rect = layout.rectForCell(row, column);
    final cellSize = layout.cellSize;
    final recoil = explosionRecoil(rect.center, blasts, cellSize);
    final localPhase = row * 0.91 - column * 0.54;
    final localPulse = math.sin(time * 1.7 + localPhase);
    final plateFloat = math.sin(time * 0.82 + row * 1.37 + column * 0.73);
    final slide = Offset(
      (math.sin(row * 0.64 + time * 0.72) * 0.052 + plateFloat * 0.018) *
          cellSize,
      (math.cos(column * 0.58 - time * 0.68) * 0.052 - plateFloat * 0.016) *
          cellSize,
    );
    final halfExtent = rect.shortestSide * (0.50 + energy * 0.022);
    final skew = (localPulse * 0.014 + plateFloat * 0.005) * cellSize;
    final baseCenter = rect.center + slide + recoil;
    final centerPull = _influenceOffset(
      baseCenter,
      cellSize: cellSize,
      influences: influences,
      scale: 0.32,
    );
    final center = baseCenter + centerPull;

    final topLeft = center +
        Offset(-halfExtent - skew, -halfExtent) +
        _influenceOffset(
          center + Offset(-halfExtent - skew, -halfExtent),
          cellSize: cellSize,
          influences: influences,
        );
    final topRight = center +
        Offset(halfExtent, -halfExtent + skew) +
        _influenceOffset(
          center + Offset(halfExtent, -halfExtent + skew),
          cellSize: cellSize,
          influences: influences,
        );
    final bottomLeft = center +
        Offset(-halfExtent, halfExtent - skew) +
        _influenceOffset(
          center + Offset(-halfExtent, halfExtent - skew),
          cellSize: cellSize,
          influences: influences,
        );
    final bottomRight = center +
        Offset(halfExtent + skew, halfExtent) +
        _influenceOffset(
          center + Offset(halfExtent + skew, halfExtent),
          cellSize: cellSize,
          influences: influences,
        );

    return TileFrame(
      center: center,
      topLeft: topLeft,
      topRight: topRight,
      bottomLeft: bottomLeft,
      bottomRight: bottomRight,
    );
  }

  Offset _influenceOffset(
    Offset point, {
    required double cellSize,
    required List<TileInfluence> influences,
    double scale = 1.0,
  }) {
    if (influences.isEmpty) {
      return Offset.zero;
    }

    final radius = cellSize * 2.35;
    final maxPull = cellSize * 0.039 * scale;
    var total = Offset.zero;

    for (final influence in influences) {
      final delta = influence.center - point;
      final distance = delta.distance;
      if (distance <= 0.0001 || distance >= radius) {
        continue;
      }

      final proximity = 1.0 - distance / radius;
      final falloff = proximity * proximity * (3.0 - 2.0 * proximity);
      final pull =
          maxPull * influence.strength.clamp(0.0, 1.0) * falloff;
      total += delta / distance * pull;
    }

    if (total.distance <= maxPull) {
      return total;
    }

    return total / total.distance * maxPull;
  }

  List<Color> _tileColors({
    required double u,
    required double v,
    required double time,
    required double energy,
    required double surfaceBoost,
  }) {
    final huePosition =
        (u * 0.48 + v * 0.34 + energy * 0.28 + time * 0.024) % 1.0;
    final baseColor = _samplePalette(
      huePosition,
      _boostAlpha(0.64 + energy * 0.30, surfaceBoost),
    );

    return [
      _boostColor(
        Color.alphaBlend(
          const Color(0xffffffff).withValues(alpha: 0.12),
          baseColor,
        ),
        surfaceBoost,
      ),
      _boostColor(baseColor, surfaceBoost),
      _boostColor(
        _samplePalette(
          huePosition + 0.08,
          _boostAlpha(0.56 + energy * 0.28, surfaceBoost),
        ),
        surfaceBoost,
      ),
      _boostColor(
        _samplePalette(
          huePosition + 0.15,
          _boostAlpha(0.62 + energy * 0.30, surfaceBoost),
        ),
        surfaceBoost,
      ),
    ];
  }

  Color _boostColor(Color color, double surfaceBoost) {
    final boost = surfaceBoost.clamp(0.0, 1.0);
    final multiplier = 1.0 + boost * 0.75;

    return color.withValues(
      red: (color.r * multiplier).clamp(0.0, 1.0),
      green: (color.g * multiplier).clamp(0.0, 1.0),
      blue: (color.b * multiplier).clamp(0.0, 1.0),
    );
  }

  double _boostAlpha(double alpha, double surfaceBoost) {
    final boost = surfaceBoost.clamp(0.0, 1.0);

    return alpha + (1 - alpha) * boost;
  }

  Color _samplePalette(double value, double alpha) {
    final scaled = value * _palette.length;
    final lower = scaled.floor() % _palette.length;
    final upper = (lower + 1) % _palette.length;
    final t = scaled - scaled.floor();

    return Color.lerp(
      _palette[lower],
      _palette[upper],
      t,
    )!.withValues(alpha: alpha.clamp(0.0, 1.0));
  }
}

class TileInfluence {
  const TileInfluence({
    required this.center,
    required this.strength,
  });

  final Offset center;
  final double strength;
}

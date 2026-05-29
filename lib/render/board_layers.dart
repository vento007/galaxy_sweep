import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:galaxy_sweep/game/board/board_layout.dart';
import 'package:galaxy_sweep/models/board_model.dart';
import 'package:galaxy_sweep/models/galaxy_blast.dart';
import 'package:galaxy_sweep/models/piece_model.dart';
import 'package:galaxy_sweep/models/piece_visual_state.dart';
import 'package:galaxy_sweep/render/board_renderer.dart';
import 'package:galaxy_sweep/render/explosion_renderer.dart';
import 'package:galaxy_sweep/render/galaxy_explosion.dart';
import 'package:galaxy_sweep/render/piece_renderer.dart';
import 'package:galaxy_sweep/render/render_config.dart';
import 'package:galaxy_sweep/render/reveal_renderer.dart';
import 'package:galaxy_sweep/render/tile_shader_renderer.dart';

class BoardSurfaceLayer {
  const BoardSurfaceLayer();

  static const _defaultRenderer = VertexBoardRenderer();
  static const _squircleRenderer = VertexBoardRenderer(tileFanSegments: 48);
  static const _shaderRenderer = TileShaderRenderer();

  void paint(
    ui.Canvas canvas, {
    required ui.Size canvasSize,
    required BoardLayout layout,
    required VertexBoardControlMesh mesh,
    required List<ActiveBlast> blasts,
    required RenderConfig renderConfig,
    required ui.FragmentProgram? tileNebulaProgram,
    required ui.FragmentProgram? tileStarsProgram,
    required double time,
  }) {
    final renderer = renderConfig.useSquircleTiles
        ? _squircleRenderer
        : _defaultRenderer;

    renderer.paintTiles(
      canvas,
      mesh,
      0,
      morphAt: (row, column, time) => VertexTileMorph.none,
      edgeVignette: renderConfig.tileVignette,
      useSquircleTiles: renderConfig.useSquircleTiles,
    );

    _shaderRenderer.paintNebula(
      canvas,
      canvasSize: canvasSize,
      mesh: mesh,
      program: tileNebulaProgram,
      blasts: blasts,
      time: time,
      paletteIndex: renderConfig.tileColorPalette.shaderIndex,
      gapFraction: (layout.gap / layout.cellSize).clamp(0.0, 0.48),
      glowIntensity: renderConfig.tileGlowIntensity,
      nebulaIntensity: renderConfig.tileNebulaIntensity,
      sheenIntensity: renderConfig.tileSheenIntensity,
      grainIntensity: renderConfig.tileGrainIntensity,
    );

    _shaderRenderer.paintStars(
      canvas,
      canvasSize: canvasSize,
      mesh: mesh,
      program: tileStarsProgram,
      time: time,
      gapFraction: (layout.gap / layout.cellSize).clamp(0.0, 0.48),
      intensity: renderConfig.tileStarsIntensity,
    );
  }
}

class PieceLayer {
  const PieceLayer();

  static const _pieceRenderer = PieceRenderer();
  static const _pipChangeDuration = 1.25;
  static const _illegalMovePipColor = Color(0xffff5a66);
  static final _pipAnimations = <int, _PipAnimation>{};

  void paint(
    ui.Canvas canvas, {
    required BoardModel board,
    required BoardLayout layout,
    required VertexBoardControlMesh mesh,
    required RenderConfig renderConfig,
    required double time,
  }) {
    for (final piece in board.pieces) {
      if (piece.visualState is PieceIdle) {
        _paintIdlePiece(
          canvas,
          board: board,
          layout: layout,
          mesh: mesh,
          piece: piece,
          renderConfig: renderConfig,
          time: time,
        );
      }
    }

    for (final piece in board.pieces) {
      if (piece.visualState is PieceDragging) {
        _paintDraggingPiece(
          canvas,
          board: board,
          layout: layout,
          mesh: mesh,
          piece: piece,
          renderConfig: renderConfig,
          time: time,
        );
      }
    }

    for (final piece in board.pieces) {
      if (piece.visualState is PieceMoving) {
        _paintMovingPiece(
          canvas,
          board: board,
          layout: layout,
          mesh: mesh,
          piece: piece,
          renderConfig: renderConfig,
          time: time,
        );
      }
    }
  }

  void _paintIdlePiece(
    ui.Canvas canvas, {
    required BoardModel board,
    required BoardLayout layout,
    required VertexBoardControlMesh mesh,
    required BoardPiece piece,
    required RenderConfig renderConfig,
    required double time,
  }) {
    final pips = _pipsForPiece(
      pieceId: piece.id,
      value: board.distanceToNearestGalaxy(piece.cellIndex),
      time: time,
    );

    _pieceRenderer.paintPieceInFrame(
      canvas,
      frame: mesh.frames[piece.cellIndex],
      cellSize: layout.cellSize,
      time: time,
      pieceScale: renderConfig.pieceScale,
      accentColor: _defaultAccentColor(renderConfig),
      distanceToNearestGalaxy: pips.value,
      previousDistanceToNearestGalaxy: pips.previousValue,
      pipTransition: pips.transition,
    );
  }

  void _paintDraggingPiece(
    ui.Canvas canvas, {
    required BoardModel board,
    required BoardLayout layout,
    required VertexBoardControlMesh mesh,
    required BoardPiece piece,
    required RenderConfig renderConfig,
    required double time,
  }) {
    final visualState = piece.visualState;
    if (visualState is! PieceDragging) {
      return;
    }

    final pips = _pipsForPiece(
      pieceId: piece.id,
      value: board.distanceToNearestGalaxy(piece.cellIndex),
      time: time,
    );
    final center = visualState.pointerPosition - visualState.grabOffset;
    final gridPosition = _gridPositionForCenter(
      layout,
      center - _pieceLift(layout),
    );

    _pieceRenderer.paintPieceOnMesh(
      canvas,
      mesh: mesh,
      gridPosition: gridPosition,
      cellSize: layout.cellSize,
      time: time,
      pieceScale: renderConfig.pieceScale,
      accentColor: _draggingAccentColor(
        board,
        piece: piece,
        visualState: visualState,
        renderConfig: renderConfig,
      ),
      lifted: true,
      distanceToNearestGalaxy: pips.value,
      previousDistanceToNearestGalaxy: pips.previousValue,
      pipTransition: pips.transition,
    );
  }

  void _paintMovingPiece(
    ui.Canvas canvas, {
    required BoardModel board,
    required BoardLayout layout,
    required VertexBoardControlMesh mesh,
    required BoardPiece piece,
    required RenderConfig renderConfig,
    required double time,
  }) {
    final visualState = piece.visualState;
    if (visualState is! PieceMoving) {
      return;
    }

    final pips = _pipsForPiece(
      pieceId: piece.id,
      value: visualState.displayDistance,
      time: time,
    );
    final frame = _movingFrameForPiece(layout, mesh, visualState, time);
    final travelVector = _movingTravelVector(layout, mesh, visualState);
    final distortion = _movingDistortion(layout, mesh, visualState, time);

    _pieceRenderer.paintPieceInFrame(
      canvas,
      frame: frame,
      cellSize: layout.cellSize,
      time: time,
      pieceScale: renderConfig.pieceScale,
      accentColor: _defaultAccentColor(renderConfig),
      lifted: true,
      applyLiftOffset: false,
      travelVector: travelVector,
      distortion: distortion,
      distanceToNearestGalaxy: pips.value,
      previousDistanceToNearestGalaxy: pips.previousValue,
      pipTransition: pips.transition,
    );
  }

  Color _defaultAccentColor(RenderConfig renderConfig) {
    const palette = [
      Color(0xffffffff),
      Color(0xff8fffea),
      Color(0xffa5b4ff),
      Color(0xffff8ab3),
      Color(0xffffd37a),
      Color(0xffffffff),
    ];
    final phase = renderConfig.piecePipColorPhase.clamp(0.0, 1.0).toDouble();
    final scaled = phase * (palette.length - 1);
    final index = scaled.floor().clamp(0, palette.length - 2);
    final t = scaled - index;

    return Color.lerp(palette[index], palette[index + 1], t)!;
  }

  Color _draggingAccentColor(
    BoardModel board, {
    required BoardPiece piece,
    required PieceDragging visualState,
    required RenderConfig renderConfig,
  }) {
    final occupied =
        visualState.hoveredIndex != piece.cellIndex &&
        board.pieceAtCell(
              visualState.hoveredIndex,
              excludingPieceId: piece.id,
            ) !=
            null;

    return occupied ? _illegalMovePipColor : _defaultAccentColor(renderConfig);
  }

  _PipPaint _pipsForPiece({
    required int pieceId,
    required int? value,
    required double time,
  }) {
    final animation = _pipAnimations[pieceId];

    if (animation == null) {
      _pipAnimations[pieceId] = _PipAnimation(
        previousValue: value,
        value: value,
        startedAt: time,
      );

      return _PipPaint(value: value, previousValue: null, transition: 1);
    }

    if (animation.value != value) {
      _pipAnimations[pieceId] = _PipAnimation(
        previousValue: animation.value,
        value: value,
        startedAt: time,
      );

      return _PipPaint(
        value: value,
        previousValue: animation.value,
        transition: 0,
      );
    }

    final raw = ((time - animation.startedAt) / _pipChangeDuration).clamp(
      0.0,
      1.0,
    );

    return _PipPaint(
      value: animation.value,
      previousValue: animation.previousValue,
      transition: Curves.easeOutCubic.transform(raw.toDouble()),
    );
  }

  TileFrame _movingFrameForPiece(
    BoardLayout layout,
    VertexBoardControlMesh mesh,
    PieceMoving moving,
    double time,
  ) {
    final progress = ((time - moving.startedAt) / moving.duration).clamp(
      0.0,
      1.0,
    );
    final eased = Curves.easeOutCubic.transform(progress);
    final fromFrame = _shiftFrameToCenter(
      mesh.frames[moving.fromIndex],
      moving.fromCenter +
          _animatedOffsetForCell(layout, mesh, moving.fromIndex),
    );

    return _lerpFrame(fromFrame, mesh.frames[moving.toIndex], eased);
  }

  ui.Offset _movingTravelVector(
    BoardLayout layout,
    VertexBoardControlMesh mesh,
    PieceMoving moving,
  ) {
    final toCenter = mesh.frames[moving.toIndex].center;

    if (moving.fromIndex == moving.toIndex) {
      final releaseCenter =
          moving.fromCenter +
          _animatedOffsetForCell(layout, mesh, moving.fromIndex);

      return toCenter - releaseCenter;
    }

    return toCenter - mesh.frames[moving.fromIndex].center;
  }

  double _movingDistortion(
    BoardLayout layout,
    VertexBoardControlMesh mesh,
    PieceMoving moving,
    double time,
  ) {
    final progress = ((time - moving.startedAt) / moving.duration).clamp(
      0.0,
      1.0,
    );
    final distance =
        _movingTravelVector(layout, mesh, moving).distance / layout.cellSize;

    return math.sin(progress * math.pi) *
        math.min(0.75, 0.28 + distance * 0.12);
  }

  ui.Offset _gridPositionForCenter(BoardLayout layout, ui.Offset center) {
    final gridX = ((center.dx - layout.boardRect.left) / layout.cellSize - 0.5)
        .clamp(0.0, (layout.boardSize - 1).toDouble());
    final gridY = ((center.dy - layout.boardRect.top) / layout.cellSize - 0.5)
        .clamp(0.0, (layout.boardSize - 1).toDouble());

    return ui.Offset(gridX.toDouble(), gridY.toDouble());
  }

  ui.Offset _pieceLift(BoardLayout layout) {
    return ui.Offset(layout.cellSize * 0.018, -layout.cellSize * 0.075);
  }

  ui.Offset _animatedOffsetForCell(
    BoardLayout layout,
    VertexBoardControlMesh mesh,
    int index,
  ) {
    final row = index ~/ layout.boardSize;
    final column = index % layout.boardSize;

    return mesh.frames[index].center - layout.rectForCell(row, column).center;
  }

  TileFrame _lerpFrame(TileFrame from, TileFrame to, double t) {
    return TileFrame(
      center: ui.Offset.lerp(from.center, to.center, t)!,
      topLeft: ui.Offset.lerp(from.topLeft, to.topLeft, t)!,
      topRight: ui.Offset.lerp(from.topRight, to.topRight, t)!,
      bottomLeft: ui.Offset.lerp(from.bottomLeft, to.bottomLeft, t)!,
      bottomRight: ui.Offset.lerp(from.bottomRight, to.bottomRight, t)!,
    );
  }

  TileFrame _shiftFrameToCenter(TileFrame frame, ui.Offset center) {
    final offset = center - frame.center;

    return TileFrame(
      center: frame.center + offset,
      topLeft: frame.topLeft + offset,
      topRight: frame.topRight + offset,
      bottomLeft: frame.bottomLeft + offset,
      bottomRight: frame.bottomRight + offset,
    );
  }
}

class BlastLayer {
  const BlastLayer();

  static const _explosionRenderer = ExplosionRenderer();
  static const _revealRenderer = RevealRenderer();

  void paintReveals(
    ui.Canvas canvas, {
    required ui.Size canvasSize,
    required VertexBoardControlMesh mesh,
    required List<ActiveBlast> blasts,
    required double cellSize,
    required ui.FragmentProgram? galaxyRevealProgram,
    required RenderConfig renderConfig,
  }) {
    final foundBlasts = blasts
        .where((blast) => blast.kind == GalaxyBlastKind.found)
        .toList();

    _revealRenderer.paint(
      canvas,
      canvasSize: canvasSize,
      mesh: mesh,
      program: galaxyRevealProgram,
      blasts: foundBlasts,
      cellSize: cellSize,
      intensity: renderConfig.galaxyFoundIntensity,
      palette: 0,
    );
  }

  void paintExplosions(
    ui.Canvas canvas, {
    required ui.Size canvasSize,
    required VertexBoardControlMesh mesh,
    required List<ActiveBlast> blasts,
    required double cellSize,
    required ui.FragmentProgram? galaxyExplodeProgram,
    required RenderConfig renderConfig,
  }) {
    final timerBlasts = blasts
        .where((blast) => blast.kind == GalaxyBlastKind.timer)
        .toList();

    _explosionRenderer.paint(
      canvas,
      canvasSize: canvasSize,
      mesh: mesh,
      program: galaxyExplodeProgram,
      blasts: timerBlasts,
      cellSize: cellSize,
      intensity: renderConfig.galaxyExplosionIntensity,
      palette: 0,
    );
  }
}

class _PipAnimation {
  const _PipAnimation({
    required this.previousValue,
    required this.value,
    required this.startedAt,
  });

  final int? previousValue;
  final int? value;
  final double startedAt;
}

class _PipPaint {
  const _PipPaint({
    required this.value,
    required this.previousValue,
    required this.transition,
  });

  final int? value;
  final int? previousValue;
  final double transition;
}

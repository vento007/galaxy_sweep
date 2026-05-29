import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:galaxy_sweep/game/cubit/game_cubit.dart';
import 'package:galaxy_sweep/render/board_layers.dart';
import 'package:galaxy_sweep/game/cubit/game_state.dart';
import 'package:galaxy_sweep/game/board/board_layout.dart';
import 'package:galaxy_sweep/render/board_mesh_builder.dart';
import 'package:galaxy_sweep/render/board_renderer.dart';
import 'package:galaxy_sweep/render/galaxy_explosion.dart';
import 'package:galaxy_sweep/models/piece_visual_state.dart';
import 'package:galaxy_sweep/render/render_config.dart';

class BoardPainter extends CustomPainter {
  BoardPainter({
    required this.state,
    required this.layout,
    required this.elapsedSeconds,
    required this.tileNebulaProgram,
    required this.tileStarsProgram,
    required this.galaxyExplodeProgram,
    required this.galaxyRevealProgram,
    required this.renderConfig,
  }) : super(repaint: elapsedSeconds);

  final GameState state;
  final BoardLayout layout;
  final ValueNotifier<double> elapsedSeconds;
  final ui.FragmentProgram? tileNebulaProgram;
  final ui.FragmentProgram? tileStarsProgram;
  final ui.FragmentProgram? galaxyExplodeProgram;
  final ui.FragmentProgram? galaxyRevealProgram;
  final RenderConfig renderConfig;

  static const _surfaceLayer = BoardSurfaceLayer();
  static const _pieceLayer = PieceLayer();
  static const _blastLayer = BlastLayer();
  static const _meshBuilder = BoardMeshBuilder();
  static _MeshLogSignature? _lastLoggedMesh;

  @override
  void paint(Canvas canvas, Size size) {
    final time = elapsedSeconds.value;
    final blasts = collectActiveBlasts(
      state.board,
      layout,
      time,
      explosionSpeed: renderConfig.galaxyExplosionSpeed,
      foundSpeed: renderConfig.galaxyFoundSpeed,
    );
    final influences = _collectTileInfluences(time);
    final mesh = _meshBuilder.build(
      board: state.board,
      layout: layout,
      time: time,
      palette: renderConfig.tileColorPalette,
      surfaceBoost: renderConfig.tileSurfaceBoost,
      blasts: blasts,
      influences: influences,
    );
    _logMeshOnLayoutChange(size, mesh);

    _surfaceLayer.paint(
      canvas,
      canvasSize: size,
      layout: layout,
      mesh: mesh,
      blasts: blasts,
      renderConfig: renderConfig,
      tileNebulaProgram: tileNebulaProgram,
      tileStarsProgram: tileStarsProgram,
      time: time,
    );
    _blastLayer.paintReveals(
      canvas,
      canvasSize: size,
      mesh: mesh,
      blasts: blasts,
      cellSize: layout.cellSize,
      galaxyRevealProgram: galaxyRevealProgram,
      renderConfig: renderConfig,
    );
    _pieceLayer.paint(
      canvas,
      board: state.board,
      layout: layout,
      mesh: mesh,
      renderConfig: renderConfig,
      time: time,
    );
    _blastLayer.paintExplosions(
      canvas,
      canvasSize: size,
      mesh: mesh,
      blasts: blasts,
      cellSize: layout.cellSize,
      galaxyExplodeProgram: galaxyExplodeProgram,
      renderConfig: renderConfig,
    );
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.layout != layout ||
        oldDelegate.elapsedSeconds != elapsedSeconds ||
        oldDelegate.tileNebulaProgram != tileNebulaProgram ||
        oldDelegate.tileStarsProgram != tileStarsProgram ||
        oldDelegate.galaxyExplodeProgram != galaxyExplodeProgram ||
        oldDelegate.galaxyRevealProgram != galaxyRevealProgram ||
        oldDelegate.renderConfig != renderConfig;
  }

  List<TileInfluence> _collectTileInfluences(double time) {
    final influences = <TileInfluence>[];

    for (final piece in state.board.pieces) {
      final visualState = piece.visualState;

      if (visualState is PieceDragging) {
        final center = visualState.pointerPosition - visualState.grabOffset;
        final sourceCenter = layout.cellCenterForIndex(piece.cellIndex);
        final dragDistance = (center - sourceCenter).distance;
        final rawStrength = (dragDistance / (layout.cellSize * 0.42)).clamp(
          0.0,
          1.0,
        );
        influences.add(
          TileInfluence(
            center: center,
            strength: Curves.easeOutCubic.transform(rawStrength.toDouble()),
          ),
        );
        continue;
      }

      if (visualState is PieceMoving) {
        final elapsed = (time - visualState.startedAt).toDouble();
        final progress = (elapsed / visualState.duration)
            .clamp(0.0, 1.0)
            .toDouble();
        final eased = Curves.easeOutCubic.transform(progress);
        final toCenter = layout.cellCenterForIndex(visualState.toIndex);
        final center = ui.Offset.lerp(visualState.fromCenter, toCenter, eased);
        if (center != null) {
          final settleProgress =
              ((elapsed - visualState.duration) /
                      GameCubit.pieceSettleTailDuration)
                  .clamp(0.0, 1.0)
                  .toDouble();
          final settleFade =
              1.0 - Curves.easeOutCubic.transform(settleProgress);
          influences.add(
            TileInfluence(center: center, strength: 0.9 * settleFade),
          );
        }
      }
    }

    return influences;
  }

  void _logMeshOnLayoutChange(ui.Size size, VertexBoardControlMesh mesh) {
    final signature = _MeshLogSignature.from(size, mesh.boardRect);
    if (_lastLoggedMesh == signature) {
      return;
    }

    _lastLoggedMesh = signature;
    debugPrint(
      'mesh: canvas=${size.width.toStringAsFixed(1)}x${size.height.toStringAsFixed(1)} '
      'board=${mesh.boardRect} dimension=${mesh.dimension} '
      'positions=${mesh.positions.length} colors=${mesh.colors.length} '
      'frames=${mesh.frames.length}',
    );

    for (var index = 0; index < mesh.frames.length && index < 3; index++) {
      final frame = mesh.frames[index];
      debugPrint(
        'mesh frame[$index]: center=${_offset(frame.center)} '
        'tl=${_offset(frame.topLeft)} tr=${_offset(frame.topRight)} '
        'bl=${_offset(frame.bottomLeft)} br=${_offset(frame.bottomRight)}',
      );
    }
  }

  String _offset(ui.Offset offset) {
    return '(${offset.dx.toStringAsFixed(1)}, ${offset.dy.toStringAsFixed(1)})';
  }
}

class _MeshLogSignature {
  const _MeshLogSignature({
    required this.canvasWidth,
    required this.canvasHeight,
    required this.boardLeft,
    required this.boardTop,
    required this.boardWidth,
    required this.boardHeight,
  });

  factory _MeshLogSignature.from(ui.Size size, ui.Rect boardRect) {
    return _MeshLogSignature(
      canvasWidth: _scaled(size.width),
      canvasHeight: _scaled(size.height),
      boardLeft: _scaled(boardRect.left),
      boardTop: _scaled(boardRect.top),
      boardWidth: _scaled(boardRect.width),
      boardHeight: _scaled(boardRect.height),
    );
  }

  final int canvasWidth;
  final int canvasHeight;
  final int boardLeft;
  final int boardTop;
  final int boardWidth;
  final int boardHeight;

  static int _scaled(double value) => (value * 10).round();

  @override
  bool operator ==(Object other) {
    return other is _MeshLogSignature &&
        other.canvasWidth == canvasWidth &&
        other.canvasHeight == canvasHeight &&
        other.boardLeft == boardLeft &&
        other.boardTop == boardTop &&
        other.boardWidth == boardWidth &&
        other.boardHeight == boardHeight;
  }

  @override
  int get hashCode {
    return Object.hash(
      canvasWidth,
      canvasHeight,
      boardLeft,
      boardTop,
      boardWidth,
      boardHeight,
    );
  }
}

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:galaxy_sweep/game/cubit/game_cubit.dart';
import 'package:galaxy_sweep/render/board_layers.dart';
import 'package:galaxy_sweep/game/cubit/game_state.dart';
import 'package:galaxy_sweep/game/board/board_layout.dart';
import 'package:galaxy_sweep/render/board_mesh_builder.dart';
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
      surfaceBoost: renderConfig.tileSurfaceBoost,
      blasts: blasts,
      influences: influences,
    );

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
        final rawStrength =
            (dragDistance / (layout.cellSize * 0.42)).clamp(0.0, 1.0);
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
        final center = ui.Offset.lerp(
          visualState.fromCenter,
          toCenter,
          eased,
        );
        if (center != null) {
          final settleProgress =
              ((elapsed - visualState.duration) /
                      GameCubit.pieceSettleTailDuration)
                  .clamp(0.0, 1.0)
                  .toDouble();
          final settleFade = 1.0 -
              Curves.easeOutCubic.transform(settleProgress);
          influences.add(
            TileInfluence(
              center: center,
              strength: 0.9 * settleFade,
            ),
          );
        }
      }
    }

    return influences;
  }
}

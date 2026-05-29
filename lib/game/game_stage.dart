import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:galaxy_sweep/controllers/render_config_controller.dart';
import 'package:galaxy_sweep/game/board/board_layout.dart';
import 'package:galaxy_sweep/game/cubit/game_cubit.dart';
import 'package:galaxy_sweep/game/cubit/game_state.dart';
import 'package:galaxy_sweep/game/overlays/game_overlay.dart';
import 'package:galaxy_sweep/game/overlays/render_controls_overlay.dart';
import 'package:galaxy_sweep/render/board_painter.dart';
import 'package:galaxy_sweep/render/render_config.dart';

class GameStage extends StatelessWidget {
  const GameStage({
    super.key,
    required this.gameCubit,
    required this.renderConfigController,
    required this.elapsedSeconds,
    required this.tileNebulaProgram,
    required this.tileStarsProgram,
    required this.galaxyExplodeProgram,
    required this.galaxyRevealProgram,
    required this.showRenderControls,
    required this.onToggleRenderControls,
  });

  final GameCubit gameCubit;
  final RenderConfigController renderConfigController;
  final ValueNotifier<double> elapsedSeconds;
  final ui.FragmentProgram? tileNebulaProgram;
  final ui.FragmentProgram? tileStarsProgram;
  final ui.FragmentProgram? galaxyExplodeProgram;
  final ui.FragmentProgram? galaxyRevealProgram;
  final bool showRenderControls;
  final VoidCallback onToggleRenderControls;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = constraints.biggest;

        return BlocBuilder<GameCubit, GameState>(
          bloc: gameCubit,
          builder: (context, state) {
            return ValueListenableBuilder<RenderConfig>(
              valueListenable: renderConfigController,
              builder: (context, renderConfig, _) {
                final layout = createBoardLayout(
                  canvasSize,
                  boardSize: state.board.boardSize,
                  gap: renderConfig.boardGap,
                );
                final board = CustomPaint(
                  painter: BoardPainter(
                    state: state,
                    layout: layout,
                    elapsedSeconds: elapsedSeconds,
                    tileNebulaProgram: tileNebulaProgram,
                    tileStarsProgram: tileStarsProgram,
                    galaxyExplodeProgram: galaxyExplodeProgram,
                    galaxyRevealProgram: galaxyRevealProgram,
                    renderConfig: renderConfig,
                  ),
                );

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    if (state.isPlaying)
                      GestureDetector(
                        onPanStart: (details) => gameCubit.dragStarted(
                          details.localPosition,
                          layout,
                        ),
                        onPanUpdate: (details) => gameCubit.dragUpdated(
                          details.localPosition,
                          layout,
                        ),
                        onPanEnd: (_) =>
                            gameCubit.dragEnded(elapsedSeconds.value, layout),
                        child: board,
                      )
                    else
                      board,
                    if (state.isIdle)
                      StartGameOverlay(
                        elapsedSeconds: elapsedSeconds,
                        onStart: () =>
                            gameCubit.startGame(elapsedSeconds.value),
                      ),
                    if (state.isGameOver)
                      GameOverOverlay(
                        elapsedSeconds: elapsedSeconds,
                        score: state.score,
                        onRestart: () =>
                            gameCubit.startGame(elapsedSeconds.value),
                      ),
                    RenderControlsOverlay(
                      controller: renderConfigController,
                      isOpen: showRenderControls,
                      onToggle: onToggleRenderControls,
                      signalTriggerMode: state.marketSignalTriggerMode,
                      onSignalTriggerModeChanged:
                          gameCubit.setMarketSignalTriggerMode,
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

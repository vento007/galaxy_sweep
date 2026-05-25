import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:galaxy_sweep/models/galaxy_blast.dart';
import 'package:galaxy_sweep/render/board_renderer.dart';
import 'package:galaxy_sweep/render/galaxy_explosion.dart';

class TileShaderRenderer {
  const TileShaderRenderer();

  void paintNebula(
    ui.Canvas canvas, {
    required ui.Size canvasSize,
    required VertexBoardControlMesh mesh,
    required ui.FragmentProgram? program,
    required List<ActiveBlast> blasts,
    required double time,
    required double gapFraction,
    required double glowIntensity,
    required double nebulaIntensity,
    required double sheenIntensity,
    required double grainIntensity,
  }) {
    if (program == null ||
        (glowIntensity <= 0 &&
            nebulaIntensity <= 0 &&
            sheenIntensity <= 0 &&
            grainIntensity <= 0)) {
      return;
    }

    final shader = program.fragmentShader();
    var uniform = 0;
    final timerBlasts = blasts
        .where((blast) => blast.kind == GalaxyBlastKind.timer)
        .take(3)
        .toList(growable: false);

    shader
      ..setFloat(uniform++, canvasSize.width)
      ..setFloat(uniform++, canvasSize.height)
      ..setFloat(uniform++, mesh.boardRect.left)
      ..setFloat(uniform++, mesh.boardRect.top)
      ..setFloat(uniform++, mesh.boardRect.width)
      ..setFloat(uniform++, mesh.boardRect.height)
      ..setFloat(uniform++, time)
      ..setFloat(uniform++, 0)
      ..setFloat(uniform++, mesh.dimension.toDouble())
      ..setFloat(uniform++, glowIntensity)
      ..setFloat(uniform++, nebulaIntensity)
      ..setFloat(uniform++, sheenIntensity)
      ..setFloat(uniform++, gapFraction.clamp(0.0, 0.48))
      ..setFloat(uniform++, grainIntensity)
      ..setFloat(uniform++, timerBlasts.length.toDouble());

    for (var index = 0; index < 3; index++) {
      if (index < timerBlasts.length) {
        final blast = timerBlasts[index];
        final boardUv = ui.Offset(
          ((blast.center.dx - mesh.boardRect.left) / mesh.boardRect.width)
              .clamp(0.0, 1.0),
          ((blast.center.dy - mesh.boardRect.top) / mesh.boardRect.height)
              .clamp(0.0, 1.0),
        );
        final strength =
            math.sin(blast.progress * math.pi).clamp(0.0, 1.0).toDouble();

        shader
          ..setFloat(uniform++, boardUv.dx)
          ..setFloat(uniform++, boardUv.dy)
          ..setFloat(uniform++, blast.progress)
          ..setFloat(uniform++, strength);
      } else {
        shader
          ..setFloat(uniform++, 0.0)
          ..setFloat(uniform++, 0.0)
          ..setFloat(uniform++, 0.0)
          ..setFloat(uniform++, 0.0);
      }
    }

    canvas.drawRect(
      mesh.boardRect,
      ui.Paint()
        ..isAntiAlias = true
        ..shader = shader
        ..blendMode = ui.BlendMode.plus,
    );
  }

  void paintStars(
    ui.Canvas canvas, {
    required ui.Size canvasSize,
    required VertexBoardControlMesh mesh,
    required ui.FragmentProgram? program,
    required double time,
    required double gapFraction,
    required double intensity,
  }) {
    if (program == null || intensity <= 0 || mesh.boardRect.isEmpty) {
      return;
    }

    final shader = program.fragmentShader();
    var uniform = 0;

    shader
      ..setFloat(uniform++, canvasSize.width)
      ..setFloat(uniform++, canvasSize.height)
      ..setFloat(uniform++, mesh.boardRect.left)
      ..setFloat(uniform++, mesh.boardRect.top)
      ..setFloat(uniform++, mesh.boardRect.width)
      ..setFloat(uniform++, mesh.boardRect.height)
      ..setFloat(uniform++, time)
      ..setFloat(uniform++, mesh.dimension.toDouble())
      ..setFloat(uniform++, intensity)
      ..setFloat(uniform++, gapFraction.clamp(0.0, 0.48));

    canvas.drawRect(
      mesh.boardRect,
      ui.Paint()
        ..isAntiAlias = true
        ..shader = shader
        ..blendMode = ui.BlendMode.plus,
    );
  }
}

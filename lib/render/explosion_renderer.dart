import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:galaxy_sweep/render/board_renderer.dart';
import 'package:galaxy_sweep/render/galaxy_explosion.dart';

class ExplosionRenderer {
  const ExplosionRenderer();

  static const _sparkCount = 26;
  static const _coolSpark = ui.Color(0xff8fd9ff);
  static const _warmSpark = ui.Color(0xffffc97a);
  static const _whiteSpark = ui.Color(0xfffff6e8);

  void paint(
    ui.Canvas canvas, {
    required ui.Size canvasSize,
    required VertexBoardControlMesh mesh,
    required ui.FragmentProgram? program,
    required List<ActiveBlast> blasts,
    required double cellSize,
    required double intensity,
    required double palette,
  }) {
    if (blasts.isEmpty || intensity <= 0 || cellSize <= 0) {
      return;
    }

    if (program != null) {
      for (final blast in blasts) {
        _paintShader(
          canvas,
          canvasSize: canvasSize,
          mesh: mesh,
          program: program,
          blast: blast,
          cellSize: cellSize,
          intensity: intensity,
          palette: palette,
        );
      }
    }

    for (final blast in blasts) {
      _paintDebris(canvas, blast, cellSize, intensity);
    }
  }

  void _paintShader(
    ui.Canvas canvas, {
    required ui.Size canvasSize,
    required VertexBoardControlMesh mesh,
    required ui.FragmentProgram program,
    required ActiveBlast blast,
    required double cellSize,
    required double intensity,
    required double palette,
  }) {
    final shader = program.fragmentShader();
    var uniform = 0;

    shader
      ..setFloat(uniform++, canvasSize.width)
      ..setFloat(uniform++, canvasSize.height)
      ..setFloat(uniform++, mesh.boardRect.left)
      ..setFloat(uniform++, mesh.boardRect.top)
      ..setFloat(uniform++, mesh.boardRect.width)
      ..setFloat(uniform++, mesh.boardRect.height)
      ..setFloat(uniform++, blast.center.dx)
      ..setFloat(uniform++, blast.center.dy)
      ..setFloat(uniform++, blast.age)
      ..setFloat(uniform++, kGalaxyExplosionDuration)
      ..setFloat(uniform++, cellSize)
      ..setFloat(uniform++, palette)
      ..setFloat(uniform++, intensity);

    canvas.drawRect(
      mesh.boardRect,
      ui.Paint()
        ..isAntiAlias = true
        ..shader = shader
        ..blendMode = ui.BlendMode.plus,
    );
  }

  void _paintDebris(
    ui.Canvas canvas,
    ActiveBlast blast,
    double cellSize,
    double intensity,
  ) {
    final age = blast.age;
    final sparkPaint = ui.Paint()
      ..isAntiAlias = true
      ..blendMode = ui.BlendMode.plus;

    for (var i = 0; i < _sparkCount; i++) {
      final seed = blast.galaxyId * 131 + i * 977;
      final angle = _hash(seed) * math.pi * 2;
      final speed = (1.10 + _hash(seed + 1) * 1.80) * cellSize;
      final drag = 2.10 + _hash(seed + 2) * 1.60;
      final life = 0.55 + _hash(seed + 3) * 0.95;

      if (age > life) {
        continue;
      }

      final dir = ui.Offset(math.cos(angle), math.sin(angle));
      final perp = ui.Offset(-dir.dy, dir.dx);
      final travelled = speed * (1 - math.exp(-age * drag)) / drag;
      final curl = (_hash(seed + 4) - 0.5) * 0.85 * cellSize * age;
      final gravity = 0.55 * cellSize * age * age;
      final head =
          blast.center + dir * travelled + perp * curl + ui.Offset(0, gravity);

      final fade = 1 - age / life;
      final eased = fade * fade;
      final radius =
          (0.05 + _hash(seed + 6) * 0.07) * cellSize * (0.35 + fade * 0.65);
      final sparkColor = ui.Color.lerp(
        _coolSpark,
        _warmSpark,
        _hash(seed + 7),
      )!;

      sparkPaint
        ..color = sparkColor.withValues(
          alpha: (eased * 0.38 * intensity).clamp(0.0, 1.0),
        )
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, radius * 1.4);
      canvas.drawCircle(head, radius * 1.6, sparkPaint);

      sparkPaint
        ..color = _whiteSpark.withValues(
          alpha: (eased * 0.62 * intensity).clamp(0.0, 1.0),
        )
        ..maskFilter = null;
      canvas.drawCircle(head, radius * 0.60, sparkPaint);
    }
  }

  double _hash(int n) {
    var x = (n * 1664525 + 1013904223) & 0x7fffffff;
    x ^= x >> 13;
    x = (x * 1274126177) & 0x7fffffff;

    return x / 0x7fffffff;
  }
}

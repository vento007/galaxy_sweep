import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:galaxy_sweep/render/board_renderer.dart';
import 'package:galaxy_sweep/render/galaxy_explosion.dart';

class RevealRenderer {
  const RevealRenderer();

  static const _moteCount = 18;
  static const _coolMote = ui.Color(0xff9fe4ff);
  static const _warmMote = ui.Color(0xffffe2ad);
  static const _whiteMote = ui.Color(0xfffff4e4);

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

    for (final blast in blasts) {
      _paintVignette(canvas, blast, cellSize, intensity);
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
      _paintMotes(canvas, blast, cellSize, intensity);
    }
  }

  void _paintVignette(
    ui.Canvas canvas,
    ActiveBlast blast,
    double cellSize,
    double intensity,
  ) {
    final t = (blast.age / kGalaxyFoundDuration).clamp(0.0, 1.0);
    final env = _smoothstep(0.0, 0.22, t) * (1.0 - _smoothstep(0.74, 1.0, t));
    final strength = (env * intensity).clamp(0.0, 1.0);

    if (strength <= 0.002) {
      return;
    }

    final radius = cellSize * 4.3;
    const clear = ui.Color(0x00060912);
    final dark = const ui.Color(0xff060912).withValues(alpha: 0.42 * strength);
    final shader = ui.Gradient.radial(
      blast.center,
      radius,
      [clear, clear, dark, clear],
      [0.0, 0.17, 0.46, 1.0],
    );

    canvas.drawCircle(blast.center, radius, ui.Paint()..shader = shader);
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
      ..setFloat(uniform++, kGalaxyFoundDuration)
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

  void _paintMotes(
    ui.Canvas canvas,
    ActiveBlast blast,
    double cellSize,
    double intensity,
  ) {
    final t = (blast.age / kGalaxyFoundDuration).clamp(0.0, 1.0);
    final motePaint = ui.Paint()
      ..isAntiAlias = true
      ..blendMode = ui.BlendMode.plus;

    for (var i = 0; i < _moteCount; i++) {
      final seed = blast.galaxyId * 197 + i * 613;

      final delay = _hash(seed) * 0.30;
      if (t <= delay) {
        continue;
      }
      final local = ((t - delay) / (1.0 - delay)).clamp(0.0, 1.0);

      final startRadius = (1.7 + _hash(seed + 1) * 2.0) * cellSize;
      final startAngle = _hash(seed + 2) * math.pi * 2;
      final orbitDir = _hash(seed + 3) < 0.5 ? -1.0 : 1.0;
      final orbitTurn = (0.5 + _hash(seed + 4) * 0.8) * orbitDir;

      final pull = _smoothstep(0.0, 1.0, local);
      final radius = startRadius * (1.0 - pull * 0.94);
      final angle = startAngle + orbitTurn * pull;
      final pos =
          blast.center + ui.Offset(math.cos(angle), math.sin(angle)) * radius;

      final arrival = _smoothstep(0.45, 0.96, local);
      final fade =
          _smoothstep(0.0, 0.18, local) * (1.0 - _smoothstep(0.90, 1.0, local));
      final brightness = fade * (0.55 + arrival * 0.75);
      final glow = _hash(seed + 5);
      final coreRadius = (0.045 + _hash(seed + 6) * 0.055) * cellSize;
      final moteColor = ui.Color.lerp(_coolMote, _warmMote, _hash(seed + 7))!;

      motePaint
        ..color = moteColor.withValues(
          alpha: (brightness * 0.30 * intensity).clamp(0.0, 1.0),
        )
        ..maskFilter = ui.MaskFilter.blur(
          ui.BlurStyle.normal,
          coreRadius * 2.0,
        );
      canvas.drawCircle(pos, coreRadius * 2.1, motePaint);

      motePaint
        ..color = _whiteMote.withValues(
          alpha: (brightness * 0.46 * intensity).clamp(0.0, 1.0),
        )
        ..maskFilter = null;
      canvas.drawCircle(pos, coreRadius * (0.55 + glow * 0.25), motePaint);
    }
  }

  double _smoothstep(double a, double b, double x) {
    final t = ((x - a) / (b - a)).clamp(0.0, 1.0);

    return t * t * (3.0 - 2.0 * t);
  }

  double _hash(int n) {
    var x = (n * 1664525 + 1013904223) & 0x7fffffff;
    x ^= x >> 13;
    x = (x * 1274126177) & 0x7fffffff;

    return x / 0x7fffffff;
  }
}

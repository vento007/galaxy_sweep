import 'dart:math' as math;
import 'dart:ui';

import 'package:galaxy_sweep/game/board/board_layout.dart';
import 'package:galaxy_sweep/models/board_model.dart';
import 'package:galaxy_sweep/models/galaxy_blast.dart';

const double kGalaxyExplosionDuration = 1.7;

const double kGalaxyFoundDuration = kGalaxyExplosionDuration;

double blastDuration(GalaxyBlastKind kind) {
  return switch (kind) {
    GalaxyBlastKind.found => kGalaxyFoundDuration,
    GalaxyBlastKind.timer => kGalaxyExplosionDuration,
  };
}

const double kGalaxyExplosionWaveSpeed = 6.8;

const double kGalaxyExplosionMinSpeed = 0.05;

double normalizeExplosionSpeed(double speed) {
  return speed.clamp(kGalaxyExplosionMinSpeed, 4.0);
}

double blastSpeed(
  GalaxyBlastKind kind, {
  required double explosionSpeed,
  required double foundSpeed,
}) {
  return switch (kind) {
    GalaxyBlastKind.found => normalizeExplosionSpeed(foundSpeed),
    GalaxyBlastKind.timer => normalizeExplosionSpeed(explosionSpeed),
  };
}

class ActiveBlast {
  const ActiveBlast({
    required this.galaxyId,
    required this.kind,
    required this.center,
    required this.age,
  });

  final int galaxyId;
  final GalaxyBlastKind kind;
  final Offset center;
  final double age;

  double get progress => (age / blastDuration(kind)).clamp(0.0, 1.0);
}

List<ActiveBlast> collectActiveBlasts(
  BoardModel board,
  BoardLayout layout,
  double time, {
  double explosionSpeed = 1.0,
  double foundSpeed = 1.0,
}) {
  final blasts = <ActiveBlast>[];

  for (final blast in board.blasts) {
    final scale = blastSpeed(
      blast.kind,
      explosionSpeed: explosionSpeed,
      foundSpeed: foundSpeed,
    );
    final age = (time - blast.startedAt) * scale;

    if (age < 0 || age >= blastDuration(blast.kind)) {
      continue;
    }

    blasts.add(
      ActiveBlast(
        galaxyId: blast.galaxyId,
        kind: blast.kind,
        center: layout.cellCenterForIndex(blast.cellIndex),
        age: age,
      ),
    );
  }

  return blasts;
}

bool blastFinished(
  GalaxyBlast blast,
  double now, {
  required double explosionSpeed,
  required double foundSpeed,
}) {
  final scale = blastSpeed(
    blast.kind,
    explosionSpeed: explosionSpeed,
    foundSpeed: foundSpeed,
  );

  return (now - blast.startedAt) * scale >= blastDuration(blast.kind);
}

Offset explosionRecoil(
  Offset pointPx,
  List<ActiveBlast> blasts,
  double cellSize,
) {
  if (blasts.isEmpty || cellSize <= 0) {
    return Offset.zero;
  }

  var dx = 0.0;
  var dy = 0.0;

  for (final blast in blasts) {
    if (blast.kind != GalaxyBlastKind.timer) {
      continue;
    }

    final vx = pointPx.dx - blast.center.dx;
    final vy = pointPx.dy - blast.center.dy;
    final distPx = math.sqrt(vx * vx + vy * vy);

    if (distPx < 0.0001) {
      continue;
    }

    final dist = distPx / cellSize;
    final waveR = blast.age * kGalaxyExplosionWaveSpeed;
    final width = 0.60 + blast.age * 1.40;
    final offset = (dist - waveR) / width;
    final band = math.exp(-offset * offset);
    final decay = math.exp(-blast.age * 3.2);
    final push = band * decay * cellSize * 0.42;

    dx += (vx / distPx) * push;
    dy += (vy / distPx) * push;
  }

  return Offset(dx, dy);
}

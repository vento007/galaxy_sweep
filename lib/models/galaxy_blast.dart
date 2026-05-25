enum GalaxyBlastKind { found, timer }

class GalaxyBlast {
  const GalaxyBlast({
    required this.galaxyId,
    required this.cellIndex,
    required this.kind,
    required this.startedAt,
  });

  final int galaxyId;
  final int cellIndex;
  final GalaxyBlastKind kind;
  final double startedAt;
}

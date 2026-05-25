class RenderConfig {
  const RenderConfig({
    this.boardGap = 4,
    this.pieceScale = 0.75,
    this.piecePipColorPhase = 0.1,
    this.pieceTileLag = 0.2,
    this.tileSurfaceBoost = 0.35,
    this.tileVignette = 1.10,
    this.tileGlowIntensity = 0.1,
    this.tileNebulaIntensity = 1.9,
    this.tileSheenIntensity = 0.5,
    this.tileStarsIntensity = 0.8,
    this.tileGrainIntensity = 0.0,
    this.galaxyExplosionIntensity = 1.5,
    this.galaxyExplosionSpeed = 0.5,
    this.galaxyFoundIntensity = 1.5,
    this.galaxyFoundSpeed = 0.5,
  });

  final double boardGap;
  final double pieceScale;
  final double piecePipColorPhase;
  final double pieceTileLag;
  final double tileSurfaceBoost;
  final double tileVignette;
  final double tileGlowIntensity;
  final double tileNebulaIntensity;
  final double tileSheenIntensity;
  final double tileStarsIntensity;
  final double tileGrainIntensity;
  final double galaxyExplosionIntensity;
  final double galaxyExplosionSpeed;
  final double galaxyFoundIntensity;
  final double galaxyFoundSpeed;

  RenderConfig copyWith({
    double? boardGap,
    double? pieceScale,
    double? piecePipColorPhase,
    double? pieceTileLag,
    double? tileSurfaceBoost,
    double? tileVignette,
    double? tileGlowIntensity,
    double? tileNebulaIntensity,
    double? tileSheenIntensity,
    double? tileStarsIntensity,
    double? tileGrainIntensity,
    double? galaxyExplosionIntensity,
    double? galaxyExplosionSpeed,
    double? galaxyFoundIntensity,
    double? galaxyFoundSpeed,
  }) {
    return RenderConfig(
      boardGap: boardGap ?? this.boardGap,
      pieceScale: pieceScale ?? this.pieceScale,
      piecePipColorPhase: piecePipColorPhase ?? this.piecePipColorPhase,
      pieceTileLag: pieceTileLag ?? this.pieceTileLag,
      tileSurfaceBoost: tileSurfaceBoost ?? this.tileSurfaceBoost,
      tileVignette: tileVignette ?? this.tileVignette,
      tileGlowIntensity: tileGlowIntensity ?? this.tileGlowIntensity,
      tileNebulaIntensity: tileNebulaIntensity ?? this.tileNebulaIntensity,
      tileSheenIntensity: tileSheenIntensity ?? this.tileSheenIntensity,
      tileStarsIntensity: tileStarsIntensity ?? this.tileStarsIntensity,
      tileGrainIntensity: tileGrainIntensity ?? this.tileGrainIntensity,
      galaxyExplosionIntensity:
          galaxyExplosionIntensity ?? this.galaxyExplosionIntensity,
      galaxyExplosionSpeed: galaxyExplosionSpeed ?? this.galaxyExplosionSpeed,
      galaxyFoundIntensity: galaxyFoundIntensity ?? this.galaxyFoundIntensity,
      galaxyFoundSpeed: galaxyFoundSpeed ?? this.galaxyFoundSpeed,
    );
  }
}

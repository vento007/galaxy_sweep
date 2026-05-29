import 'dart:ui';

enum TileColorPalette {
  galaxy('Galaxy', [
    Color(0xff6b214d),
    Color(0xff8b4737),
    Color(0xff896b37),
    Color(0xff477a54),
    Color(0xff047a71),
    Color(0xff195f7a),
    Color(0xff3c4a74),
    Color(0xff56325f),
  ], 0),
  aurora('Aurora', [
    Color(0xff103b4a),
    Color(0xff006d77),
    Color(0xff16a085),
    Color(0xff72efdd),
    Color(0xff80ffdb),
    Color(0xff8ec5fc),
    Color(0xff6a8dff),
    Color(0xff3d348b),
  ], 1),
  ember('Ember', [
    Color(0xff3b0d11),
    Color(0xff7f1d1d),
    Color(0xffb45309),
    Color(0xfff59e0b),
    Color(0xffffdd55),
    Color(0xffff8a3d),
    Color(0xff9a3412),
    Color(0xff4a1d12),
  ], 2),
  obsidian('Obsidian', [
    Color(0xff1a1a2e),
    Color(0xff16213e),
    Color(0xff0f3460),
    Color(0xff1a4a6b),
    Color(0xff2d6a8a),
    Color(0xff3d8fa8),
    Color(0xff4fb3c8),
    Color(0xff6fd8e8),
  ], 1),
  dusk('Dusk', [
    Color(0xff2d1b33),
    Color(0xff4a2040),
    Color(0xff7b3f6e),
    Color(0xffb05480),
    Color(0xffd4736b),
    Color(0xffe8986a),
    Color(0xfff5c06e),
    Color(0xfffde8a0),
  ], 2),
  void_('Void', [
    Color(0xff0a0a0f),
    Color(0xff0d1117),
    Color(0xff1a1f3a),
    Color(0xff2a1f4a),
    Color(0xff3d1f6b),
    Color(0xff6b3fa8),
    Color(0xffa060e0),
    Color(0xffc890ff),
  ], 0),
  moss('Moss', [
    Color(0xff1a2a0f),
    Color(0xff2a3d12),
    Color(0xff3d5a1a),
    Color(0xff5a7a20),
    Color(0xff7a8c2a),
    Color(0xff9a8040),
    Color(0xffb87040),
    Color(0xffd4904a),
  ], 2),
  abyssal('Abyssal', [
    Color(0xff020c10),
    Color(0xff041e28),
    Color(0xff053545),
    Color(0xff075060),
    Color(0xff0a7070),
    Color(0xff0fa88a),
    Color(0xff30d4b0),
    Color(0xff90f0e0),
  ], 1),
  forge('Forge', [
    Color(0xff0f0a04),
    Color(0xff2a1205),
    Color(0xff4a1e08),
    Color(0xff7a2e0a),
    Color(0xffb04a10),
    Color(0xffd47020),
    Color(0xfff0a030),
    Color(0xffffd060),
  ], 2),
  prism('Prism', [
    Color(0xff3a1a4a),
    Color(0xff1a2a7a),
    Color(0xff1a5a7a),
    Color(0xff1a6a4a),
    Color(0xff4a6a1a),
    Color(0xff7a5a10),
    Color(0xff7a2a10),
    Color(0xff5a1a3a),
  ], 0),
  glacial('Glacial', [
    Color(0xffe8f4f8),
    Color(0xffb8d8e8),
    Color(0xff80b8d4),
    Color(0xff4a90b8),
    Color(0xff206890),
    Color(0xff0e4868),
    Color(0xff082840),
    Color(0xff040f1a),
  ], 1),
  spore('Spore', [
    Color(0xff0d1a0a),
    Color(0xff1a3010),
    Color(0xff2a5018),
    Color(0xff4a7820),
    Color(0xff7aaa30),
    Color(0xffa0c840),
    Color(0xff8060c0),
    Color(0xff5030a0),
  ], 0);

  const TileColorPalette(this.label, this.colors, this.shaderIndex);

  final String label;
  final List<Color> colors;
  final double shaderIndex;
}

class RenderConfig {
  const RenderConfig({
    this.boardGap = 4,
    this.pieceScale = 0.75,
    this.piecePipColorPhase = 0.1,
    this.pieceTileLag = 0.2,
    this.tileColorPalette = TileColorPalette.galaxy,
    this.useSquircleTiles = true,
    this.tileEnergyAmount = 0.90,
    this.tileEnergySpeed = 1.0,
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
  final TileColorPalette tileColorPalette;
  final bool useSquircleTiles;
  final double tileEnergyAmount;
  final double tileEnergySpeed;
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
    TileColorPalette? tileColorPalette,
    bool? useSquircleTiles,
    double? tileEnergyAmount,
    double? tileEnergySpeed,
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
      tileColorPalette: tileColorPalette ?? this.tileColorPalette,
      useSquircleTiles: useSquircleTiles ?? this.useSquircleTiles,
      tileEnergyAmount: tileEnergyAmount ?? this.tileEnergyAmount,
      tileEnergySpeed: tileEnergySpeed ?? this.tileEnergySpeed,
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

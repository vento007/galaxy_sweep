import 'package:flutter/material.dart';
import 'package:galaxy_sweep/controllers/render_config_controller.dart';
import 'package:galaxy_sweep/render/render_config.dart';

class RenderControlsOverlay extends StatelessWidget {
  const RenderControlsOverlay({
    super.key,
    required this.controller,
    required this.isOpen,
    required this.onToggle,
    this.onTestMarketTick,
  });

  final RenderConfigController controller;
  final bool isOpen;
  final VoidCallback onToggle;
  final VoidCallback? onTestMarketTick;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 12,
      right: 12,
      child: SafeArea(
        child: Material(
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Tooltip(
                message: isOpen
                    ? 'Hide Render Controls'
                    : 'Show Render Controls',
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: isOpen ? 0.62 : 0.46),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(
                        alpha: isOpen ? 0.18 : 0.10,
                      ),
                    ),
                  ),
                  child: IconButton(
                    onPressed: onToggle,
                    icon: Icon(
                      Icons.settings_rounded,
                      size: 20,
                      color: Colors.white.withValues(alpha: 0.88),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: !isOpen
                    ? const SizedBox.shrink()
                    : ValueListenableBuilder<RenderConfig>(
                        key: const ValueKey('render-controls-panel'),
                        valueListenable: controller,
                        builder: (context, config, _) {
                          return DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.46),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.10),
                              ),
                            ),
                            child: SizedBox(
                              width: 270,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _PaletteSelector(
                                      value: config.tileColorPalette,
                                      onChanged: (palette) => controller.update(
                                        config.copyWith(
                                          tileColorPalette: palette,
                                        ),
                                      ),
                                    ),
                                    _RenderSwitch(
                                      label: 'Squircle',
                                      value: config.useSquircleTiles,
                                      onChanged: (value) => controller.update(
                                        config.copyWith(
                                          useSquircleTiles: value,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _RenderSlider(
                                      label: 'Energy',
                                      value: config.tileEnergyAmount,
                                      max: 1,
                                      onChanged: (value) => controller.update(
                                        config.copyWith(
                                          tileEnergyAmount: value,
                                        ),
                                      ),
                                    ),
                                    _RenderSlider(
                                      label: 'EnergySpd',
                                      value: config.tileEnergySpeed,
                                      max: 2,
                                      onChanged: (value) => controller.update(
                                        config.copyWith(tileEnergySpeed: value),
                                      ),
                                    ),
                                    _RenderSlider(
                                      label: 'Accent',
                                      value: config.piecePipColorPhase,
                                      max: 1,
                                      onChanged: (value) => controller.update(
                                        config.copyWith(
                                          piecePipColorPhase: value,
                                        ),
                                      ),
                                    ),
                                    _RenderSlider(
                                      label: 'Surface',
                                      value: config.tileSurfaceBoost,
                                      max: 1,
                                      onChanged: (value) => controller.update(
                                        config.copyWith(
                                          tileSurfaceBoost: value,
                                        ),
                                      ),
                                    ),
                                    _RenderSlider(
                                      label: 'Vignette',
                                      value: config.tileVignette,
                                      max: 1.2,
                                      onChanged: (value) => controller.update(
                                        config.copyWith(tileVignette: value),
                                      ),
                                    ),
                                    _RenderSlider(
                                      label: 'Glow',
                                      value: config.tileGlowIntensity,
                                      max: 1.5,
                                      onChanged: (value) => controller.update(
                                        config.copyWith(
                                          tileGlowIntensity: value,
                                        ),
                                      ),
                                    ),
                                    _RenderSlider(
                                      label: 'Nebula',
                                      value: config.tileNebulaIntensity,
                                      max: 2,
                                      onChanged: (value) => controller.update(
                                        config.copyWith(
                                          tileNebulaIntensity: value,
                                        ),
                                      ),
                                    ),
                                    _RenderSlider(
                                      label: 'Stars',
                                      value: config.tileStarsIntensity,
                                      max: 1,
                                      onChanged: (value) => controller.update(
                                        config.copyWith(
                                          tileStarsIntensity: value,
                                        ),
                                      ),
                                    ),
                                    _RenderSlider(
                                      label: 'Grain',
                                      value: config.tileGrainIntensity,
                                      max: 2,
                                      onChanged: (value) => controller.update(
                                        config.copyWith(
                                          tileGrainIntensity: value,
                                        ),
                                      ),
                                    ),
                                    _RenderSlider(
                                      label: 'Found',
                                      value: config.galaxyFoundIntensity,
                                      max: 2,
                                      onChanged: (value) => controller.update(
                                        config.copyWith(
                                          galaxyFoundIntensity: value,
                                        ),
                                      ),
                                    ),
                                    _RenderSlider(
                                      label: 'FoundSpd',
                                      value: config.galaxyFoundSpeed,
                                      min: 0.05,
                                      max: 1.5,
                                      onChanged: (value) => controller.update(
                                        config.copyWith(
                                          galaxyFoundSpeed: value,
                                        ),
                                      ),
                                    ),
                                    _RenderSlider(
                                      label: 'Boom',
                                      value: config.galaxyExplosionIntensity,
                                      max: 2,
                                      onChanged: (value) => controller.update(
                                        config.copyWith(
                                          galaxyExplosionIntensity: value,
                                        ),
                                      ),
                                    ),
                                    _RenderSlider(
                                      label: 'BoomSpd',
                                      value: config.galaxyExplosionSpeed,
                                      min: 0.05,
                                      max: 1.5,
                                      onChanged: (value) => controller.update(
                                        config.copyWith(
                                          galaxyExplosionSpeed: value,
                                        ),
                                      ),
                                    ),
                                    if (onTestMarketTick != null) ...[
                                      const SizedBox(height: 8),
                                      FilledButton(
                                        onPressed: onTestMarketTick,
                                        style: FilledButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xff5a82ff,
                                          ),
                                          foregroundColor: const Color(
                                            0xffeef3ff,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                        ),
                                        child: const Text(
                                          'TestBTC',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RenderSwitch extends StatelessWidget {
  const _RenderSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: Row(
        children: [
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.78),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Spacer(),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xffd6b5ff),
            activeTrackColor: const Color(0xffd6b5ff).withValues(alpha: 0.36),
            inactiveThumbColor: Colors.white.withValues(alpha: 0.54),
            inactiveTrackColor: Colors.white.withValues(alpha: 0.14),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

class _PaletteSelector extends StatelessWidget {
  const _PaletteSelector({required this.value, required this.onChanged});

  final TileColorPalette value;
  final ValueChanged<TileColorPalette> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<TileColorPalette>(
            value: value,
            isExpanded: true,
            dropdownColor: const Color(0xff101518),
            iconEnabledColor: Colors.white.withValues(alpha: 0.72),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
            items: [
              for (final palette in TileColorPalette.values)
                DropdownMenuItem(
                  value: palette,
                  child: _PaletteLabel(palette: palette),
                ),
            ],
            onChanged: (palette) {
              if (palette != null) {
                onChanged(palette);
              }
            },
          ),
        ),
      ),
    );
  }
}

class _PaletteLabel extends StatelessWidget {
  const _PaletteLabel({required this.palette});

  final TileColorPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                palette.colors.first,
                palette.colors[palette.colors.length ~/ 2],
                palette.colors.last,
              ],
            ),
          ),
          child: const SizedBox(width: 8, height: 8),
        ),
        const SizedBox(width: 6),
        Text(palette.label),
      ],
    );
  }
}

class _RenderSlider extends StatelessWidget {
  const _RenderSlider({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
    this.min = 0,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 78,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.visible,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max).toDouble(),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 34,
          child: Text(
            value.toStringAsFixed(2),
            textAlign: TextAlign.right,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.70),
              fontSize: 11,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

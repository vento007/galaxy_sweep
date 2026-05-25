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
                message: isOpen ? 'Hide Render Controls' : 'Show Render Controls',
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: isOpen ? 0.62 : 0.46),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: isOpen ? 0.18 : 0.10),
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
                                    _RenderSlider(
                                      label: 'Accent',
                                      value: config.piecePipColorPhase,
                                      max: 1,
                                      onChanged: (value) => controller.update(
                                        config.copyWith(piecePipColorPhase: value),
                                      ),
                                    ),
                                    _RenderSlider(
                                      label: 'Surface',
                                      value: config.tileSurfaceBoost,
                                      max: 1,
                                      onChanged: (value) => controller.update(
                                        config.copyWith(tileSurfaceBoost: value),
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
                                        config.copyWith(tileGlowIntensity: value),
                                      ),
                                    ),
                                    _RenderSlider(
                                      label: 'Nebula',
                                      value: config.tileNebulaIntensity,
                                      max: 2,
                                      onChanged: (value) => controller.update(
                                        config.copyWith(tileNebulaIntensity: value),
                                      ),
                                    ),
                                    _RenderSlider(
                                      label: 'Stars',
                                      value: config.tileStarsIntensity,
                                      max: 1,
                                      onChanged: (value) => controller.update(
                                        config.copyWith(tileStarsIntensity: value),
                                      ),
                                    ),
                                    _RenderSlider(
                                      label: 'Grain',
                                      value: config.tileGrainIntensity,
                                      max: 2,
                                      onChanged: (value) => controller.update(
                                        config.copyWith(tileGrainIntensity: value),
                                      ),
                                    ),
                                    _RenderSlider(
                                      label: 'Found',
                                      value: config.galaxyFoundIntensity,
                                      max: 2,
                                      onChanged: (value) => controller.update(
                                        config.copyWith(galaxyFoundIntensity: value),
                                      ),
                                    ),
                                    _RenderSlider(
                                      label: 'FoundSpd',
                                      value: config.galaxyFoundSpeed,
                                      min: 0.05,
                                      max: 1.5,
                                      onChanged: (value) => controller.update(
                                        config.copyWith(galaxyFoundSpeed: value),
                                      ),
                                    ),
                                    _RenderSlider(
                                      label: 'Boom',
                                      value: config.galaxyExplosionIntensity,
                                      max: 2,
                                      onChanged: (value) => controller.update(
                                        config.copyWith(galaxyExplosionIntensity: value),
                                      ),
                                    ),
                                    _RenderSlider(
                                      label: 'BoomSpd',
                                      value: config.galaxyExplosionSpeed,
                                      min: 0.05,
                                      max: 1.5,
                                      onChanged: (value) => controller.update(
                                        config.copyWith(galaxyExplosionSpeed: value),
                                      ),
                                    ),
                                    if (onTestMarketTick != null) ...[
                                      const SizedBox(height: 8),
                                      FilledButton(
                                        onPressed: onTestMarketTick,
                                        style: FilledButton.styleFrom(
                                          backgroundColor: const Color(0xff5a82ff),
                                          foregroundColor: const Color(0xffeef3ff),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
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

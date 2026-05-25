import 'package:flutter/foundation.dart';
import 'package:galaxy_sweep/render/render_config.dart';

class RenderConfigController extends ValueNotifier<RenderConfig> {
  RenderConfigController({RenderConfig initial = const RenderConfig()})
    : super(initial);

  RenderConfig get config => value;

  void update(RenderConfig config) {
    value = config;
  }
}

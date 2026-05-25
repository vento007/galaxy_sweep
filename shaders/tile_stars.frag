#include <flutter/runtime_effect.glsl>

precision mediump float;

uniform vec2 uSize;
uniform vec4 uBoard;
uniform float uTime;
uniform float uGridSize;
uniform float uIntensity;
uniform float uGap;

out vec4 fragColor;

float hash21(vec2 p) {
  p = fract(p * vec2(127.1, 311.7));
  p += dot(p, p + 19.19);

  return fract(p.x * p.y);
}

vec2 hash22(vec2 p) {
  return vec2(hash21(p), hash21(p + 41.37));
}

float roundedTileDistance(vec2 local, float gap, float radius) {
  float extent = max(0.08, 0.5 - gap * 0.5);
  vec2 tile = (local - 0.5) / extent;
  vec2 d = abs(tile) - vec2(1.0 - radius);

  return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - radius;
}

void main() {
  vec2 fragCoord = FlutterFragCoord().xy;
  vec2 boardUv = (fragCoord - uBoard.xy) / uBoard.zw;

  if (boardUv.x < 0.0 || boardUv.x > 1.0 || boardUv.y < 0.0 || boardUv.y > 1.0) {
    fragColor = vec4(0.0);
    return;
  }

  vec2 grid = boardUv * uGridSize;
  vec2 cell = floor(grid);
  vec2 local = fract(grid);
  float gap = clamp(uGap, 0.04, 0.38);
  float sdf = roundedTileDistance(local, gap, 0.30);
  float tileMask = smoothstep(0.000, -0.090, sdf);
  vec2 p = local - 0.5;
  vec3 color = vec3(0.0);
  float alpha = 0.0;

  for (int i = 0; i < 9; i++) {
    float index = float(i);
    vec2 seed = cell + vec2(index * 17.13, index * 5.91);
    vec2 rnd = hash22(seed);
    float angle = rnd.x * 6.2831853;
    vec2 direction = vec2(cos(angle), sin(angle));
    float speed = 0.085 + hash21(seed + 9.17) * 0.105;
    float depth = fract(uTime * speed + rnd.y);
    float easedDepth = depth * depth * (3.0 - 2.0 * depth);
    float radius = mix(0.020, 0.42, easedDepth);
    vec2 starPos = direction * radius;
    vec2 toPixel = p - starPos;
    float starSize = mix(0.0040, 0.018, easedDepth);
    float core = exp(-dot(toPixel, toPixel) / max(starSize * starSize, 0.00001));
    float alongTail = dot(toPixel, -direction);
    float acrossTail = abs(toPixel.x * direction.y - toPixel.y * direction.x);
    float tailLength = mix(0.012, 0.070, easedDepth);
    float tailWidth = mix(0.0022, 0.007, easedDepth);
    float tail =
        exp(-(acrossTail * acrossTail) / max(tailWidth * tailWidth, 0.00001)) *
        smoothstep(tailLength, 0.0, alongTail) *
        step(0.0, alongTail);
    float appear = smoothstep(0.02, 0.18, depth);
    float vanish = 1.0 - smoothstep(0.88, 1.0, depth);
    float brightness = appear * vanish * mix(0.24, 0.78, easedDepth);
    vec3 starColor = mix(
      vec3(0.64, 0.95, 1.0),
      vec3(1.0, 0.88, 0.62),
      hash21(seed + 21.73)
    );
    float starAlpha = (core * 0.86 + tail * 0.30) * brightness;

    color += starColor * starAlpha;
    alpha += starAlpha;
  }

  float vignette = 1.0 - smoothstep(0.34, 0.52, length(p));
  float strength = clamp(uIntensity, 0.0, 3.0) * tileMask * vignette;

  fragColor = vec4(color * strength, alpha * 0.82 * strength);
}

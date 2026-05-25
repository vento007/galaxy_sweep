#include <flutter/runtime_effect.glsl>

precision mediump float;

uniform vec2 uSize;
uniform vec4 uBoard;
uniform vec2 uCenter;
uniform float uAge;
uniform float uDuration;
uniform float uCellSize;
uniform float uPalette;
uniform float uIntensity;

out vec4 fragColor;

vec3 paletteSample(float palette, float t) {
  t = fract(t);

  vec3 a;
  vec3 b;
  vec3 c;
  vec3 d;

  if (palette < 0.5) {
    a = vec3(1.0, 0.302, 0.427);
    b = vec3(1.0, 0.820, 0.400);
    c = vec3(0.024, 0.839, 0.627);
    d = vec3(0.067, 0.541, 0.698);
  } else if (palette < 1.5) {
    a = vec3(1.0, 0.541, 0.239);
    b = vec3(0.961, 0.914, 0.376);
    c = vec3(0.282, 0.792, 0.894);
    d = vec3(0.722, 0.949, 0.902);
  } else {
    a = vec3(0.976, 0.255, 0.267);
    b = vec3(0.976, 0.780, 0.310);
    c = vec3(0.565, 0.745, 0.427);
    d = vec3(0.341, 0.459, 0.565);
  }

  float segment = t * 4.0;

  if (segment < 1.0) {
    return mix(a, b, smoothstep(0.0, 1.0, segment));
  }
  if (segment < 2.0) {
    return mix(b, c, smoothstep(0.0, 1.0, segment - 1.0));
  }
  if (segment < 3.0) {
    return mix(c, d, smoothstep(0.0, 1.0, segment - 2.0));
  }

  return mix(d, a, smoothstep(0.0, 1.0, segment - 3.0));
}

float hash21(vec2 p) {
  p = fract(p * vec2(123.34, 345.45));
  p += dot(p, p + 34.345);

  return fract(p.x * p.y);
}

float valueNoise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  vec2 u = f * f * (3.0 - 2.0 * f);

  return mix(
      mix(hash21(i), hash21(i + vec2(1.0, 0.0)), u.x),
      mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), u.x),
      u.y);
}

float nebulaNoise(vec2 p) {
  return valueNoise(p) * 0.52 +
      valueNoise(p * 2.03 + vec2(7.11, 3.17)) * 0.30 +
      valueNoise(p * 4.07 + vec2(13.71, 19.19)) * 0.18;
}

vec2 rotate(vec2 v, float a) {
  float c = cos(a);
  float s = sin(a);

  return vec2(v.x * c - v.y * s, v.x * s + v.y * c);
}

void main() {
  vec2 fragCoord = FlutterFragCoord().xy;
  vec2 boardUv = (fragCoord - uBoard.xy) / uBoard.zw;
  float edgeX = min(boardUv.x, 1.0 - boardUv.x);
  float edgeY = min(boardUv.y, 1.0 - boardUv.y);
  float boardFade = smoothstep(0.0, 0.03, min(edgeX, edgeY));

  float t = clamp(uAge / max(uDuration, 0.001), 0.0, 1.0);

  if (t >= 1.0 || uIntensity <= 0.0 || boardFade <= 0.0) {
    fragColor = vec4(0.0);
    return;
  }

  float env = smoothstep(0.0, 0.22, t) * (1.0 - smoothstep(0.74, 1.0, t));

  vec2 q = (fragCoord - uCenter) / max(uCellSize, 1.0);
  float r = length(q);

  float breathe = 0.86 + 0.14 * sin(t * 9.4);

  float spin = t * 2.2;
  vec2 sq = rotate(q, -spin);
  float sr = length(sq);
  float sa = atan(sq.y, sq.x);
  float discRadius = mix(0.28, 1.00, smoothstep(0.0, 0.5, t));
  float disc = exp(-(sr * sr) / (discRadius * discRadius));
  float armPhase = sa - log(sr + 0.16) * 2.3;
  float arms = smoothstep(0.05, 1.0, cos(armPhase * 2.0));
  float armTaper = smoothstep(0.04, 0.26, sr) * smoothstep(1.25, 0.45, sr);
  float galaxy = disc * (0.30 + arms * armTaper * 0.70);

  float coreGrow = 0.62 + 0.38 * smoothstep(0.0, 0.6, t);
  float coreBulge = exp(-(sr * sr) / 0.050);
  float corePin = exp(-(sr * sr) / 0.010);

  float ringAngle = atan(q.y, q.x);
  float rings = 0.0;
  for (int i = 0; i < 3; i++) {
    float prog = fract(t * 1.7 + float(i) * 0.34);
    float ringR = mix(2.70, 0.16, prog);
    vec2 ringSample = vec2(cos(ringAngle), sin(ringAngle)) * 2.4 +
        vec2(float(i) * 11.7, t * 0.5);
    float wobble = nebulaNoise(ringSample) - 0.5;
    float clump = nebulaNoise(ringSample * 1.8 + 21.3);
    ringR += wobble * 0.42;
    float width = 0.26 + clump * 0.20;
    float rd = (r - ringR) / width;
    float ring = exp(-rd * rd) * mix(0.30, 1.0, clump);
    rings += ring *
        smoothstep(0.0, 0.16, prog) *
        (1.0 - smoothstep(0.80, 1.0, prog));
  }

  vec2 nq = rotate(q, spin * 0.55) * 0.62;
  float haze = nebulaNoise(nq + vec2(t * 0.42, -t * 0.27));
  haze = smoothstep(0.42, 0.96, haze) * exp(-(r * r) / 2.6);

  float hue = 0.10 + t * 0.05 + sr * 0.05;
  vec3 coreCol = mix(vec3(1.0, 0.965, 0.90), paletteSample(uPalette, hue), 0.42);
  vec3 armCol = paletteSample(uPalette, hue + 0.40);
  vec3 hazeCol = paletteSample(uPalette, hue + 0.20);

  vec3 col = vec3(0.0);
  col += vec3(1.0, 0.97, 0.92) * corePin * 0.72;
  col += coreCol * coreBulge * 0.56 * coreGrow * breathe;
  col += coreCol * galaxy * 0.22 * breathe;
  col += armCol * galaxy * 0.34 * breathe;
  col += mix(coreCol, vec3(1.0), 0.35) * rings * 0.34;
  col += hazeCol * haze * 0.18;

  float alpha =
      corePin * 0.62 +
      coreBulge * 0.46 * coreGrow +
      galaxy * 0.32 +
      rings * 0.30 +
      haze * 0.15;

  float strength = clamp(uIntensity, 0.0, 4.0) * boardFade * env;

  fragColor = vec4(col * strength, clamp(alpha, 0.0, 1.0) * strength);
}

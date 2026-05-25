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

  vec2 q = (fragCoord - uCenter) / max(uCellSize, 1.0);
  float r = length(q);

  float coreSize = mix(0.18, 1.15, smoothstep(0.0, 0.13, uAge));
  float coreEnv = exp(-uAge * 8.5);
  float core = exp(-(r * r) / (coreSize * coreSize)) * coreEnv;
  float spike = exp(-(r * r) / 0.10) * exp(-uAge * 14.0);

  float waveSpeed = 6.8;
  float waveR = uAge * waveSpeed;
  float ringWidth = 0.32 + uAge * 1.10;
  float ringFade = (1.0 - t) * (1.0 - t);
  float dMid = (r - waveR) / ringWidth;
  float ring = exp(-dMid * dMid) * ringFade;
  float chroma = ringWidth * 0.55;
  float dRed = (r - (waveR + chroma)) / ringWidth;
  float dCyan = (r - (waveR - chroma)) / ringWidth;
  float ringRed = exp(-dRed * dRed) * ringFade;
  float ringCyan = exp(-dCyan * dCyan) * ringFade;

  float swirl = uAge * 1.50 - r * 0.55;
  float cs = cos(swirl);
  float sn = sin(swirl);
  vec2 nq = vec2(q.x * cs - q.y * sn, q.x * sn + q.y * cs);
  float cloud = nebulaNoise(nq * 0.85 + vec2(uAge * 0.40, -uAge * 0.25));
  cloud = smoothstep(0.30, 0.92, cloud);
  float haloSize = mix(0.80, 3.40, t);
  float halo = exp(-(r * r) / (haloSize * haloSize));
  float afterEnv = smoothstep(0.0, 0.22, uAge) * (1.0 - smoothstep(0.50, 1.0, t));
  float nebula = halo * (0.45 + cloud * 0.85) * afterEnv;

  float hue = uAge * 0.12 + r * 0.05;
  vec3 warm = paletteSample(uPalette, hue);
  vec3 cool = paletteSample(uPalette, hue + 0.45);
  vec3 white = vec3(1.0, 0.985, 0.95);

  vec3 col = vec3(0.0);
  col += white * (core * 0.50 + spike * 0.70);
  col += mix(white, warm, 0.5) * core * 0.22;
  col += vec3(1.0, 0.42, 0.55) * ringRed * 0.52;
  col += vec3(0.40, 0.92, 1.0) * ringCyan * 0.52;
  col += white * ring * 0.55;
  col += mix(cool, warm, cloud) * nebula * 0.80;

  float alpha = core * 0.44 +
      spike * 0.52 +
      ring * 0.50 +
      (ringRed + ringCyan) * 0.32 +
      nebula * 0.62;

  float strength = clamp(uIntensity, 0.0, 4.0) * boardFade;

  fragColor = vec4(col * strength, clamp(alpha, 0.0, 1.0) * strength);
}

#include <flutter/runtime_effect.glsl>

precision mediump float;

uniform vec2 uSize;
uniform vec4 uBoard;
uniform float uTime;
uniform float uPalette;
uniform float uGridSize;
uniform float uGlowIntensity;
uniform float uNebulaIntensity;
uniform float uSheenIntensity;
uniform float uGap;
uniform float uGrainIntensity;
uniform float uBlastCount;
uniform vec4 uBlast0;
uniform vec4 uBlast1;
uniform vec4 uBlast2;

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

float roundedTileDistance(vec2 local, float gap, float radius) {
  float extent = max(0.08, 0.5 - gap * 0.5);
  vec2 tile = (local - 0.5) / extent;
  vec2 d = abs(tile) - vec2(1.0 - radius);

  return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - radius;
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
  return valueNoise(p) * 0.48 +
      valueNoise(p * 2.03 + vec2(7.11, 3.17)) * 0.27 +
      valueNoise(p * 4.07 + vec2(13.71, 19.19)) * 0.16 +
      valueNoise(p * 8.13 + vec2(29.33, 11.57)) * 0.09;
}

float blastFieldAt(vec2 boardUv, vec4 blast) {
  if (blast.w <= 0.0) {
    return 0.0;
  }

  float progress = clamp(blast.z, 0.0, 1.0);
  float strength = clamp(blast.w, 0.0, 1.0);
  vec2 delta = boardUv - blast.xy;
  float dist = length(delta);
  float radius = mix(0.12, 0.42, progress);
  float core = exp(-(dist * dist) / max(radius * radius, 0.0001));
  float ringWidth = mix(0.040, 0.110, progress);
  float ring = exp(-pow((dist - radius * 0.82) / max(ringWidth, 0.0001), 2.0));
  float wash = smoothstep(radius * 1.65, 0.0, dist);

  return (core * 1.15 + ring * 0.82 + wash * 0.42) * strength;
}

void main() {
  vec2 fragCoord = FlutterFragCoord().xy;
  vec2 boardUv = (fragCoord - uBoard.xy) / uBoard.zw;

  if (boardUv.x < 0.0 || boardUv.x > 1.0 || boardUv.y < 0.0 || boardUv.y > 1.0) {
    fragColor = vec4(0.0);
    return;
  }

  float boardEdge = min(min(boardUv.x, 1.0 - boardUv.x), min(boardUv.y, 1.0 - boardUv.y));
  float boardFade = smoothstep(0.0, 0.012, boardEdge);
  vec2 grid = boardUv * uGridSize;
  vec2 cell = floor(grid);
  vec2 local = fract(grid);
  float gap = clamp(uGap, 0.04, 0.38);
  float sdf = roundedTileDistance(local, gap, 0.30);
  float tileMask = smoothstep(0.105, -0.024, sdf);
  float softInside = smoothstep(0.045, -0.060, sdf);
  float centerFalloff = exp(-dot(local - 0.5, local - 0.5) * 4.4) * softInside;
  float softAura = exp(-max(sdf, 0.0) * 8.0) * smoothstep(0.26, -0.10, sdf);
  float cellSeed = dot(cell, vec2(0.117, 0.073));
  float flow =
      sin((boardUv.x * 4.4 + boardUv.y * 3.1) * 6.283 + uTime * 0.72) * 0.5 +
      sin((cell.x - cell.y) * 0.63 + uTime * 1.18) * 0.32 +
      0.5;
  float hue = boardUv.x * 0.46 + boardUv.y * 0.38 + cellSeed + uTime * 0.030;
  vec3 color = paletteSample(uPalette, hue + flow * 0.025);
  vec3 hot = mix(color, vec3(0.92, 1.0, 0.94), 0.24 + centerFalloff * 0.24);
  float shimmer = smoothstep(0.55, 1.18, flow);

  float grainAmount = clamp(uGrainIntensity, 0.0, 3.0);
  float grainSoft = nebulaNoise(boardUv * 26.0 + vec2(uTime * 0.012, 0.0));
  float grainFine = valueNoise(boardUv * 140.0);
  float grainField = mix(grainSoft, grainFine, 0.55);
  float grainModulation = 1.0 + (grainField - 0.5) * 0.68 * grainAmount;
  vec3 dustColor = mix(color, vec3(0.85, 0.90, 1.0), 0.40);
  float dust = grainField * softInside * 0.05 * grainAmount * boardFade;

  float glowAlpha =
      (centerFalloff * 0.145 +
          softAura * 0.040 +
          shimmer * tileMask * 0.050) *
      grainModulation;
  vec2 nebulaUv = local * 2.35 +
      cell * 0.31 +
      vec2(uTime * 0.045, -uTime * 0.032) +
      vec2(sin(cellSeed * 29.0 + uTime * 0.21), cos(cellSeed * 23.0 - uTime * 0.18)) * 0.08;
  float cloud = nebulaNoise(nebulaUv + flow * 0.16);
  cloud = smoothstep(0.34, 0.86, cloud);
  float filament =
      sin((local.x * 3.4 + local.y * 5.1 + cloud * 2.2 + cellSeed * 18.0 + uTime * 0.24) * 6.283) * 0.5 + 0.5;
  filament = smoothstep(0.76, 1.0, filament) * cloud;
  vec3 nebulaA = paletteSample(uPalette, hue + 0.18 + cloud * 0.12);
  vec3 nebulaB = paletteSample(uPalette, hue + 0.54 - cloud * 0.10);
  vec3 nebulaColor = mix(nebulaA, nebulaB, flow * 0.55 + 0.22);
  float nebulaAlpha =
      (cloud * 0.060 + filament * 0.042) * softInside * grainModulation;
  vec2 sheenDirection = normalize(vec2(
      0.74 + sin(cellSeed * 18.0) * 0.18,
      -0.58 + cos(cellSeed * 13.0) * 0.16));
  vec2 sheenPerp = vec2(-sheenDirection.y, sheenDirection.x);
  float sheenTravel = fract(uTime * 0.035 + cellSeed * 5.7) * 1.92 - 0.96;
  float sheenDistance = dot(local - 0.5, sheenDirection) - sheenTravel;
  float sheenBand = exp(-(sheenDistance * sheenDistance) / 0.014);
  float sheenSecondary = exp(-((sheenDistance + 0.18) * (sheenDistance + 0.18)) / 0.040) * 0.32;
  float sheenMask = smoothstep(0.030, -0.065, sdf) * (0.62 + centerFalloff * 0.38);
  float spectralPhase =
      hue +
      dot(local - 0.5, sheenPerp) * 0.48 +
      cloud * 0.10 +
      uTime * 0.018;
  vec3 spectral = 0.62 + 0.38 * cos(
      6.2831853 * (vec3(0.00, 0.30, 0.62) + spectralPhase));
  vec3 sheenColor = mix(vec3(0.95, 1.0, 0.96), spectral, 0.46);
  float sheenAlpha = (sheenBand * 0.082 + sheenSecondary * 0.036) * sheenMask;
  float glowStrength = clamp(uGlowIntensity, 0.0, 3.0) * boardFade;
  float nebulaStrength = clamp(uNebulaIntensity, 0.0, 3.0) * boardFade;
  float sheenStrength = clamp(uSheenIntensity, 0.0, 3.0) * boardFade;
  float blastField = 0.0;

  if (uBlastCount > 0.5) {
    blastField = max(blastField, blastFieldAt(boardUv, uBlast0));
  }
  if (uBlastCount > 1.5) {
    blastField = max(blastField, blastFieldAt(boardUv, uBlast1));
  }
  if (uBlastCount > 2.5) {
    blastField = max(blastField, blastFieldAt(boardUv, uBlast2));
  }

  blastField = clamp(blastField * 1.12, 0.0, 1.0);
  float blastPresence = step(0.5, uBlastCount);
  float farQuiet = 1.0 - clamp(blastField * 1.2, 0.0, 1.0);
  float quietDown = mix(1.0, 0.82, blastPresence * farQuiet);
  float localTurbulence = 1.0 + blastField * 0.14;
  glowAlpha *= localTurbulence;
  nebulaAlpha *= mix(1.0, 1.06, blastField);
  sheenAlpha *= mix(1.0, 1.16, blastField);
  float glowMaterial = quietDown * (1.0 + blastField * 2.15);
  float nebulaMaterial = quietDown * (1.0 + blastField * 0.82);
  float sheenMaterial = quietDown * (1.0 + blastField * 1.35);
  vec3 finalColor =
      hot * glowAlpha * glowStrength * glowMaterial +
      nebulaColor * nebulaAlpha * nebulaStrength * nebulaMaterial +
      sheenColor * sheenAlpha * sheenStrength * sheenMaterial +
      dustColor * dust;
  float finalAlpha =
      glowAlpha * glowStrength * glowMaterial +
      nebulaAlpha * 0.92 * nebulaStrength * nebulaMaterial +
      sheenAlpha * 0.88 * sheenStrength * sheenMaterial +
      dust;

  fragColor = vec4(finalColor, finalAlpha);
}

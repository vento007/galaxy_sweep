# Changelog

## 1.2.0+3

- Replaced the centered market-spawn notification with a board-region signal
  frame that hints at the area without revealing the exact hidden galaxy.
- Added a small BTC signal label to the market region frame.
- Added scan-band shimmer and tile-mesh warping inside the active market signal
  region.
- Added a signal trigger dropdown for BTC / 5, BTC / 2, and timed signals.

## 1.1.0+2

- Added a manual tile palette selector in the render controls.
- Added multiple tile color palettes for the board surface.
- Connected the selected palette to the vertex-rendered tile colors.
- Passed the selected palette through to the tile nebula shader.
- Added a render control for comparing the original tile shape with the
  squircle variant.
- Added render controls for tile energy and tile energy speed.

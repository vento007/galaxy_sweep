import 'dart:ui';

class TileColors {
  const TileColors({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  });

  final Color topLeft;
  final Color topRight;
  final Color bottomLeft;
  final Color bottomRight;

  TileColors withAlpha(double alpha) {
    final topleft = topLeft.withValues(alpha: alpha);
    final topRightColor = topRight.withValues(alpha: alpha);
    final bottomLeftColor = bottomLeft.withValues(alpha: alpha);
    final bottomRightColor = bottomRight.withValues(alpha: alpha);

    return TileColors(
      topLeft: topleft,
      topRight: topRightColor,
      bottomLeft: bottomLeftColor,
      bottomRight: bottomRightColor,
    );
  }
}

class TileColorPicker {
  const TileColorPicker();

  TileColors colorsForTile({
    required int row,
    required int column,
    required double time,
  }) {
    return const TileColors(
      topLeft: Color(0xff1b91e8),
      topRight: Color(0xff1b91e8),
      bottomLeft: Color(0xff1b91e8),
      bottomRight: Color(0xff1b91e8),
    );
  }
}

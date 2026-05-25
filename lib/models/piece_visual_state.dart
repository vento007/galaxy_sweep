import 'dart:ui';

sealed class PieceVisualState {
  const PieceVisualState();
}

class PieceIdle extends PieceVisualState {
  const PieceIdle();
}

class PieceDragging extends PieceVisualState {
  const PieceDragging({
    required this.pointerPosition,
    required this.grabOffset,
    required this.hoveredIndex,
  });

  final Offset pointerPosition;
  final Offset grabOffset;
  final int hoveredIndex;
}

class PieceMoving extends PieceVisualState {
  const PieceMoving({
    required this.fromIndex,
    required this.fromCenter,
    required this.toIndex,
    required this.displayDistance,
    required this.startedAt,
    required this.duration,
  });

  final int fromIndex;
  final Offset fromCenter;
  final int toIndex;
  final int? displayDistance;
  final double startedAt;
  final double duration;
}

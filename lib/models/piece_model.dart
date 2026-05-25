import 'package:galaxy_sweep/models/piece_visual_state.dart';

class BoardPiece {
  const BoardPiece({
    required this.id,
    required this.cellIndex,
    this.visualState = const PieceIdle(),
  });

  final int id;
  final int cellIndex;
  final PieceVisualState visualState;

  BoardPiece copyWith({int? cellIndex, PieceVisualState? visualState}) {
    return BoardPiece(
      id: id,
      cellIndex: cellIndex ?? this.cellIndex,
      visualState: visualState ?? this.visualState,
    );
  }
}

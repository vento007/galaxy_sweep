import 'package:galaxy_sweep/models/galaxy_state.dart';

class BoardGalaxy {
  const BoardGalaxy({
    required this.id,
    required this.cellIndex,
    this.state = GalaxyState.hidden,
  });
  final int id;
  final int cellIndex;
  final GalaxyState state;

  BoardGalaxy copyWith({int? cellIndex, GalaxyState? state}) {
    return BoardGalaxy(
      id: id,
      cellIndex: cellIndex ?? this.cellIndex,
      state: state ?? this.state,
    );
  }
}

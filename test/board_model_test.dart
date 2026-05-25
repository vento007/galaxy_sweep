import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_sweep/models/board_model.dart';

void main() {
  test('creates board cells when constructed', () {
    final model = BoardModel(boardSize: 10);

    expect(model.cells.length, 100);
    expect(model.pieces, isEmpty);
    expect(model.galaxies, isEmpty);
  });

  test('uses constructor board size for board cells', () {
    final model = BoardModel(boardSize: 12);

    expect(model.cells.length, 144);
    expect(model.cells.last.row, 11);
    expect(model.cells.last.column, 11);
  });
}

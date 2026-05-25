import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_sweep/game/board/board_layout.dart';
import 'package:galaxy_sweep/game/board/drag_target_resolver.dart';

void main() {
  const resolver = DragTargetResolver();

  BoardLayout layout() {
    return BoardLayout(
      canvasSize: const Size(1000, 1000),
      boardSize: 10,
      gap: 0,
    );
  }

  test('uses actual cell when piece center is over another cell', () {
    final boardLayout = layout();
    final target = resolver.resolve(
      sourceIndex: 44,
      pieceCenter: boardLayout.cellCenterForIndex(45),
      layout: boardLayout,
    );

    expect(target.index, 45);
    expect(target.source, 'actual');
  });

  test('keeps source when drag is below intent distance', () {
    final boardLayout = layout();
    final sourceCenter = boardLayout.cellCenterForIndex(44);
    final target = resolver.resolve(
      sourceIndex: 44,
      pieceCenter: sourceCenter + const Offset(8, 0),
      layout: boardLayout,
    );

    expect(target.index, 44);
    expect(target.source, 'same');
  });

  test(
    'uses swipe target when released inside source cell after intent drag',
    () {
      final boardLayout = layout();
      final sourceCenter = boardLayout.cellCenterForIndex(44);
      final target = resolver.resolve(
        sourceIndex: 44,
        pieceCenter: sourceCenter + const Offset(16, 0),
        layout: boardLayout,
      );

      expect(target.index, 45);
      expect(target.source, 'swipe');
    },
  );

  test('keeps source when released outside board', () {
    final boardLayout = layout();
    final target = resolver.resolve(
      sourceIndex: 44,
      pieceCenter: const Offset(-100, -100),
      layout: boardLayout,
    );

    expect(target.index, 44);
    expect(target.source, 'outside');
  });
}

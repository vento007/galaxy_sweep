import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_sweep/render/board_painter.dart';

import 'package:galaxy_sweep/main.dart';

void main() {
  testWidgets('renders the game board', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(
      find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is BoardPainter,
      ),
      findsOneWidget,
    );
  });
}

import 'package:final_project/widgets/motion_reveal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('staggered entrance finishes and honors reduced motion', (
    tester,
  ) async {
    Widget app({required bool reduceMotion}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: const MotionReveal(
          delay: Duration(milliseconds: 200),
          duration: Duration(milliseconds: 300),
          child: Text('Ready'),
        ),
      ),
    );

    double opacity() => tester
        .widget<FadeTransition>(
          find.descendant(
            of: find.byType(MotionReveal),
            matching: find.byType(FadeTransition),
          ),
        )
        .opacity
        .value;

    await tester.pumpWidget(app(reduceMotion: false));
    await tester.pump(const Duration(milliseconds: 100));
    expect(opacity(), 0);
    await tester.pumpAndSettle();
    expect(opacity(), 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(app(reduceMotion: true));
    expect(opacity(), 1);
  });
}

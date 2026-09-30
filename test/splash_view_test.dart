import 'package:final_project/views/splash_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows Spendi branding while the app starts', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashView()));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Spendi'), findsOneWidget);
    expect(find.text('A little clarity for every peso.'), findsOneWidget);
    expect(find.byIcon(Icons.account_balance_wallet_rounded), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('offers retry when startup fails', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: SplashView(
          errorMessage: 'Could not connect.',
          onRetry: () => retried = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not connect.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.tap(find.text('Try again'));
    expect(retried, isTrue);
  });
}

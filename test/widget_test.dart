// This is a basic Flutter widget test.
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:echelon_connect/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: EchelonConnectApp(),
      ),
    );

    // Verify the app title is displayed
    expect(find.text('ECHELON CONNECT'), findsOneWidget);
  });
}

// Basic smoke test for Emlaktan app

import 'package:flutter_test/flutter_test.dart';
import 'package:emlaktan_app/main.dart';

void main() {
  testWidgets('App starts without error', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const EmlaktanApp());

    // Verify that app starts (shows splash or login screen)
    // The app should render without throwing
    expect(find.byType(EmlaktanApp), findsOneWidget);
  });
}

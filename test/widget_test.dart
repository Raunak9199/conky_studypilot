import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:conky_studypilot/app/app.dart';

void main() {
  testWidgets('App boots and shows Today screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const StudyPilotApp());

    // Verify that the Today screen is shown with mocked data.
    expect(find.text('DAY 1 / 30'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}

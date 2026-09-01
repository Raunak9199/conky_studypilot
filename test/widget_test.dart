import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:conky_studypilot/app/app.dart';

void main() {
  testWidgets('App boots and shows Today screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const StudyPilotApp());

    // Verify that the Today screen skeleton is shown.
    expect(find.text('Today Screen Skeleton'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}

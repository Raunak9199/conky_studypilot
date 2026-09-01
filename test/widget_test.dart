import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:conky_studypilot/app/app.dart';
import 'package:conky_studypilot/services/schedule_service.dart';
import 'package:conky_studypilot/data/study_plan.dart';

void main() {
  testWidgets('App boots and shows Today screen', (WidgetTester tester) async {
    final scheduleService = ScheduleService(enableNotifications: false);
    scheduleService.startDay(StaticStudyPlan.plan30Days[0]);

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: scheduleService,
        child: const StudyPilotApp(),
      ),
    );

    // Verify that the Today screen is shown with mocked data.
    expect(find.text('DAY 1 / 30'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    scheduleService.stop();
  });
}

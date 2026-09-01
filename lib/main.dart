import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'services/notification_service.dart';
import 'services/schedule_service.dart';
import 'data/study_plan.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications
  await NotificationService().init();

  // Load saved day
  final prefs = await SharedPreferences.getInstance();
  final savedDayNumber = prefs.getInt('currentDayNumber') ?? 1;
  // Ensure we don't go out of bounds (1-30)
  final dayIndex = (savedDayNumber - 1).clamp(0, 29);

  // Create schedule service and restore state
  final scheduleService = ScheduleService();
  await scheduleService.init();
  scheduleService.startDay(StaticStudyPlan.plan30Days[dayIndex]);

  runApp(
    ChangeNotifierProvider.value(
      value: scheduleService,
      child: const StudyPilotApp(),
    ),
  );
}

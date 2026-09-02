import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'services/notification_service.dart';
import 'services/schedule_service.dart';
import 'services/sync_service.dart';
import 'data/study_plan.dart';
import 'models/study_day.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications
  await NotificationService().init();

  // Initialize Sync Service
  final syncService = SyncService();
  await syncService.init();

  // Load last known synced schedule from local storage
  List<StudyDay>? syncedDays;
  final localData = await syncService.getLocalSyncData();
  if (localData != null) {
    try {
      syncedDays = syncService.parseScheduleToStudyDays(localData['schedule']);
    } catch (e) {
      debugPrint("Error parsing local sync data: \$e");
    }
  }

  // Attempt automatic sync in the background
  syncService.fetchSyncData().then((networkData) {
    // We will let the UI (Settings screen) handle manual sync updates for now,
    // but we could pipe this directly to scheduleService here if we wanted immediate background updates.
  });

  // Load saved day
  final prefs = await SharedPreferences.getInstance();
  final savedDayNumber = prefs.getInt('currentDayNumber') ?? 1;

  // Create schedule service and restore state
  final scheduleService = ScheduleService();
  await scheduleService.init(syncedDays: syncedDays);
  
  // Start the appropriate day
  final planToUse = syncedDays ?? StaticStudyPlan.plan30Days;
  final dayIndex = (savedDayNumber - 1).clamp(0, planToUse.length - 1);
  scheduleService.startDay(planToUse[dayIndex]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: scheduleService),
        ChangeNotifierProvider.value(value: syncService),
      ],
      child: const StudyPilotApp(),
    ),
  );
}

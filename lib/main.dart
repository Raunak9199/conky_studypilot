import 'package:flutter/material.dart';

import 'app/app.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notifications
  await NotificationService().init();

  runApp(const StudyPilotApp());
}

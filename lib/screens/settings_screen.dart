import 'package:flutter/material.dart';

import 'package:timezone/timezone.dart' as tz;

import '../models/study_session.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const ListTile(
            title: Text('Notifications'),
            subtitle: Text('Manage your study schedule alerts'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications_active),
            title: const Text('Test Notification'),
            subtitle: const Text('Trigger an immediate test alert'),
            trailing: const Icon(Icons.play_arrow),
            onTap: () {
              NotificationService().showTestNotification();
            },
          ),
          ListTile(
            leading: const Icon(Icons.alarm),
            title: const Text('Test Exact Alarm (10 Sec)'),
            subtitle: const Text('Schedules a notification 10 seconds from now'),
            trailing: const Icon(Icons.schedule),
            onTap: () {
              final testSession = StudySession(
                id: 'test_alarm_10s',
                title: 'Test Exact Alarm',
                description: 'This is a scheduled alarm',
                startTime: Duration.zero,
                duration: const Duration(minutes: 5),
              );
              final scheduledTime = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10));
              NotificationService().scheduleSessionNotification(testSession, scheduledTime);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Alarm scheduled for 10 seconds from now')),
              );
            },
          ),
        ],
      ),
    );
  }
}

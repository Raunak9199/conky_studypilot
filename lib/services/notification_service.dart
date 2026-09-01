import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/study_session.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Initialize timezone data
    tz.initializeTimeZones();

    // Android initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestSoundPermission: false,
          requestBadgePermission: false,
          requestAlertPermission: false,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap here if needed
      },
    );

    // Request permissions for Android 13+
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> showTestNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'studypilot_test_channel_id',
          'StudyPilot Test Notifications',
          channelDescription: 'Channel for testing StudyPilot notifications',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: false,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      id: 0,
      title: 'Test Notification',
      body: 'This is a test notification from Conky StudyPilot!',
      notificationDetails: platformChannelSpecifics,
      payload: 'test_payload',
    );
  }

  /// Schedules a notification for a specific session
  Future<void> scheduleSessionNotification(
    StudySession session,
    tz.TZDateTime scheduledTime,
  ) async {
    // Before scheduling, ensure we have exact alarm permission
    final androidImplementation = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    // Request exact alarm permission if not granted
    final hasExactAlarm = await androidImplementation
        ?.canScheduleExactNotifications();
    if (hasExactAlarm != null && !hasExactAlarm) {
      await androidImplementation?.requestExactAlarmsPermission();
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'studypilot_schedule_channel_id',
          'StudyPilot Schedule',
          channelDescription: 'Notifications for your study sessions',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id: session.id.hashCode,
      title: '🔔 STUDY TIME',
      body: '${session.title}\n${_formatTimeRange(session)}',
      scheduledDate: scheduledTime,
      notificationDetails: platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  String _formatTimeRange(StudySession session) {
    final start = session.startTime;
    final end = Duration(minutes: start.inMinutes + session.duration.inMinutes);
    return '${_formatDuration(start)} – ${_formatDuration(end)}';
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}

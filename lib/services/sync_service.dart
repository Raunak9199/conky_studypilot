import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/study_day.dart';
import '../models/study_session.dart';

class SyncService extends ChangeNotifier {
  static const String keyIp = 'sync_ip';
  static const String keyPort = 'sync_port';
  static const String keyToken = 'sync_token';
  static const String keyLastSync = 'sync_last_timestamp';
  static const String keyLastSchedule = 'sync_last_schedule';

  String _ip = '';
  String _port = '8080';
  String _token = '';
  DateTime? _lastSync;
  bool _isOnline = false;

  String get ip => _ip;
  String get port => _port;
  String get token => _token;
  DateTime? get lastSync => _lastSync;
  bool get isOnline => _isOnline;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _ip = prefs.getString(keyIp) ?? '';
    _port = prefs.getString(keyPort) ?? '8080';
    _token = prefs.getString(keyToken) ?? '';
    final lastSyncStr = prefs.getString(keyLastSync);
    if (lastSyncStr != null) {
      _lastSync = DateTime.parse(lastSyncStr);
    }
  }

  Future<void> saveSettings(String ip, String port, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyIp, ip);
    await prefs.setString(keyPort, port);
    await prefs.setString(keyToken, token);
    _ip = ip;
    _port = port;
    _token = token;
    notifyListeners();
  }

  Future<bool> checkStatus() async {
    if (_ip.isEmpty) return false;
    try {
      final response = await http
          .get(Uri.parse('http://$_ip:$_port/api/status'))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        _isOnline = true;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Status check failed: $e");
    }
    _isOnline = false;
    notifyListeners();
    return false;
  }

  Future<Map<String, dynamic>?> fetchSyncData() async {
    if (_ip.isEmpty || _token.isEmpty) return null;

    try {
      final response = await http
          .get(
            Uri.parse('http://$_ip:$_port/api/sync'),
            headers: {'Sync-Token': _token},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Save locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(keyLastSchedule, response.body);
        _lastSync = DateTime.now();
        await prefs.setString(keyLastSync, _lastSync!.toIso8601String());

        _isOnline = true;
        notifyListeners();

        return data;
      } else {
        debugPrint("Sync failed with status: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Fetch sync data failed: $e");
    }

    _isOnline = false;
    notifyListeners();
    return null;
  }

  Future<Map<String, dynamic>?> getLocalSyncData() async {
    final prefs = await SharedPreferences.getInstance();
    final dataStr = prefs.getString(keyLastSchedule);
    if (dataStr != null) {
      try {
        return json.decode(dataStr);
      } catch (e) {
        debugPrint("Failed to decode local sync data: $e");
      }
    }
    return null;
  }

  /// Parses the raw JSON from Desktop into a list of Flutter StudyDay objects
  List<StudyDay> parseScheduleToStudyDays(Map<String, dynamic> scheduleJson) {
    final slots = scheduleJson['slots'] as List;
    final days = scheduleJson['days'] as Map<String, dynamic>;

    List<StudyDay> studyDays = [];

    // Sort day keys as integers
    final dayKeys = days.keys.toList()
      ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

    if (dayKeys.isEmpty) {
      // Fallback empty days
      for (int i = 1; i <= 30; i++) {
        studyDays.add(StudyDay(dayNumber: i, sessions: []));
      }
    } else {
      // Parse defined days
      Map<int, List<StudySession>> parsedDays = {};

      for (String dKey in dayKeys) {
        final dayNumber = int.parse(dKey);
        final topics = days[dKey] as List;

        List<StudySession> sessions = [];
        int sessionId = 1;

        for (final slot in slots) {
          final startStr = slot[0] as String;
          final endStr = slot[1] as String;
          final name = slot[2] as String;

          String description = "General Study";
          for (final topic in topics) {
            if ((topic[0] as String).toUpperCase() == name.toUpperCase()) {
              description = topic[1] as String;
              break;
            }
          }

          final startParts = startStr.split(':');
          final endParts = endStr.split(':');
          final startMinutes =
              int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
          final endMinutes =
              int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

          sessions.add(
            StudySession(
              id: '${dayNumber}_${sessionId++}',
              title: name,
              description: description,
              startTime: Duration(minutes: startMinutes),
              duration: Duration(minutes: endMinutes - startMinutes),
            ),
          );
        }
        parsedDays[dayNumber] = sessions;
      }

      // Generate 30 days based on defined patterns
      final maxDefinedDay = parsedDays.keys.reduce((a, b) => a > b ? a : b);
      for (int i = 1; i <= 30; i++) {
        List<StudySession> sessionsForDay;

        if (parsedDays.containsKey(i)) {
          // Exact match
          sessionsForDay = parsedDays[i]!;
        } else if (maxDefinedDay == 1) {
          // "Same for all days" logic
          sessionsForDay = parsedDays[1]!
              .map(
                (s) => StudySession(
                  id: '${i}_${s.id.split('_').last}',
                  title: s.title,
                  description: s.description,
                  startTime: s.startTime,
                  duration: s.duration,
                ),
              )
              .toList();
        } else if (maxDefinedDay == 7) {
          // "Weekly" logic (modulo 7)
          int weekDay = ((i - 1) % 7) + 1;
          sessionsForDay = parsedDays.containsKey(weekDay)
              ? parsedDays[weekDay]!
                    .map(
                      (s) => StudySession(
                        id: '${i}_${s.id.split('_').last}',
                        title: s.title,
                        description: s.description,
                        startTime: s.startTime,
                        duration: s.duration,
                      ),
                    )
                    .toList()
              : [];
        } else {
          // Fallback to empty if it's missing (e.g. user manually deleted a day)
          sessionsForDay = [];
        }

        studyDays.add(StudyDay(dayNumber: i, sessions: sessionsForDay));
      }
    }

    return studyDays;
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:timezone/timezone.dart' as tz;

import '../models/study_day.dart';
import '../models/study_session.dart';
import 'notification_service.dart';

class ScheduleService extends ChangeNotifier {
  final bool enableNotifications;
  ScheduleService({this.enableNotifications = true});

  StudyDay? _currentDay;
  Timer? _ticker;

  // Real time minus any pause shift
  DateTime _effectiveTime = DateTime.now();

  bool _isPaused = false;
  Duration _totalPauseOffset = Duration.zero;
  DateTime? _pauseStartTime;

  // State exposed to UI
  StudySession? _currentSession;
  StudySession? _nextSession;
  Duration _timeRemainingInCurrent = Duration.zero;
  Duration _timeUntilNext = Duration.zero;

  StudyDay? get currentDay => _currentDay;
  StudySession? get currentSession => _currentSession;
  StudySession? get nextSession => _nextSession;
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isPaused = prefs.getBool('isPaused') ?? false;
    final offsetSecs = prefs.getInt('totalPauseOffset') ?? 0;
    _totalPauseOffset = Duration(seconds: offsetSecs);

    final pauseStartStr = prefs.getString('pauseStartTime');
    if (pauseStartStr != null) {
      _pauseStartTime = DateTime.parse(pauseStartStr);
    }
  }

  Future<void> _saveState() async {
    // In test environments where we disable notifications, we also might not have SharedPreferences
    if (!enableNotifications) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPaused', _isPaused);
    await prefs.setInt('totalPauseOffset', _totalPauseOffset.inSeconds);
    if (_pauseStartTime != null) {
      await prefs.setString(
        'pauseStartTime',
        _pauseStartTime!.toIso8601String(),
      );
    } else {
      await prefs.remove('pauseStartTime');
    }
    if (_currentDay != null) {
      await prefs.setInt('currentDayNumber', _currentDay!.dayNumber);
    }
  }

  Duration get timeRemainingInCurrent => _timeRemainingInCurrent;
  Duration get timeUntilNext => _timeUntilNext;
  bool get isPaused => _isPaused;

  Duration get currentTotalOffset {
    if (_isPaused && _pauseStartTime != null) {
      return _totalPauseOffset + DateTime.now().difference(_pauseStartTime!);
    }
    return _totalPauseOffset;
  }

  /// Calculates the shifted real-world start time of a session
  DateTime getShiftedStartTime(StudySession session) {
    final midnight = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    return midnight.add(session.startTime).add(currentTotalOffset);
  }

  /// Calculates the shifted real-world end time of a session
  DateTime getShiftedEndTime(StudySession session) {
    final midnight = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    return midnight
        .add(session.startTime)
        .add(session.duration)
        .add(currentTotalOffset);
  }

  /// Start the schedule for a given day
  void startDay(StudyDay day, {DateTime? simulatedTime}) {
    _currentDay = day;
    _saveState();

    // Cancel old ticker
    _ticker?.cancel();

    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (simulatedTime != null) {
        if (!_isPaused) {
          _effectiveTime = _effectiveTime.add(const Duration(seconds: 1));
        }
      } else {
        _effectiveTime = DateTime.now().subtract(currentTotalOffset);
      }
      _updateState();
    });

    if (simulatedTime != null) {
      _effectiveTime = simulatedTime;
    } else {
      _effectiveTime = DateTime.now().subtract(currentTotalOffset);
    }

    if (enableNotifications) {
      _rescheduleAllNotifications();
    }
    _updateState();
  }

  /// Change the current day and reset the schedule
  void changeDay(StudyDay day) {
    _isPaused = false;
    _totalPauseOffset = Duration.zero;
    _pauseStartTime = null;
    startDay(day);
  }

  /// Reset the pause state for the current day
  void resetPauseState() {
    _isPaused = false;
    _totalPauseOffset = Duration.zero;
    _pauseStartTime = null;
    if (_currentDay != null) {
      startDay(_currentDay!);
    }
  }

  void stop() {
    _ticker?.cancel();
    _ticker = null;
  }

  void togglePause() {
    if (_isPaused) {
      // Resuming
      _isPaused = false;
      if (_pauseStartTime != null) {
        final pauseDuration = DateTime.now().difference(_pauseStartTime!);
        _totalPauseOffset += pauseDuration;
        _pauseStartTime = null;
      }
      _updateState();
      _saveState();

      if (enableNotifications) {
        _rescheduleAllNotifications();
      }
    } else {
      // Pausing
      _isPaused = true;
      _pauseStartTime = DateTime.now();
      _saveState();

      if (enableNotifications) {
        // Cancel all upcoming alarms since we don't know when we'll resume
        NotificationService().cancelAllNotifications();
      }

      notifyListeners();
    }
  }

  /// Fast-forward or manipulate time for tests
  @visibleForTesting
  void advanceTime(Duration duration) {
    _effectiveTime = _effectiveTime.add(duration);
    _updateState();
  }

  void _updateState() {
    if (_currentDay == null) return;

    final now = _effectiveTime;

    // Convert current time to a duration since midnight to match session.startTime
    final durationSinceMidnight = Duration(
      hours: now.hour,
      minutes: now.minute,
      seconds: now.second,
    );

    _currentSession = null;
    _nextSession = null;

    for (int i = 0; i < _currentDay!.sessions.length; i++) {
      final session = _currentDay!.sessions[i];
      final sessionStart = session.startTime;
      final sessionEnd = sessionStart + session.duration;

      if (durationSinceMidnight >= sessionStart &&
          durationSinceMidnight < sessionEnd) {
        _currentSession = session;
        _timeRemainingInCurrent = sessionEnd - durationSinceMidnight;

        if (i + 1 < _currentDay!.sessions.length) {
          _nextSession = _currentDay!.sessions[i + 1];
          _timeUntilNext = _nextSession!.startTime - durationSinceMidnight;
        } else {
          _nextSession = null;
          _timeUntilNext = Duration.zero;
        }
        break;
      } else if (durationSinceMidnight < sessionStart) {
        if (_currentSession == null && _nextSession == null) {
          _nextSession = session;
          _timeUntilNext = sessionStart - durationSinceMidnight;
        }
      }
    }

    notifyListeners();
  }

  Future<void> _rescheduleAllNotifications() async {
    if (_currentDay == null) return;
    final notificationService = NotificationService();

    // Cancel any existing notifications first
    await notificationService.cancelAllNotifications();

    final now = DateTime.now();

    for (final session in _currentDay!.sessions) {
      final shiftedStart = getShiftedStartTime(session);

      // Only schedule if the shifted start time is in the future
      if (shiftedStart.isAfter(now)) {
        final tzScheduledTime = tz.TZDateTime.from(shiftedStart, tz.local);
        await notificationService.scheduleSessionNotification(
          session,
          tzScheduledTime,
        );
      }
    }
  }
}

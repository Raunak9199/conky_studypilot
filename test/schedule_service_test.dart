import 'package:flutter_test/flutter_test.dart';
import 'package:conky_studypilot/models/study_day.dart';
import 'package:conky_studypilot/models/study_session.dart';
import 'package:conky_studypilot/services/schedule_service.dart';

void main() {
  group('ScheduleService', () {
    late ScheduleService scheduleService;
    late StudyDay mockDay;

    setUp(() {
      scheduleService = ScheduleService(enableNotifications: false);
      
      // Mock day with sessions starting at 10:00 AM
      mockDay = StudyDay(
        dayNumber: 1,
        sessions: [
          StudySession(
            id: 's1',
            title: 'Session 1',
            description: 'Desc 1',
            startTime: const Duration(hours: 10),
            duration: const Duration(hours: 1),
          ),
          StudySession(
            id: 's2',
            title: 'Session 2',
            description: 'Desc 2',
            startTime: const Duration(hours: 11, minutes: 15),
            duration: const Duration(hours: 1),
          ),
        ],
      );
    });

    tearDown(() {
      scheduleService.stop();
    });

    test('Identifies current session correctly', () {
      // Set time to 10:30 AM
      final time = DateTime(2023, 10, 1, 10, 30);
      scheduleService.startDay(mockDay, simulatedTime: time);

      expect(scheduleService.currentSession?.id, 's1');
      expect(scheduleService.timeRemainingInCurrent.inMinutes, 30);
      expect(scheduleService.nextSession?.id, 's2');
      // Next session starts at 11:15, current time is 10:30
      expect(scheduleService.timeUntilNext.inMinutes, 45);
    });

    test('Identifies next session when outside of a session', () {
      // Set time to 9:00 AM (before session 1)
      final time = DateTime(2023, 10, 1, 9, 0);
      scheduleService.startDay(mockDay, simulatedTime: time);

      expect(scheduleService.currentSession, isNull);
      expect(scheduleService.nextSession?.id, 's1');
      expect(scheduleService.timeUntilNext.inMinutes, 60); // 10:00 - 9:00
    });

    test('Handles pause and resume', () {
      final time = DateTime(2023, 10, 1, 10, 30);
      scheduleService.startDay(mockDay, simulatedTime: time);

      expect(scheduleService.isPaused, isFalse);
      
      scheduleService.togglePause();
      expect(scheduleService.isPaused, isTrue);

      scheduleService.togglePause();
      expect(scheduleService.isPaused, isFalse);
    });

    test('advanceTime updates states correctly', () {
      final time = DateTime(2023, 10, 1, 10, 30);
      scheduleService.startDay(mockDay, simulatedTime: time);
      
      expect(scheduleService.currentSession?.id, 's1');

      // Advance by 45 minutes to 11:15 AM
      scheduleService.advanceTime(const Duration(minutes: 45));
      expect(scheduleService.currentSession?.id, 's2');
    });
  });
}

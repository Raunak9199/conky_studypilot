import '../models/study_day.dart';
import '../models/study_session.dart';

class StaticStudyPlan {
  static final List<StudySession> _defaultSessions = [
    const StudySession(
      id: 'dsa',
      title: 'DSA',
      description: 'Data Structures and Algorithms',
      startTime: Duration(hours: 8, minutes: 0),
      duration: Duration(hours: 1, minutes: 30),
    ),
    const StudySession(
      id: 'mobile',
      title: 'Mobile Development',
      description: 'Flutter / Kotlin / Compose / KMP',
      startTime: Duration(hours: 9, minutes: 30),
      duration: Duration(hours: 2, minutes: 0),
    ),
    const StudySession(
      id: 'bank_quant',
      title: 'Bank — Quant + Reasoning',
      description: 'Quantitative Aptitude and Logical Reasoning',
      startTime: Duration(hours: 12, minutes: 0),
      duration: Duration(hours: 3, minutes: 0),
    ),
    const StudySession(
      id: 'bank_english',
      title: 'Bank — English + Computer/GA',
      description: 'English Language and Computer Aptitude / GA',
      startTime: Duration(hours: 15, minutes: 45),
      duration: Duration(hours: 2, minutes: 0),
    ),
    const StudySession(
      id: 'revision',
      title: 'Current Affairs + Revision',
      description: 'Daily Current Affairs and Revision',
      startTime: Duration(hours: 17, minutes: 45),
      duration: Duration(minutes: 45),
    ),
    const StudySession(
      id: 'late_night',
      title: 'Late Night Review (Testing)',
      description: 'Review session to test the app late at night',
      startTime: Duration(hours: 23, minutes: 00),
      duration: Duration(hours: 1, minutes: 30),
    ),
  ];

  static List<StudyDay> get plan30Days {
    return List.generate(30, (index) {
      final dayNumber = index + 1;
      return StudyDay(
        dayNumber: dayNumber,
        sessions: _defaultSessions.map((s) {
          return s.copyWith(
            id: 'day_${dayNumber}_${s.id}',
            // Here you could dynamically change descriptions per day based on a real syllabus
            description: '${s.description} (Day $dayNumber)',
          );
        }).toList(),
      );
    });
  }
}

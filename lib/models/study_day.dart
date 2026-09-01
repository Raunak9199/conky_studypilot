import 'study_session.dart';

class StudyDay {
  final int dayNumber;
  final List<StudySession> sessions;

  const StudyDay({
    required this.dayNumber,
    required this.sessions,
  });

  factory StudyDay.fromJson(Map<String, dynamic> json) {
    var list = json['sessions'] as List;
    List<StudySession> sessionsList =
        list.map((i) => StudySession.fromJson(i)).toList();

    return StudyDay(
      dayNumber: json['dayNumber'] as int,
      sessions: sessionsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dayNumber': dayNumber,
      'sessions': sessions.map((s) => s.toJson()).toList(),
    };
  }
}

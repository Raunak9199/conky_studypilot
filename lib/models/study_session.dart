class StudySession {
  final String id;
  final String title;
  final String description;
  final Duration startTime;
  final Duration duration;

  const StudySession({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.duration,
  });

  factory StudySession.fromJson(Map<String, dynamic> json) {
    return StudySession(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      startTime: Duration(minutes: json['startTimeMinutes'] as int),
      duration: Duration(minutes: json['durationMinutes'] as int),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTimeMinutes': startTime.inMinutes,
      'durationMinutes': duration.inMinutes,
    };
  }

  StudySession copyWith({
    String? id,
    String? title,
    String? description,
    Duration? startTime,
    Duration? duration,
  }) {
    return StudySession(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      duration: duration ?? this.duration,
    );
  }
}

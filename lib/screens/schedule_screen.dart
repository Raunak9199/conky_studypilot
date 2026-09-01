import 'package:flutter/material.dart';

import '../data/study_plan.dart';
import '../models/study_session.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentDay = StaticStudyPlan.plan30Days[0];
    final allDays = StaticStudyPlan.plan30Days;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Schedule'),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Today's Schedule"),
              Tab(text: '30-Day Overview'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTodaySchedule(context, currentDay.sessions),
            _build30DayOverview(context, allDays),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySchedule(
    BuildContext context,
    List<StudySession> sessions,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        // Mocking states for UI (0: completed, 1: now, others: pending)
        IconData icon;
        Color color;
        if (index == 0) {
          icon = Icons.check_circle;
          color = Colors.green;
        } else if (index == 1) {
          icon = Icons.play_circle_fill;
          color = Colors.blue;
        } else {
          icon = Icons.radio_button_unchecked;
          color = Colors.grey;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Icon(icon, color: color, size: 32),
            title: Text(
              session.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(_formatTimeRange(session)),
          ),
        );
      },
    );
  }

  Widget _build30DayOverview(BuildContext context, List<dynamic> days) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        // Mocking states
        IconData icon;
        Color color;
        if (day.dayNumber < 1) {
          // none completed for Day 1 mock
          icon = Icons.check_circle;
          color = Colors.green;
        } else if (day.dayNumber == 1) {
          icon = Icons.play_circle_fill;
          color = Colors.blue;
        } else {
          icon = Icons.radio_button_unchecked;
          color = Colors.grey;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(icon, color: color),
            title: Text(
              'Day ${day.dayNumber}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      },
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

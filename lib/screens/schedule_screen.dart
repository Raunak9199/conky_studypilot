import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../data/study_plan.dart';
import '../models/study_session.dart';
import '../services/schedule_service.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ScheduleService>(
      builder: (context, schedule, child) {
        final currentDay = schedule.currentDay;
        final allDays = StaticStudyPlan.plan30Days;

        if (currentDay == null) {
          return const Scaffold(
            body: Center(child: Text('No active schedule')),
          );
        }

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
                _buildTodaySchedule(context, currentDay.sessions, schedule),
                _build30DayOverview(
                  context,
                  allDays,
                  schedule.currentDay?.dayNumber ?? 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTodaySchedule(
    BuildContext context,
    List<StudySession> sessions,
    ScheduleService schedule,
  ) {
    final now = DateTime.now();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        final isCurrent = schedule.currentSession?.id == session.id;
        final shiftedStart = schedule.getShiftedStartTime(session);
        final isCompleted = !isCurrent && shiftedStart.isBefore(now);

        IconData icon;
        Color color;
        if (isCurrent) {
          icon = Icons.play_circle_fill;
          color = Colors.blue;
        } else if (isCompleted) {
          icon = Icons.check_circle;
          color = Colors.green;
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
            subtitle: Text(
              _formatTimeRange(
                shiftedStart,
                schedule.getShiftedEndTime(session),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _build30DayOverview(
    BuildContext context,
    List<dynamic> days,
    int currentDayNumber,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];

        IconData icon;
        Color color;
        if (day.dayNumber < currentDayNumber) {
          icon = Icons.check_circle;
          color = Colors.green;
        } else if (day.dayNumber == currentDayNumber) {
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

  String _formatTimeRange(DateTime start, DateTime end) {
    return '${_formatTime(start)} – ${_formatTime(end)}';
  }

  String _formatTime(DateTime time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}

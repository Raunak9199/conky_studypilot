import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:provider/provider.dart';

import '../models/study_session.dart';
import '../services/schedule_service.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ScheduleService>(
      builder: (context, schedule, child) {
        final currentDay = schedule.currentDay;
        if (currentDay == null) {
          return const Scaffold(
            body: Center(child: Text('No active schedule')),
          );
        }

        final currentSession = schedule.currentSession;
        final nextSession = schedule.nextSession;
        final isPaused = schedule.isPaused;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Conky StudyPilot'),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'DAY ${currentDay.dayNumber} / ${schedule.studyDays.length}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),
                  if (currentSession != null)
                    _buildNowCard(
                      context,
                      currentSession,
                      schedule.timeRemainingInCurrent,
                      schedule,
                    )
                  else
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text(
                          'No active session right now.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (nextSession != null)
                    _buildNextCard(
                      context,
                      nextSession,
                      schedule.timeUntilNext,
                      schedule,
                    ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      schedule.togglePause();
                    },
                    icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                    label: Text(
                      isPaused ? 'RESUME' : 'PAUSE SCHEDULE',
                      style: const TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: isPaused
                          ? Colors.green
                          : Colors.amber.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNowCard(
    BuildContext context,
    StudySession session,
    Duration timeRemaining,
    ScheduleService schedule,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.play_circle_fill,
                  color: Colors.green,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  'NOW',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              session.title,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _formatTimeRange(
                schedule.getShiftedStartTime(session),
                schedule.getShiftedEndTime(session),
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Text(
              '${timeRemaining.inMinutes} min remaining',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextCard(
    BuildContext context,
    StudySession session,
    Duration startsIn,
    ScheduleService schedule,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.skip_next, color: Colors.blue, size: 28),
                const SizedBox(width: 8),
                Text(
                  'NEXT',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              session.title,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              _formatTimeRange(
                schedule.getShiftedStartTime(session),
                schedule.getShiftedEndTime(session),
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Starts in ${startsIn.inHours > 0 ? '${startsIn.inHours}h ' : ''}${startsIn.inMinutes % 60}m',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
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

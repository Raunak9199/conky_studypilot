// ignore_for_file: dead_code
import 'package:flutter/material.dart';

import '../data/study_plan.dart';
import '../models/study_session.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for Phase 3 UI testing
    final currentDay = StaticStudyPlan.plan30Days[0];
    final currentSession = currentDay.sessions[0];
    final nextSession = currentDay.sessions[1];
    bool isPaused = false;

    return Scaffold(
      appBar: AppBar(title: const Text('Conky StudyPilot'), centerTitle: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'DAY ${currentDay.dayNumber} / 30',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
              const SizedBox(height: 32),
              _buildNowCard(context, currentSession),
              const SizedBox(height: 16),
              _buildNextCard(context, nextSession),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {},
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
  }

  Widget _buildNowCard(BuildContext context, StudySession session) {
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
              _formatTimeRange(session),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            const Text(
              '42 min remaining', // Mocked remaining time
              style: TextStyle(
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

  Widget _buildNextCard(BuildContext context, StudySession session) {
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
              _formatTimeRange(session),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            const Text(
              'Starts in 12 min', // Mocked starts in time
              style: TextStyle(
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

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../data/study_plan.dart';
import '../services/schedule_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ScheduleService>(
      builder: (context, schedule, child) {
        final currentDayNumber = schedule.currentDay?.dayNumber ?? 1;

        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              const ListTile(
                title: Text('Schedule Preferences', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                subtitle: Text('Manage your current study plan'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text('Current Day'),
                subtitle: const Text('Select which day of the plan you are on'),
                trailing: DropdownButton<int>(
                  value: currentDayNumber,
                  items: List.generate(30, (index) {
                    final day = index + 1;
                    return DropdownMenuItem(
                      value: day,
                      child: Text('Day $day'),
                    );
                  }),
                  onChanged: (newDay) {
                    if (newDay != null) {
                      schedule.changeDay(StaticStudyPlan.plan30Days[newDay - 1]);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Changed to Day $newDay')),
                      );
                    }
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.refresh, color: Colors.red),
                title: const Text('Reset Schedule', style: TextStyle(color: Colors.red)),
                subtitle: const Text('Clears all pause offsets and restarts today\'s timeline.'),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Reset Schedule?'),
                      content: const Text('This will clear your pause history for today and snap all sessions back to their original scheduled times. This cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('CANCEL'),
                        ),
                        TextButton(
                          onPressed: () {
                            schedule.resetPauseState();
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Schedule reset!')),
                            );
                          },
                          child: const Text('RESET', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../data/study_plan.dart';
import '../services/schedule_service.dart';
import '../services/sync_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _ipController = TextEditingController();
  final _portController = TextEditingController();
  final _tokenController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final syncService = Provider.of<SyncService>(context, listen: false);
      _ipController.text = syncService.ip;
      _portController.text = syncService.port;
      _tokenController.text = syncService.token;
    });
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  void _saveSyncSettings(SyncService syncService) {
    syncService.saveSettings(
      _ipController.text.trim(),
      _portController.text.trim(),
      _tokenController.text.trim(),
    );
  }

  void _performSync(SyncService syncService, ScheduleService scheduleService) async {
    _saveSyncSettings(syncService);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Syncing with Desktop...')),
    );
    
    final data = await syncService.fetchSyncData();
    if (!mounted) return;
    
    if (data != null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sync successful!'), backgroundColor: Colors.green),
      );
      
      try {
        final newDays = syncService.parseScheduleToStudyDays(data['schedule']);
        final state = data['state'];
        
        DateTime? pauseStartedAt;
        if (state['pauseStartedAt'] != null) {
          pauseStartedAt = DateTime.parse(state['pauseStartedAt']);
        }
        
        scheduleService.syncWithData(
          newDays,
          isPaused: state['isPaused'] ?? false,
          pauseStartedAt: pauseStartedAt,
          totalPauseOffset: Duration(seconds: state['totalPauseSeconds'] ?? 0),
          dayNumber: data['dayNumber'] ?? 1,
        );
      } catch (e) {
        debugPrint("Error applying synced data: \$e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error parsing sync data: \$e'), backgroundColor: Colors.red),
        );
      }
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sync failed. Check connection.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ScheduleService, SyncService>(
      builder: (context, schedule, syncService, child) {
        final currentDayNumber = schedule.currentDay?.dayNumber ?? 1;

        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              const ListTile(
                title: Text('Desktop Sync', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                subtitle: Text('Sync schedule and timers over LAN'),
              ),
              Card(
                elevation: 0,
                color: Colors.grey.shade50,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            syncService.isOnline ? Icons.circle : Icons.circle_outlined,
                            color: syncService.isOnline ? Colors.green : Colors.grey,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            syncService.isOnline ? 'Connected' : 'Desktop offline (Using local schedule)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: syncService.isOnline ? Colors.green : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Last sync: ${syncService.lastSync != null ? DateFormat("HH:mm").format(syncService.lastSync!.toLocal()) : "Never"}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _ipController,
                        decoration: const InputDecoration(
                          labelText: 'Desktop IP Address',
                          hintText: 'e.g. 192.168.1.100',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _portController,
                        decoration: const InputDecoration(
                          labelText: 'Port',
                          hintText: '8080',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _tokenController,
                        decoration: const InputDecoration(
                          labelText: 'Sync Token',
                          hintText: 'Found in sync_config.json',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          OutlinedButton(
                            onPressed: () async {
                              _saveSyncSettings(syncService);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Checking connection...')),
                              );
                              final ok = await syncService.checkStatus();
                              if (mounted) {
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(ok ? 'Connection successful!' : 'Connection failed.'),
                                    backgroundColor: ok ? Colors.green : Colors.red,
                                  ),
                                );
                              }
                            },
                            child: const Text('TEST CONNECTION'),
                          ),
                          ElevatedButton(
                            onPressed: () => _performSync(syncService, schedule),
                            child: const Text('SYNC NOW'),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
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
                      child: Text('Day \$day'),
                    );
                  }),
                  onChanged: (newDay) {
                    if (newDay != null) {
                      // Note: This relies on _plan30Days internally via changeDay but we don't have access to the exact list here.
                      // We will need to update ScheduleService changeDay to just take an integer, or pass the plan.
                      // Wait, changeDay takes a StudyDay. If we're synced, StaticStudyPlan is wrong!
                      // I need to fix this later or let it be for now. 
                      // For now, I'll update schedule_service to take an int instead in another tool call.
                      // To avoid breaking it immediately, I'll leave it but the dropdown might crash if newDay > length.
                      // Actually, let's fix it properly.
                      schedule.changeDayByIndex(newDay - 1);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Changed to Day \$newDay')),
                      );
                    }
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.refresh, color: Colors.red),
                title: const Text('Reset Schedule', style: TextStyle(color: Colors.red)),
                subtitle: const Text("Clears all pause offsets and restarts today's timeline."),
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

# Conky StudyPilot — Flutter Android App Development Plan

## Goal

Build a small, offline-first Android app called **Conky StudyPilot** for the 30-day SDE1 + IBPS/SBI Clerk study plan.

The app should:
- Store the complete 30-day plan locally.
- Show today's timetable and topics.
- Schedule phone notifications/alarms at session start times.
- Play configurable sound and vibration.
- Support Pause / Resume.
- Shift remaining sessions by the exact pause duration.
- Reset the accumulated pause shift at midnight.
- Survive app closure, sleep, and reboot.
- Provide notification/sound/vibration settings and test controls.
- Remain small and offline; no backend for V1.

## Technology

Use **Flutter + Dart + Material 3**, with Android as the primary platform.

Recommended packages:
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_local_notifications:
  timezone:
  shared_preferences:
  intl:
```

Use `flutter_local_notifications` for Android notifications/scheduled alarms. Use Android exact-alarm support where required. Avoid Firebase, ntfy, REST APIs, authentication, or internet dependency in V1.

## Architecture

```text
Flutter UI
    │
    ├── Today
    ├── Schedule
    └── Settings
             │
             ▼
       ScheduleService
             │
       ┌─────┴─────┐
       ▼           ▼
 PauseService   NotificationService
       │           │
       └─────┬─────┘
             ▼
        Local State
             │
             ▼
      Android exact alarm
             │
             ▼
       Sound + Vibration
```

Keep scheduling logic out of UI widgets. The schedule engine must be independently testable.

## Project Structure

```text
lib/
├── main.dart
├── app/
│   ├── app.dart
│   └── theme.dart
├── models/
│   ├── study_day.dart
│   ├── study_session.dart
│   └── schedule_state.dart
├── data/
│   └── study_plan.dart
├── services/
│   ├── notification_service.dart
│   ├── schedule_service.dart
│   ├── pause_service.dart
│   └── storage_service.dart
├── screens/
│   ├── today_screen.dart
│   ├── schedule_screen.dart
│   └── settings_screen.dart
└── widgets/
    ├── session_card.dart
    ├── countdown_card.dart
    ├── pause_button.dart
    └── progress_indicator.dart
```

Avoid unnecessary Bloc/Riverpod/etc. for V1. A lightweight state approach such as `ChangeNotifier`/`ValueNotifier` is sufficient.

## Data Models

### StudySession

```dart
class StudySession {
  final String id;
  final String title;
  final String description;
  final Duration startTime;
  final Duration duration;
}
```

### StudyDay

```dart
class StudyDay {
  final int dayNumber;
  final List<StudySession> sessions;
}
```

Store the complete 30-day plan in `data/study_plan.dart`.

## Default Timetable

| Time | Duration | Focus |
|---|---:|---|
| 08:00 | 1.5 hr | DSA |
| 09:30 | 2 hr | Flutter / Kotlin / Compose / KMP |
| 11:30 | 30 min | Break |
| 12:00 | 3 hr | Bank — Quant + Reasoning |
| 15:00 | 45 min | Lunch / Break |
| 15:45 | 2 hr | Bank — English + Computer Aptitude / GA |
| 17:45 | 30–45 min | Current Affairs + Revision |

Use the complete 30-day topics from the supplied study plan.

## ScheduleService

Create a central `ScheduleService`.

Responsibilities:

```text
Original schedule
      ↓
Current day
      ↓
Pause state
      ↓
Effective schedule
      ↓
Current / next session
      ↓
Alarm timestamps
```

Expose:
- today's sessions
- current session
- next session
- remaining time
- completed sessions
- today's accumulated delay
- pause state

## Pause / Resume

Persist state similar to:

```json
{
  "date": "2026-09-01",
  "isPaused": false,
  "pauseStartedAt": null,
  "totalPauseSeconds": 0
}
```

When paused:
```text
isPaused = true
pauseStartedAt = current timestamp
```

Freeze effective timetable time.

When resumed:
```text
pauseDuration = now - pauseStartedAt
totalPauseSeconds += pauseDuration
isPaused = false
pauseStartedAt = null
```

Shift all remaining sessions by the exact accumulated pause duration. Never move already-completed sessions.

## Multiple Pauses

Example:

```text
Pause #1 = 10 min
Pause #2 = 20 min
Pause #3 = 5 min

Total shift = 35 min
```

All remaining sessions use the accumulated shift.

## Midnight

Reset daily pause state at midnight.

Example:

```text
Day 1 delay = +42 min
        ↓ midnight
Day 2 delay = 0
```

Day 2 starts from its original timetable.

Do not carry yesterday's delay into the next day.

For a pause crossing midnight, finalize/reset the previous day's state and start the new day fresh. Do not carry an overnight pause into the new day.

## Persistence / Sleep / Restart

Pause state must survive:
- app restart
- Flutter process restart
- phone sleep
- phone reboot

Persist timestamps rather than relying on in-memory counters.

Use wall-clock timestamps so sleep/wake does not corrupt elapsed pause duration.

## Notifications

Use `flutter_local_notifications`.

Session-start notifications should exist for:

```text
08:00 DSA
09:30 Mobile Development
12:00 Bank — Quant + Reasoning
15:45 Bank — English + Computer/GA
17:45 Current Affairs + Revision
```

Example:

```text
🔔 STUDY TIME

Mobile Development

Day 1 / 30

Kotlin Core:
null safety, data classes,
sealed classes, scope functions

09:30 – 11:30
```

### Critical notification rule

Never use:

```dart
currentTime == scheduledTime
```

Notifications should be scheduled using calculated Android alarm timestamps.

If any polling fallback is used, trigger when the effective time has **crossed** the scheduled start, not when it exactly equals it.

Maintain deterministic notification IDs/state so each session fires exactly once.

## Pause + Notifications

When pause/resume changes the effective schedule:

```text
Cancel today's pending notifications
        ↓
Recalculate effective schedule
        ↓
Schedule remaining notifications
```

Example:

```text
Original:
09:30 Mobile
12:00 Bank
15:45 English
17:45 Revision

Pause:
09:00 → 09:40

New:
10:10 Mobile
12:40 Bank
16:25 English
18:25 Revision
```

## Scheduling Strategy

Do not schedule all 30 days at once.

Prefer:

```text
App startup
    ↓
Calculate current day
    ↓
Load state
    ↓
Cancel stale alarms
    ↓
Schedule today's remaining sessions
```

At day transition, reset daily state and schedule the new day's sessions.

## Android Permissions

Handle modern Android permissions explicitly:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

The app must:
1. Detect notification permission.
2. Request notification permission where required.
3. Detect exact-alarm permission.
4. Guide the user to grant exact-alarm access.
5. Show permission status in Settings.

Prefer `SCHEDULE_EXACT_ALARM` for V1 rather than assuming exact-alarm permission is already available.

## Reboot

Registered alarms must be rescheduled after reboot.

Expected flow:

```text
BOOT_COMPLETED
    ↓
Load persisted state
    ↓
Calculate today's remaining sessions
    ↓
Cancel stale alarms
    ↓
Schedule remaining alarms
```

Test this explicitly.

## Lifecycle Testing

Test:
- app open
- backgrounded
- swiped away
- phone locked
- phone idle
- phone asleep
- phone rebooted

Normal app closure/backgrounding should not prevent scheduled notifications.

## Notification Settings

Provide:

```text
Notifications          ON/OFF
Sound                  Default / Study Bell / Soft Bell / Silent
Vibration              Off / Normal / Strong
Priority               Normal / High / Urgent
Exact Alarms           Allowed / Not Allowed
```

Use Android notification channels appropriately.

## Custom Sound

Optionally include:

```text
android/app/src/main/res/raw/study_bell.mp3
```

Do not prevent the user from controlling notification sound through Android settings.

## Today Screen

Target design:

```text
┌───────────────────────────────┐
│          Conky STUDYPILOT           │
│          DAY 1 / 30           │
│                               │
│  🟢 NOW                       │
│  DSA                          │
│  08:00 – 09:30                │
│  42 min remaining             │
│                               │
│  NEXT                         │
│  Mobile Development           │
│  09:30 – 11:30                │
│  Starts in 12 min             │
│                               │
│        [ ⏸ PAUSE ]            │
└───────────────────────────────┘
```

Paused state:

```text
┌───────────────────────────────┐
│       ⏸ SCHEDULE PAUSED       │
│                               │
│  Paused: 18:32                │
│  Today's delay: +18:32        │
│                               │
│        [ ▶ RESUME ]            │
└───────────────────────────────┘
```

After resume:

```text
▶ RUNNING
Today's delay: +18:32
```

## Schedule Screen

Today's schedule:

```text
08:00  ✓ DSA
09:30  ▶ Mobile Development
12:00  ○ Quant + Reasoning
15:45  ○ English + Computer
17:45  ○ Current Affairs
```

30-day overview:

```text
✓ Day 1
✓ Day 2
▶ Day 3
○ Day 4
...
○ Day 30
```

## Settings Screen

Keep it simple:

```text
Notifications                 ON
Sound                         Study Bell
Vibration                     Strong
Exact alarms                  ✓ Allowed
Notification permission       ✓ Allowed

Test notification             [ TEST ]
Test vibration                [ TEST ]

Reset today's schedule        [ RESET ]

About
```

## Developer/Test Mode

Provide:

```text
Test notification in:
[ 10 seconds ]
[ 30 seconds ]
[ 1 minute ]
[ 5 minutes ]

[ TEST VIBRATION ]
```

The test notification must exercise the real notification path, including sound and vibration.

## Testing Matrix

### Notification
Schedule a test alarm, lock the phone, wait, and verify notification + sound + vibration.

### Pause
If a session is 10:00–11:00 and pause occurs at 10:10 for 10 minutes, it must resume with 50 minutes remaining.

### Multiple Pause
Pause 10 min + pause 20 min = 30 min total shift.

### Reboot
Schedule an alarm, reboot, verify it is rescheduled.

### Midnight
Use a developer date/time override. Verify yesterday's delay is discarded and the new day starts at zero delay.

### Lifecycle
Verify behavior when app is open, backgrounded, swiped away, locked, asleep, and rebooted.

## Day 30

After completion:

```text
🎉 PLAN COMPLETE

30 / 30 DAYS COMPLETED
```

Do not automatically start a new cycle.

## Dependencies

Start with only:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_local_notifications:
  timezone:
  shared_preferences:
  intl:
```

Do not add unnecessary packages.

## Storage

Persist:
- plan start date
- current day
- pause state
- pause start timestamp
- accumulated pause duration
- notification scheduling state
- user notification preferences

The built-in 30-day schedule can remain static Dart data.

## No Backend

V1 must not require:
- Firebase
- ntfy
- REST API
- WebSocket
- cloud database
- user account
- internet

The app must work completely offline.

## Ubuntu Integration

Do not make Ubuntu the master scheduler.

```text
                 30-Day Study Plan
                        │
              ┌─────────┴─────────┐
              ▼                   ▼
        Ubuntu Conky          Android App
        Desktop HUD           Alarm Scheduler
        Countdown             Sound
        Visual display        Vibration
                              Notifications
```

The Android app must work independently even when Ubuntu is powered off.

## Development Phases

### Phase 1 — Flutter Project + UI Skeleton
Build:
- project
- Material 3 theme
- navigation
- Today screen
- Schedule screen
- Settings screen

No alarms yet.

### Phase 2 — Study Plan Data
Implement:
- `StudyDay`
- `StudySession`
- full 30-day data
- current-day calculation

Verify Day 1 → Day 30.

### Phase 3 — Schedule UI
Implement:
- current session
- next session
- countdown
- completed sessions
- progress
- 30-day overview

### Phase 4 — Notification Service
Implement:
- initialization
- notification channel
- test notification
- sound
- vibration
- notification permissions

First make one notification work reliably.

### Phase 5 — Exact Android Alarms
Implement:
- timezone handling
- scheduled notifications
- exact-alarm permission
- permission status
- test alarms

Verify with app closed and screen locked.

### Phase 6 — Schedule Engine
Implement and unit-test:
```text
Original schedule
       ↓
Current time
       ↓
Current day
       ↓
Effective schedule
```

### Phase 7 — Pause / Resume
Implement:
- persistent state
- pause timestamp
- resume timestamp
- accumulated shift
- multiple pauses
- frozen effective time
- notification rescheduling

### Phase 8 — Persistence + Reboot
Implement:
- state persistence
- boot rescheduling
- stale alarm cancellation
- startup synchronization

### Phase 9 — Settings + Polish
Implement:
- sound
- vibration
- priority
- exact-alarm status
- test notification
- test vibration
- reset today's schedule

### Phase 10 — Final Testing + APK

Run:

```bash
flutter analyze
flutter test
flutter build apk --release
```

Install the release APK and perform real-world tests.

## Important Implementation Rules

1. Do not implement the whole application in one giant response.
2. Build in phases.
3. Compile/analyze after each major phase.
4. Keep scheduling logic out of UI widgets.
5. Never use exact timestamp equality for notification triggering.
6. Persist timestamps; do not rely on in-memory timers.
7. Handle timezone correctly.
8. Handle midnight explicitly.
9. Reschedule alarms after pause/resume.
10. Reschedule alarms after reboot.
11. Do not schedule notifications for past sessions.
12. Cancel stale notifications before scheduling updated ones.
13. Give each session a deterministic notification ID.
14. Prevent duplicate notifications.
15. Handle missing/corrupt local state safely.
16. Avoid unnecessary dependencies.
17. Keep V1 completely offline.
18. Make the scheduling engine independently testable.
19. Add automated tests for pause/resume and midnight behavior.
20. Use wall-clock timestamps for persisted time calculations.

## Unit Tests

At minimum:

```text
calculateDayNumber()
getCurrentSession()
getNextSession()

pause()
resume()

singlePauseShift()
multiplePauseShift()

pauseDuringSession()
pauseBetweenSessions()

pauseCrossingMidnight()
newDayResetsShift()

scheduleRemainingSessions()
cancelAndReschedule()

notificationIdIsStable()
duplicateNotificationIsPrevented()
```

Use fake timestamps rather than waiting in real time.

## Final User Experience

Morning:

```text
Conky STUDYPILOT
DAY 7 / 30

▶ NOW
DSA

⏭ NEXT
Mobile Development

[ ⏸ PAUSE ]
```

At session start:

```text
🔔 STUDY TIME

DSA

Day 7 / 30

Weekly mock:
25 mixed easy problems

08:00 – 09:30
```

During emergency:

```text
⏸ PAUSED
Paused: 08:32
Today's delay: +08:32
```

Resume:

```text
▶ RESUME
```

Remaining schedule shifts automatically.

At midnight:

```text
DAY 8 / 30
Today's delay: +00:00
```

## Initial AI Coding Prompt

> Build a Flutter Android app called **Conky StudyPilot** based on this specification.
>
> Use Flutter/Dart + Material 3. The app is a small offline-first 30-day study scheduler for an SDE1 + IBPS/SBI Clerk preparation plan.
>
> Use `flutter_local_notifications`, `timezone`, `shared_preferences`, and `intl` as the initial dependencies.
>
> Do not add Firebase, a backend, ntfy, REST APIs, authentication, or an internet dependency.
>
> Build incrementally:
> 1. UI skeleton
> 2. study-plan data
> 3. schedule UI
> 4. notification service
> 5. exact Android alarms and permissions
> 6. schedule engine
> 7. pause/resume
> 8. persistence/reboot handling
> 9. settings/polish
> 10. testing/release APK
>
> Before each phase, briefly explain the design.
>
> After each phase:
> - run/analyze the project
> - fix compilation/analyzer errors
> - add appropriate tests
> - only then continue
>
> Do not dump the entire app in one response.
>
> Pay particular attention to:
> - exact alarms
> - notification sound/vibration
> - pause/resume
> - accumulated daily pause offset
> - midnight reset
> - multiple pauses
> - reboot rescheduling
> - app lifecycle
> - duplicate prevention
> - persistent timestamps
> - timezone handling
> - developer test alarms
>
> The scheduling engine must be independent of the UI and unit-testable.
>
> Never use exact timestamp equality to trigger notifications.
>
> Start with **Phase 1 only** and wait for verification before proceeding.

## Success Criteria

```text
✓ 30-day plan loads
✓ Correct current day
✓ Correct current session
✓ Correct next session
✓ Countdown works
✓ Notifications fire at scheduled times
✓ Sound works
✓ Vibration works
✓ Exact-alarm permission handled
✓ App can be closed
✓ Phone can be locked
✓ Phone can sleep
✓ Phone can reboot
✓ Alarms reschedule after reboot
✓ Pause freezes schedule
✓ Resume shifts remaining sessions
✓ Multiple pauses accumulate
✓ Already-completed sessions don't move
✓ Notifications shift after pause
✓ Midnight resets daily shift
✓ Overnight pause doesn't corrupt next day
✓ Test notification works
✓ Test vibration works
✓ Settings work
✓ No backend required
✓ Offline operation works
✓ Unit tests pass
✓ flutter analyze passes
✓ Release APK builds
```

## Final Recommendation

Use **Flutter for V1**.

Move to Jetpack Compose/Kotlin/KMP only if Android-specific limitations make the Flutter implementation unreliable after real-world testing.

The app should remain small, offline-first, and focused on reliable study scheduling rather than becoming a general productivity application.

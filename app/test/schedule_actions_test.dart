import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gogo/models.dart';
import 'package:gogo/screens/all_schedules_screen.dart';
import 'package:gogo/screens/pending_schedules_screen.dart';
import 'package:gogo/theme.dart';

ScheduleEntry _entry(int id, {bool fired = false}) => ScheduleEntry(
      id: id,
      fireAt: fired ? 1000 : DateTime.now().millisecondsSinceEpoch ~/ 1000 + 100000,
      state: 'on',
      mode: 'cool',
      fan: 'low',
      setTemp: 22,
      zones: null,
      firedAt: fired ? 1000 : null,
    );

// The schedule screens poll on a 10s timer, so pumpAndSettle never quiesces.
// Use a fixed-duration pump everywhere instead.
const _pump = Duration(milliseconds: 100);

void main() {
  testWidgets('pending schedule play opens a confirmation dialog and triggers on confirm',
      (tester) async {
    var triggeredId = -1;
    await tester.pumpWidget(MaterialApp(
      theme: buildDarkTheme(),
      home: PendingSchedulesScreen(
        getSchedules: () async => [_entry(1)],
        getZoneNames: () async => {},
        triggerSchedule: (id) async => triggeredId = id,
        deleteSchedule: (_) async {},
      ),
    ));
    await tester.pump(_pump);

    expect(find.byKey(const Key('schedule-item-0-trigger')), findsOneWidget);
    await tester.tap(find.byKey(const Key('schedule-item-0-trigger')));
    await tester.pump(_pump);

    expect(find.text('Run schedule now?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('schedule-confirm-ok')));
    await tester.pump(_pump);

    expect(triggeredId, 1);
  });

  testWidgets('pending schedule delete opens a confirmation dialog', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildDarkTheme(),
      home: PendingSchedulesScreen(
        getSchedules: () async => [_entry(2)],
        getZoneNames: () async => {},
        triggerSchedule: (_) async {},
        deleteSchedule: (_) async {},
      ),
    ));
    await tester.pump(_pump);

    await tester.tap(find.byKey(const Key('schedule-item-0-delete')));
    await tester.pump(_pump);

    expect(find.text('Delete schedule?'), findsOneWidget);
    expect(find.byKey(const Key('schedule-confirm-cancel')), findsOneWidget);
  });

  testWidgets('all schedules play opens confirmation for a pending entry', (tester) async {
    var triggeredId = -1;
    await tester.pumpWidget(MaterialApp(
      theme: buildDarkTheme(),
      home: AllSchedulesScreen(
        getSchedules: () async => [_entry(3)],
        getZoneNames: () async => {},
        triggerSchedule: (id) async => triggeredId = id,
        deleteSchedule: (_) async {},
      ),
    ));
    await tester.pump(_pump);

    expect(find.byKey(const Key('all-schedule-item-0-trigger')), findsOneWidget);
    await tester.tap(find.byKey(const Key('all-schedule-item-0-trigger')));
    await tester.pump(_pump);

    expect(find.text('Run schedule now?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('all-schedule-confirm-ok')));
    await tester.pump(_pump);

    expect(triggeredId, 3);
  });

  testWidgets('all schedules shows no play button for a fired entry', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildDarkTheme(),
      home: AllSchedulesScreen(
        getSchedules: () async => [_entry(4, fired: true)],
        getZoneNames: () async => {},
        triggerSchedule: (_) async {},
        deleteSchedule: (_) async {},
      ),
    ));
    await tester.pump(_pump);

    expect(find.byKey(const Key('all-schedule-item-0-trigger')), findsNothing);
    expect(find.byKey(const Key('all-schedule-item-0-delete')), findsNothing);
  });
}

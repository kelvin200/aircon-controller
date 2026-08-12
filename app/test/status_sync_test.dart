import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gogo/models.dart';
import 'package:gogo/screens/status_screen.dart';
import 'package:gogo/theme.dart';

SystemStatus _status(String state) => SystemStatus(
      state: state,
      mode: 'cool',
      fan: 'high',
      setTemp: 22,
      zones: {
        'z01': ZoneInfo(
            name: 'Zone 1', state: 'open', setTemp: 20, measuredTemp: 21, value: 40),
      },
    );

Widget _harness({
  required Future<SystemStatus> Function() getStatus,
  required Future<void> Function(Map<String, dynamic> body) postSystem,
  Future<void> Function(Map<String, dynamic> body)? postSchedule,
}) {
  return MaterialApp(
    theme: buildDarkTheme(),
    home: Scaffold(
      body: StatusScreen(
        getStatus: getStatus,
        postSystem: postSystem,
        postSchedule: postSchedule,
      ),
    ),
  );
}

bool _switchOn(WidgetTester tester) =>
    tester.widget<Switch>(find.byKey(const Key('power-switch'))).value;

void main() {
  testWidgets('stale poll during power-on does not flash back to off', (tester) async {
    var serverState = 'off';
    var readStale = false; // simulate AC propagation delay on the read path
    await tester.pumpWidget(_harness(
      getStatus: () async => _status(readStale ? 'off' : serverState),
      postSystem: (body) async {
        if (body['state'] == 'on') serverState = 'on';
      },
    ));
    await tester.pump();
    expect(_switchOn(tester), isFalse);

    // User turns the system on.
    await tester.tap(find.byKey(const Key('power-switch')));
    await tester.pump();
    expect(_switchOn(tester), isTrue); // optimistic ON
    expect(find.text('ON'), findsWidgets);

    // The power command has already succeeded, but the AC unit still reports
    // its previous state while the change propagates. A poll now returns OFF.
    readStale = true;
    await tester.pump(const Duration(seconds: 11));
    await tester.pump();

    // The stale read must be held back — the UI keeps showing ON.
    expect(_switchOn(tester), isTrue);
    expect(find.text('OFF'), findsNothing);

    // Once the unit reports ON, the poll confirms and applies it.
    readStale = false;
    await tester.pump(const Duration(seconds: 11));
    await tester.pump();
    expect(_switchOn(tester), isTrue);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('schedule failure after a successful power-on does not revert', (tester) async {
    var serverState = 'off';
    var scheduleFails = true;
    await tester.pumpWidget(_harness(
      getStatus: () async => _status(serverState),
      postSystem: (body) async {
        if (body['state'] == 'on') serverState = 'on';
      },
      postSchedule: (_) async {
        if (scheduleFails) throw Exception('db locked');
      },
    ));
    await tester.pump();
    expect(_switchOn(tester), isFalse);

    await tester.tap(find.byKey(const Key('power-switch')));
    await tester.pump();
    await tester.pump();

    // Power command succeeded; follow-up schedule creation failed. The UI
    // must still show ON and surface a notice, not revert to OFF.
    expect(_switchOn(tester), isTrue);
    expect(find.text('Could not create follow-up schedules'), findsOneWidget);
    expect(find.text('OFF'), findsNothing);

    // Let the snackbar's dismiss timer run out and dispose the tree.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('power command failure reverts to the previous state', (tester) async {
    var postFails = true;
    await tester.pumpWidget(_harness(
      getStatus: () async => _status('off'),
      postSystem: (_) async {
        if (postFails) throw Exception('network');
      },
    ));
    await tester.pump();
    expect(_switchOn(tester), isFalse);

    await tester.tap(find.byKey(const Key('power-switch')));
    await tester.pump();
    await tester.pump(); // let the failing command resolve and revert

    expect(_switchOn(tester), isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('out-of-order status responses do not overwrite newer state', (tester) async {
    final responses = <Completer<SystemStatus>>[];
    await tester.pumpWidget(MaterialApp(
      theme: buildDarkTheme(),
      home: Scaffold(
        body: StatusScreen(
          getStatus: () {
            final c = Completer<SystemStatus>();
            responses.add(c);
            return c.future;
          },
          postSystem: (_) async {},
          postSchedule: (_) async {},
        ),
      ),
    ));

    // Initial load → OFF.
    expect(responses, hasLength(1));
    responses[0].complete(_status('off'));
    await tester.pump();
    expect(_switchOn(tester), isFalse);

    // Fire two poll ticks so multiple reads are in flight.
    await tester.pump(const Duration(seconds: 11));
    await tester.pump(const Duration(seconds: 11));
    expect(responses.length, greaterThanOrEqualTo(3));

    // The older in-flight reads report ON, but resolve AFTER the newest read
    // (which reports OFF). Only the newest response may be applied.
    for (final older in responses.skip(1).take(responses.length - 2)) {
      older.complete(_status('on'));
    }
    responses.last.complete(_status('off'));
    await tester.pump();

    expect(_switchOn(tester), isFalse); // newest (OFF) won, stale ON dropped
    await tester.pumpWidget(const SizedBox());
  });
}

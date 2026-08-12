import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gogo/models.dart';
import 'package:gogo/theme.dart';
import 'package:gogo/widgets/zone_grid.dart';

const _names = ['Zone 1','Zone 2','Zone 3','Zone 4','Zone 5','Zone 6','Zone 7','Zone 8','Zone 9'];

SystemStatus _fullStatus({String systemState = 'on'}) {
  final zones = <String, ZoneInfo>{};
  for (var i = 0; i < 9; i++) {
    final id = zoneIds[i];
    zones[id] = ZoneInfo(
      name: _names[i],
      state: i.isEven ? 'open' : 'close',
      setTemp: 21,
      measuredTemp: 20,
      value: 40 + i * 5,
    );
  }
  return SystemStatus(state: systemState, mode: 'cool', fan: 'high', setTemp: 22, zones: zones);
}

Widget _harness(SystemStatus status, {required bool isOn, required void Function(String) onToggle, required void Function(String, int) onValue}) {
  return MaterialApp(
    theme: buildDarkTheme(),
    home: Scaffold(
      body: SingleChildScrollView(
        child: ZoneGrid(status: status, isOn: isOn, onToggle: onToggle, onValue: onValue),
      ),
    ),
  );
}

void main() {
  testWidgets('grid renders nine cells with name and value', (tester) async {
    await tester.pumpWidget(_harness(_fullStatus(), isOn: true, onToggle: (_) {}, onValue: (_, __) {}));

    expect(find.byKey(const Key('zone-grid')), findsOneWidget);
    for (var i = 0; i < 9; i++) {
      expect(find.byKey(Key('zone-cell-$i')), findsOneWidget);
      expect(find.byKey(Key('zone-cell-$i-name')), findsOneWidget);
      expect(find.byKey(Key('zone-cell-$i-value')), findsOneWidget);
    }
    // Spot-check a name and a value number.
    expect(find.text('Zone 1'), findsOneWidget);
    expect(find.text('40'), findsOneWidget);
  });

  testWidgets('tapping a cell toggles and long-press reveals the slider sheet', (tester) async {
    final toggles = <String>[];
    final values = <String, int>{};
    await tester.pumpWidget(_harness(
      _fullStatus(),
      isOn: true,
      onToggle: (id) => toggles.add(id),
      onValue: (id, v) => values[id] = v,
    ));

    // Tap cell 0 (z01, open) → toggle handler.
    await tester.tap(find.byKey(const Key('zone-cell-0')));
    expect(toggles, ['z01']);

    // Long-press cell 1 (z02) → slider sheet appears.
    await tester.longPress(find.byKey(const Key('zone-cell-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('zone-cell-1-slider')), findsOneWidget);

    // Commit a new value via the slider → value handler + sheet closes.
    final slider = tester.widget<Slider>(find.byKey(const Key('zone-cell-1-slider')));
    slider.onChangeEnd!(55);
    await tester.pumpAndSettle();
    expect(values['z02'], 55);
    expect(find.byKey(const Key('zone-cell-1-slider')), findsNothing);
  });

  testWidgets('grid stays interactive when the system is off', (tester) async {
    final toggles = <String>[];
    final values = <String, int>{};
    await tester.pumpWidget(_harness(
      _fullStatus(systemState: 'off'),
      isOn: false,
      onToggle: (id) => toggles.add(id),
      onValue: (id, v) => values[id] = v,
    ));

    // Tapping an open cell still fires the toggle handler while off.
    await tester.tap(find.byKey(const Key('zone-cell-0')));
    expect(toggles, ['z01']);

    // Long-press still reveals the slider sheet while off.
    await tester.longPress(find.byKey(const Key('zone-cell-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('zone-cell-1-slider')), findsOneWidget);

    final slider = tester.widget<Slider>(find.byKey(const Key('zone-cell-1-slider')));
    slider.onChangeEnd!(55);
    await tester.pumpAndSettle();
    expect(values['z02'], 55);
  });
}

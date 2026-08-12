import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gogo/main.dart';
import 'package:gogo/models.dart';
import 'package:gogo/theme.dart';
import 'package:gogo/widgets/cards/mode_fan_card.dart';
import 'package:gogo/widgets/cards/power_card.dart';
import 'package:gogo/widgets/cards/temperature_card.dart';
import 'package:gogo/widgets/zone_grid.dart';
import 'package:gogo/widgets/status_pill.dart';

SystemStatus _fakeStatus() => SystemStatus(
      state: 'on',
      mode: 'cool',
      fan: 'high',
      setTemp: 22,
      zones: {
        'z01': ZoneInfo(
            name: 'Zone 1', state: 'open', setTemp: 20, measuredTemp: 21, value: 40),
      },
    );

void main() {
  testWidgets('app renders with dark theme, header and navigation', (tester) async {
    await tester.pumpWidget(const GoGoApp());
    await tester.pump(const Duration(milliseconds: 50));

    // Header identity and live status pill.
    expect(find.text('Kel Aircon'), findsOneWidget);
    expect(find.byType(StatusPill), findsWidgets);

    // Bottom navigation with the four destinations.
    final nav = tester.widget<NavigationBar>(find.byKey(const Key('bottom-nav')));
    expect(nav.selectedIndex, 0);
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Zones'), findsOneWidget);
    expect(find.text('Schedules'), findsOneWidget);
    expect(find.text('Errors'), findsOneWidget);

    // Dark theme is applied.
    final ctx = tester.element(find.text('Kel Aircon'));
    expect(Theme.of(ctx).brightness, Brightness.dark);
    expect(AppColors.of(ctx).canvas, AppColors.dark.canvas);

    // Navigation switches destination.
    await tester.tap(find.text('Zones'));
    await tester.pump(const Duration(milliseconds: 50));
    final nav2 = tester.widget<NavigationBar>(find.byKey(const Key('bottom-nav')));
    expect(nav2.selectedIndex, 1);

    // Dispose the tree so polling timers are cancelled.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('status screen cards render with keys and dark theme', (tester) async {
    final status = _fakeStatus();
    await tester.pumpWidget(MaterialApp(
      theme: buildDarkTheme(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              PowerCard(isOn: true, onToggle: () {}),
              TemperatureCard(
                status: status,
                tempColor: Colors.blue,
                onChanged: (_) {},
                onChangeEnd: (_) {},
              ),
              ModeFanCard(status: status, isOn: true, onMode: (_) {}, onFan: (_) {}),
              ZoneGrid(
                status: status,
                isOn: true,
                onToggle: (_) {},
                onValue: (_, __) {},
              ),
            ],
          ),
        ),
      ),
    ));

    // Power card.
    expect(find.byKey(const Key('power-switch')), findsOneWidget);
    // Temperature card.
    expect(find.byKey(const Key('set-temp')), findsOneWidget);
    expect(find.byKey(const Key('status-temp-slider')), findsOneWidget);
    // Mode & fan card.
    expect(find.byKey(const Key('mode-segmented')), findsOneWidget);
    expect(find.byKey(const Key('fan-segmented')), findsOneWidget);
    // Zones card (grid renders the one provided zone; missing zones are skipped).
    expect(find.byKey(const Key('zone-grid')), findsOneWidget);
    expect(find.byKey(const Key('zone-cell-0')), findsOneWidget);

    final ctx = tester.element(find.byKey(const Key('power-switch')));
    expect(Theme.of(ctx).brightness, Brightness.dark);
    expect(AppColors.of(ctx).surface, AppColors.dark.surface);
  });

  testWidgets('status pill renders an uppercased label with a dot', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildDarkTheme(),
      home: Scaffold(body: StatusPill(label: 'On', colour: AppColors.dark.green)),
    ));
    expect(find.text('ON'), findsOneWidget);
  });
}

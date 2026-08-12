import 'package:flutter_test/flutter_test.dart';
import 'package:gogo/api.dart';
import 'package:gogo/models.dart';
import 'package:gogo/screens/add_schedule_sheet.dart';

void main() {
  test('projects the effective status from earlier pending schedules', () {
    final current = SystemStatus(
      state: 'on',
      mode: 'cool',
      fan: 'high',
      setTemp: 22,
      zones: {
        'z01': ZoneInfo(
            name: 'Zone 1',
            state: 'open',
            setTemp: 20,
            measuredTemp: 21,
            value: 40),
      },
    );

    final pending = [
      ScheduleEntry(
        id: 1,
        fireAt: DateTime(2026, 7, 8, 9, 0).millisecondsSinceEpoch ~/ 1000,
        state: 'off',
        fan: 'medium',
        setTemp: 21,
        zones: {
          'z01': ZoneChange(state: 'close', value: 80),
        },
      ),
      ScheduleEntry(
        id: 2,
        fireAt: DateTime(2026, 7, 8, 10, 0).millisecondsSinceEpoch ~/ 1000,
        fan: 'low',
      ),
    ];

    final before = buildProjectedStatus(
      currentStatus: current,
      pendingSchedules: pending,
      targetTime: DateTime(2026, 7, 8, 8, 50),
    );
    expect(before.state, 'on');
    expect(before.fan, 'high');
    expect(before.zones['z01']!.state, 'open');

    final after = buildProjectedStatus(
      currentStatus: current,
      pendingSchedules: pending,
      targetTime: DateTime(2026, 7, 8, 9, 10),
    );
    expect(after.state, 'off');
    expect(after.fan, 'medium');
    expect(after.setTemp, 21);
    expect(after.zones['z01']!.state, 'close');
    expect(after.zones['z01']!.value, 80);
  });

  test('buildAutoFollowUpSchedules creates fan-low and turn-off entries', () {
    final baseTime = DateTime(2026, 7, 17, 12, 0);

    final schedules = buildAutoFollowUpSchedules(baseTime);

    expect(schedules, hasLength(2));
    expect(schedules[0]['fan'], 'low');
    expect(schedules[0]['fireAt'], baseTime.add(const Duration(minutes: 30)).millisecondsSinceEpoch ~/ 1000);
    expect(schedules[1]['state'], 'off');
    expect(schedules[1]['fireAt'], baseTime.add(const Duration(hours: 2)).millisecondsSinceEpoch ~/ 1000);
  });
}

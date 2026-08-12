import 'package:flutter/material.dart';
import 'screens/status_screen.dart';
import 'screens/zones_page.dart';
import 'screens/pending_schedules_screen.dart';
import 'screens/error_log_screen.dart';
import 'theme.dart';
import 'widgets/grid_canvas.dart';
import 'widgets/status_pill.dart';

void main() {
  runApp(const GoGoApp());
}

class GoGoApp extends StatelessWidget {
  const GoGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kel Aircon',
      debugShowCheckedModeBanner: false,
      theme: buildDarkTheme(),
      // Grid canvas sits behind the whole navigator so it shows through
      // every screen and pushed route.
      builder: (context, child) => Stack(
        children: [
          const Positioned.fill(child: GridCanvas()),
          if (child != null) child,
        ],
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;
  String? _systemState;

  void _onStatus(String? state) {
    if (state != _systemState) {
      setState(() { _systemState = state; });
    }
  }

  Widget _screen() {
    switch (_index) {
      case 0:
        return StatusScreen(onStatus: _onStatus);
      case 1:
        return ZonesPage(onStatus: _onStatus);
      case 2:
        return const PendingSchedulesScreen();
      default:
        return const ErrorLogScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            _Header(state: _systemState),
            Expanded(child: _screen()),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.hairline)),
        ),
        child: NavigationBar(
          key: const Key('bottom-nav'),
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() { _index = i; }),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.ac_unit_outlined), selectedIcon: Icon(Icons.ac_unit), label: 'Status'),
            NavigationDestination(icon: Icon(Icons.view_module_outlined), selectedIcon: Icon(Icons.view_module), label: 'Zones'),
            NavigationDestination(icon: Icon(Icons.schedule_outlined), selectedIcon: Icon(Icons.schedule), label: 'Schedules'),
            NavigationDestination(icon: Icon(Icons.error_outline), selectedIcon: Icon(Icons.error), label: 'Errors'),
          ],
        ),
      ),
    );
  }
}

/// Slim app header: identity on the left, live system status pill on the right.
class _Header extends StatelessWidget {
  final String? state;

  const _Header({required this.state});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isOn = state == 'on';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.hairline)),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: c.coral,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.ac_unit, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Text(
            'Kel Aircon',
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          StatusPill(
            label: isOn ? 'On' : state == 'off' ? 'Off' : '—',
            colour: isOn ? c.green : c.textMuted,
          ),
        ],
      ),
    );
  }
}

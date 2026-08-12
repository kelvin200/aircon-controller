import 'package:flutter/material.dart';

class TopProgressBar extends StatefulWidget {
  final VoidCallback onComplete;
  const TopProgressBar({super.key, required this.onComplete});

  @override
  State<TopProgressBar> createState() => _TopProgressBarState();
}

class _TopProgressBarState extends State<TopProgressBar> with SingleTickerProviderStateMixin {
  late final AnimationController _ctr;

  @override
  void initState() {
    super.initState();
    _ctr = AnimationController(vsync: this, duration: const Duration(seconds: 10))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete();
          _ctr.forward(from: 0);
        }
      });
    _ctr.forward();
  }

  @override
  void dispose() {
    _ctr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 4,
      child: AnimatedBuilder(
        animation: _ctr,
        builder: (ctx, ch) => LinearProgressIndicator(
          value: _ctr.value,
          backgroundColor: Colors.transparent,
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFADD8FF)), // light blue
          minHeight: 4,
        ),
      ),
    );
  }
}

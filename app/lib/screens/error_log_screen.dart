import 'dart:async';
import 'package:flutter/material.dart';
import '../api.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/panel.dart';
import '../widgets/top_progress_bar.dart';

class ErrorLogScreen extends StatefulWidget {
  const ErrorLogScreen({super.key});

  @override
  State<ErrorLogScreen> createState() => _ErrorLogScreenState();
}

class _ErrorLogScreenState extends State<ErrorLogScreen> {
  List<AppError> _errors = [];
  String? _loadError;
  Timer? _pollTimer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _load());
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; });
    try {
      final errs = await getErrors();
      if (mounted) setState(() { _errors = errs; _loadError = null; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _loadError = e.toString(); _isLoading = false; });
    }
  }

  String _formatTime(int unixSec) {
    final dt = DateTime.fromMillisecondsSinceEpoch(unixSec * 1000);
    return dt.toString().substring(0, 19);
  }

  Color _sourceColour(String source) {
    switch (source) {
      case 'scheduler': return AppColors.dark.orange;
      case 'ezoneClient': return AppColors.dark.coral;
      default: return AppColors.dark.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadError != null) {
      return Column(
        children: [
          TopProgressBar(onComplete: _load),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Error: $_loadError'),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (_errors.isEmpty) {
      return Column(
        children: [
          TopProgressBar(onComplete: _load),
          const Expanded(
            child: Center(
              child: Text('No errors recorded', key: Key('error-log-empty')),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        TopProgressBar(onComplete: _load),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _errors.length,
            itemBuilder: (ctx, i) {
              final e = _errors[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Panel(
                  key: Key('error-item-$i'),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            key: Key('error-item-$i-source'),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _sourceColour(e.source).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: _sourceColour(e.source).withValues(alpha: 0.55)),
                            ),
                            child: Text(
                              e.source,
                              style: TextStyle(color: _sourceColour(e.source), fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatTime(e.occurredAt),
                            key: Key('error-item-$i-time'),
                            style: monoStyle(context, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        e.message,
                        key: Key('error-item-$i-message'),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

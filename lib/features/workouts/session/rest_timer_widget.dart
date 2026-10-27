import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RestTimerWidget extends StatefulWidget {
  const RestTimerWidget({
    super.key,
    required this.initialSeconds,
    required this.onComplete,
    required this.onSkip,
    this.nextExerciseName,
    this.nextSetNumber,
  });

  final int initialSeconds;
  final VoidCallback onComplete;
  final VoidCallback onSkip;
  final String? nextExerciseName;
  final int? nextSetNumber;

  @override
  State<RestTimerWidget> createState() => _RestTimerWidgetState();
}

class _RestTimerWidgetState extends State<RestTimerWidget>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late int _totalSeconds;
  late int _remainingSeconds;
  DateTime? _targetEndTime;
  Timer? _timer;
  bool _isRunning = true;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _totalSeconds = widget.initialSeconds;
    _remainingSeconds = widget.initialSeconds;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _startTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _isRunning &&
        _targetEndTime != null) {
      final remaining = _targetEndTime!.difference(DateTime.now()).inSeconds;
      if (remaining <= 0) {
        _timer?.cancel();
        setState(() {
          _remainingSeconds = 0;
          _isRunning = false;
        });
        HapticFeedback.heavyImpact();
        widget.onComplete();
      } else {
        setState(() {
          _remainingSeconds = remaining;
        });
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _targetEndTime = DateTime.now().add(Duration(seconds: _remainingSeconds));
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds > 1) {
        setState(() {
          _remainingSeconds--;
        });
        if (_remainingSeconds <= 3) {
          HapticFeedback.lightImpact();
        }
      } else {
        _timer?.cancel();
        setState(() {
          _remainingSeconds = 0;
          _isRunning = false;
        });
        HapticFeedback.heavyImpact();
        widget.onComplete();
      }
    });
  }

  void _togglePause() {
    setState(() {
      if (_isRunning) {
        _timer?.cancel();
        _isRunning = false;
        _targetEndTime = null;
      } else {
        if (_remainingSeconds > 0) {
          _isRunning = true;
          _startTimer();
        }
      }
    });
  }

  void _addSeconds(int seconds) {
    setState(() {
      _remainingSeconds += seconds;
      if (_remainingSeconds > _totalSeconds) {
        _totalSeconds = _remainingSeconds;
      }
      if (_isRunning) {
        _targetEndTime = DateTime.now().add(
          Duration(seconds: _remainingSeconds),
        );
      } else {
        _isRunning = true;
        _startTimer();
      }
    });
  }

  void _setDuration(int seconds) {
    setState(() {
      _totalSeconds = seconds;
      _remainingSeconds = seconds;
      _isRunning = true;
      _startTimer();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalSeconds > 0
        ? (_remainingSeconds / _totalSeconds).clamp(0.0, 1.0)
        : 0.0;
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    final timeStr =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF151B23),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: _remainingSeconds <= 5
              ? const Color(0xFFB6FF3B)
              : const Color(0xFF1C2430),
          width: 2,
        ),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        color: Color(0xFFB6FF3B),
                        size: 22,
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'REST PERIOD',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFFB6FF3B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onSkip,
                  tooltip: 'Skip rest',
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.nextExerciseName != null) ...[
              Text(
                'Up Next: ${widget.nextExerciseName}${widget.nextSetNumber != null ? ' (Set ${widget.nextSetNumber})' : ''}',
                style: const TextStyle(
                  color: Color(0xFFA7B0BF),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: 170,
              height: 170,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 10,
                      strokeCap: StrokeCap.round,
                      backgroundColor: const Color(0xFF1C2430),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _remainingSeconds <= 5
                            ? const Color(0xFFFFB547)
                            : const Color(0xFFB6FF3B),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeStr,
                        style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        _isRunning ? 'RECOVER' : 'PAUSED',
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 2,
                          color: _isRunning
                              ? const Color(0xFFA7B0BF)
                              : const Color(0xFFFFB547),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Interval preset chips
            Wrap(
              spacing: 8,
              children: [30, 60, 90, 120].map((s) {
                final isCurrent = _totalSeconds == s;
                return ChoiceChip(
                  label: Text('${s}s'),
                  selected: isCurrent,
                  onSelected: (_) => _setDuration(s),
                  selectedColor: const Color(0xFFB6FF3B).withAlpha(40),
                  labelStyle: TextStyle(
                    color: isCurrent ? const Color(0xFFB6FF3B) : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _addSeconds(15),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('+15s'),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _isRunning
                        ? const Color(0xFF1C2430)
                        : const Color(0xFFB6FF3B),
                    foregroundColor: _isRunning ? Colors.white : Colors.black,
                  ),
                  onPressed: _togglePause,
                  icon: Icon(
                    _isRunning ? Icons.pause : Icons.play_arrow,
                    size: 20,
                  ),
                  label: Text(_isRunning ? 'Pause' : 'Resume'),
                ),
                OutlinedButton(
                  onPressed: widget.onSkip,
                  child: const Text('Skip'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

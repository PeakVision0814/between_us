import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

enum _ProbeScene { lightMotion, paintMotion, scrollList }

class _SampleStats {
  const _SampleStats({
    required this.average,
    required this.median,
    required this.p90,
    required this.min,
    required this.max,
  });

  final double average;
  final double median;
  final double p90;
  final double min;
  final double max;

  double get hz => 1000 / average;
}

// Temporary high-refresh probe for on-device diagnosis.
class DebugRefreshDiagnosticsCard extends StatefulWidget {
  const DebugRefreshDiagnosticsCard({super.key});

  @override
  State<DebugRefreshDiagnosticsCard> createState() =>
      _DebugRefreshDiagnosticsCardState();
}

class _DebugRefreshDiagnosticsCardState
    extends State<DebugRefreshDiagnosticsCard>
    with TickerProviderStateMixin {
  static const int _maxSamples = 240;
  static const Duration _metricsUiUpdateInterval = Duration(milliseconds: 250);

  final Queue<double> _frameIntervalMs = Queue<double>();
  final Queue<double> _tickerIntervalMs = Queue<double>();
  final Queue<double> _buildDurationMs = Queue<double>();
  final Queue<double> _rasterDurationMs = Queue<double>();
  final Stopwatch _uiUpdateStopwatch = Stopwatch();

  late final AnimationController _motionController;
  late final Ticker _probeTicker;

  _ProbeScene _scene = _ProbeScene.lightMotion;
  bool _isProbeRunning = false;
  int _frameSampleCount = 0;
  int _tickerSampleCount = 0;
  int? _lastVsyncMicros;
  Duration? _lastTickerElapsed;

  @override
  void initState() {
    super.initState();
    _motionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _probeTicker = createTicker(_handleTicker);
    _uiUpdateStopwatch.start();
    SchedulerBinding.instance.addTimingsCallback(_handleFrameTimings);
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_handleFrameTimings);
    _probeTicker.dispose();
    _motionController.dispose();
    super.dispose();
  }

  void _toggleProbe() {
    if (_isProbeRunning) {
      setState(() {
        _motionController.stop();
        _probeTicker.stop();
        _isProbeRunning = false;
      });
      return;
    }

    setState(() {
      _clearSamples();
      _motionController
        ..value = 0
        ..repeat(reverse: true);
      _probeTicker.start();
      _isProbeRunning = true;
    });
  }

  void _clearSamples() {
    _frameIntervalMs.clear();
    _tickerIntervalMs.clear();
    _buildDurationMs.clear();
    _rasterDurationMs.clear();
    _frameSampleCount = 0;
    _tickerSampleCount = 0;
    _lastVsyncMicros = null;
    _lastTickerElapsed = null;
    _uiUpdateStopwatch.reset();
    _uiUpdateStopwatch.start();
  }

  void _handleTicker(Duration elapsed) {
    if (!_isProbeRunning || !mounted) {
      return;
    }

    final previous = _lastTickerElapsed;
    if (previous != null) {
      final intervalMs = (elapsed - previous).inMicroseconds / 1000;
      if (intervalMs > 0 && intervalMs < 100) {
        _pushSample(_tickerIntervalMs, intervalMs);
        _tickerSampleCount += 1;
        _requestMetricsUiUpdate();
      }
    }
    _lastTickerElapsed = elapsed;
  }

  void _handleFrameTimings(List<ui.FrameTiming> timings) {
    if (!_isProbeRunning || !mounted) {
      return;
    }

    var updated = false;
    for (final timing in timings) {
      final vsyncMicros = timing.timestampInMicroseconds(
        ui.FramePhase.vsyncStart,
      );
      if (_lastVsyncMicros != null) {
        final intervalMs = (vsyncMicros - _lastVsyncMicros!) / 1000;
        if (intervalMs > 0 && intervalMs < 100) {
          _pushSample(_frameIntervalMs, intervalMs);
          _pushSample(
            _buildDurationMs,
            timing.buildDuration.inMicroseconds / 1000,
          );
          _pushSample(
            _rasterDurationMs,
            timing.rasterDuration.inMicroseconds / 1000,
          );
          _frameSampleCount += 1;
          updated = true;
        }
      }
      _lastVsyncMicros = vsyncMicros;
    }

    if (updated) {
      _requestMetricsUiUpdate();
    }
  }

  void _requestMetricsUiUpdate() {
    if (!_uiUpdateStopwatch.isRunning ||
        _uiUpdateStopwatch.elapsed < _metricsUiUpdateInterval) {
      return;
    }
    _uiUpdateStopwatch.reset();
    _uiUpdateStopwatch.start();
    setState(() {});
  }

  void _pushSample(Queue<double> queue, double value) {
    queue.addLast(value);
    if (queue.length > _maxSamples) {
      queue.removeFirst();
    }
  }

  _SampleStats? _statsOf(Queue<double> queue) {
    if (queue.isEmpty) {
      return null;
    }
    final sorted = queue.toList()..sort();
    final total = sorted.fold<double>(0, (sum, value) => sum + value);
    return _SampleStats(
      average: total / sorted.length,
      median: sorted[sorted.length ~/ 2],
      p90: sorted[(sorted.length * 0.9).floor().clamp(0, sorted.length - 1)],
      min: sorted.first,
      max: sorted.last,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final view = View.of(context);
    final display = view.display;
    final targetIntervalMs = 1000 / display.refreshRate;
    final frameStats = _statsOf(_frameIntervalMs);
    final tickerStats = _statsOf(_tickerIntervalMs);
    final buildStats = _statsOf(_buildDurationMs);
    final rasterStats = _statsOf(_rasterDurationMs);

    return Card(
      color: colorScheme.secondary.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.developer_mode_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'High Refresh Diagnostics',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                FilledButton.tonal(
                  onPressed: _toggleProbe,
                  child: Text(_isProbeRunning ? 'Stop probe' : 'Start probe'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Debug-only probe. It compares Flutter display capability, scheduler cadence, and produced-frame cadence under an explicit motion scene.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            _MetricRow(title: 'Runtime mode', value: _runtimeModeLabel),
            _MetricRow(
              title: 'Flutter display refreshRate',
              value: '${display.refreshRate.toStringAsFixed(1)} Hz',
            ),
            _MetricRow(
              title: '120 Hz target interval',
              value: '${targetIntervalMs.toStringAsFixed(2)} ms',
            ),
            _MetricRow(title: 'Display id', value: '${display.id}'),
            _MetricRow(
              title: 'Display size',
              value:
                  '${display.size.width.toStringAsFixed(0)} x ${display.size.height.toStringAsFixed(0)} px',
            ),
            _MetricRow(
              title: 'View DPR',
              value: view.devicePixelRatio.toStringAsFixed(2),
            ),
            const Divider(height: 22),
            _MetricRow(
              title: 'Ticker cadence',
              value: _formatCadence(tickerStats),
            ),
            _MetricRow(
              title: 'FrameTiming cadence',
              value: _formatCadence(frameStats),
            ),
            _MetricRow(
              title: 'Average build',
              value: _formatDuration(buildStats),
            ),
            _MetricRow(
              title: 'Average raster',
              value: _formatDuration(rasterStats),
            ),
            _MetricRow(
              title: 'Samples',
              value:
                  'ticker $_tickerSampleCount / frame timing $_frameSampleCount',
            ),
            const SizedBox(height: 12),
            SegmentedButton<_ProbeScene>(
              segments: const [
                ButtonSegment(
                  value: _ProbeScene.lightMotion,
                  label: Text('Light'),
                  icon: Icon(Icons.timeline_outlined),
                ),
                ButtonSegment(
                  value: _ProbeScene.paintMotion,
                  label: Text('Paint'),
                  icon: Icon(Icons.brush_outlined),
                ),
                ButtonSegment(
                  value: _ProbeScene.scrollList,
                  label: Text('List'),
                  icon: Icon(Icons.view_list_outlined),
                ),
              ],
              selected: {_scene},
              onSelectionChanged: (selection) {
                setState(() {
                  _scene = selection.single;
                  if (_isProbeRunning) {
                    _clearSamples();
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            RepaintBoundary(
              child: _MotionProbeStage(
                animation: _motionController,
                scene: _scene,
                isRunning: _isProbeRunning,
              ),
            ),
            const SizedBox(height: 12),
            Text(_diagnosticHint, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  String _formatCadence(_SampleStats? stats) {
    if (stats == null) {
      return 'No samples yet';
    }
    return '${stats.average.toStringAsFixed(2)} ms (${stats.hz.toStringAsFixed(1)} Hz), p50 ${stats.median.toStringAsFixed(2)} ms, p90 ${stats.p90.toStringAsFixed(2)} ms';
  }

  String _formatDuration(_SampleStats? stats) {
    if (stats == null) {
      return 'No samples yet';
    }
    return '${stats.average.toStringAsFixed(2)} ms, p50 ${stats.median.toStringAsFixed(2)} ms, p90 ${stats.p90.toStringAsFixed(2)} ms';
  }

  String get _runtimeModeLabel {
    if (kReleaseMode) {
      return 'release';
    }
    if (kProfileMode) {
      return 'profile';
    }
    return 'debug';
  }

  String get _diagnosticHint {
    if (kDebugMode) {
      return 'Debug mode has extra instrumentation and JIT overhead. Use profile or release on a real 120 Hz device for trustworthy numbers.';
    }
    return 'If Ticker and FrameTiming both stay near 16.67 ms during Light motion, Flutter is receiving or producing frames at about 60 Hz even though the display reports 120 Hz.';
  }
}

class _MotionProbeStage extends StatelessWidget {
  const _MotionProbeStage({
    required this.animation,
    required this.scene,
    required this.isRunning,
  });

  final Animation<double> animation;
  final _ProbeScene scene;
  final bool isRunning;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: SizedBox(
          height: 180,
          width: double.infinity,
          child: switch (scene) {
            _ProbeScene.lightMotion => _LightMotionScene(
              animation: animation,
              isRunning: isRunning,
            ),
            _ProbeScene.paintMotion => _PaintMotionScene(
              animation: animation,
              isRunning: isRunning,
            ),
            _ProbeScene.scrollList => const _ScrollListScene(),
          },
        ),
      ),
    );
  }
}

class _LightMotionScene extends StatelessWidget {
  const _LightMotionScene({required this.animation, required this.isRunning});

  final Animation<double> animation;
  final bool isRunning;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final alignment = Alignment((animation.value * 2) - 1, 0);
        return ColoredBox(
          color: colorScheme.surface,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: alignment,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isRunning
                        ? colorScheme.primary
                        : colorScheme.outlineVariant,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                left: 14,
                bottom: 12,
                child: Text(
                  'Light transform animation',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PaintMotionScene extends StatelessWidget {
  const _PaintMotionScene({required this.animation, required this.isRunning});

  final Animation<double> animation;
  final bool isRunning;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return CustomPaint(
          painter: _PaintProbePainter(
            progress: animation.value,
            primary: isRunning ? colorScheme.primary : colorScheme.outline,
            secondary: colorScheme.tertiary,
            surface: colorScheme.surface,
          ),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                'Paint-heavy animation',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ScrollListScene extends StatelessWidget {
  const _ScrollListScene();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 48,
      itemBuilder: (context, index) {
        return ListTile(
          dense: true,
          leading: CircleAvatar(radius: 12, child: Text('${index + 1}')),
          title: Text('Scroll cadence row ${index + 1}'),
          subtitle: const Text('Fling this nested list while the probe runs.'),
        );
      },
    );
  }
}

class _PaintProbePainter extends CustomPainter {
  const _PaintProbePainter({
    required this.progress,
    required this.primary,
    required this.secondary,
    required this.surface,
  });

  final double progress;
  final Color primary;
  final Color secondary;
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(surface, BlendMode.src);
    final stripePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = secondary.withValues(alpha: 0.35);
    final dotPaint = Paint()..color = primary.withValues(alpha: 0.78);
    final phase = progress * math.pi * 2;

    for (var i = 0; i < 28; i += 1) {
      final y = ((i + progress) / 28) * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), stripePaint);
    }

    for (var i = 0; i < 64; i += 1) {
      final row = i ~/ 8;
      final column = i % 8;
      final x = (column + 0.5) * size.width / 8;
      final baseY = (row + 0.5) * size.height / 8;
      final y = baseY + math.sin(phase + i * 0.45) * 12;
      final radius = 3.5 + math.cos(phase + i * 0.3).abs() * 3;
      canvas.drawCircle(Offset(x, y), radius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PaintProbePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primary != primary ||
        oldDelegate.secondary != secondary ||
        oldDelegate.surface != surface;
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(title, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

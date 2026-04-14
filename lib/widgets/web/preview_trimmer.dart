import 'package:flutter/material.dart';
import '../../theme/theme.dart';

/// Lets a creator drag a window to pick the 30-second preview start point.
/// [totalDurationMs] is the full track length in milliseconds.
/// [initialStartMs] is the currently saved start point.
/// [onChanged] fires whenever the user moves the handle.
class PreviewTrimmer extends StatefulWidget {
  final int totalDurationMs;
  final int initialStartMs;
  final ValueChanged<int> onChanged;

  const PreviewTrimmer({
    super.key,
    required this.totalDurationMs,
    required this.initialStartMs,
    required this.onChanged,
  });

  @override
  State<PreviewTrimmer> createState() => _PreviewTrimmerState();
}

class _PreviewTrimmerState extends State<PreviewTrimmer> {
  late double _startFraction;
  static const int _previewMs = 30000;

  @override
  void initState() {
    super.initState();
    _startFraction = widget.initialStartMs / widget.totalDurationMs.toDouble();
  }

  int get _startMs => (_startFraction * widget.totalDurationMs).round();
  int get _endMs => (_startMs + _previewMs).clamp(0, widget.totalDurationMs);
  double get _endFraction => _endMs / widget.totalDurationMs.toDouble();

  String _msToDisplay(int ms) {
    final secs = ms ~/ 1000;
    final m = secs ~/ 60;
    final s = secs % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Preview Start', style: theme.textTheme.titleSmall),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingSm,
                vertical: AppTheme.spacingXxs,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              ),
              child: Text(
                '${_msToDisplay(_startMs)} → ${_msToDisplay(_endMs)}  (:30)',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingSm),
        LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;
            final windowLeft = _startFraction * totalWidth;
            final windowWidth =
                (_endFraction - _startFraction).clamp(0.0, 1.0) * totalWidth;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: (details) {
                final delta = details.delta.dx / totalWidth;
                setState(() {
                  _startFraction = (_startFraction + delta).clamp(
                    0.0,
                    1.0 - (_previewMs / widget.totalDurationMs),
                  );
                });
                widget.onChanged(_startMs);
              },
              child: Stack(
                children: [
                  // Full waveform bar (placeholder)
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: List.generate(
                        60,
                        (i) => Container(
                          width: 2,
                          height: (4.0 + (i % 7) * 5.0),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.outline,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Selected window highlight
                  Positioned(
                    left: windowLeft,
                    width: windowWidth,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colors.gradient1.withOpacity(AppTheme.opacityDisabled),
                            colors.gradient2.withOpacity(AppTheme.opacityDisabled),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        border: Border.all(
                          color: colors.gradient1,
                          width: AppTheme.borderSelected,
                        ),
                      ),
                    ),
                  ),
                  // Drag handle
                  Positioned(
                    left: (windowLeft - 10).clamp(0, totalWidth - 20),
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        width: 20,
                        height: 48,
                        decoration: BoxDecoration(
                          color: colors.gradient1,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: Icon(
                          Icons.drag_indicator_rounded,
                          color: theme.colorScheme.onPrimary,
                          size: AppTheme.iconSm,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Text(
          'Drag the handle to set where your 30-second preview starts.',
          style: theme.textTheme.bodySmall?.copyWith(color: colors.subtleText),
        ),
      ],
    );
  }
}

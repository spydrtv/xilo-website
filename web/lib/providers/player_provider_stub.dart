import 'dart:async';
import '../models/track.dart';

/// Web stub — just_audio is not available on web/preview.
/// Uses a Timer to simulate playback so the preview UI works identically.
class AudioDelegate {
  final void Function(Duration) onPositionChanged;
  final void Function() onTrackCompleted;

  Timer? _timer;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  AudioDelegate({
    required this.onPositionChanged,
    required this.onTrackCompleted,
  });

  void play(Track track) {
    _position = Duration.zero;
    _duration = track.duration;
    _startTimer();
  }

  void pause() {
    _timer?.cancel();
  }

  void resume() {
    _startTimer();
  }

  void seek(Duration position) {
    _position = position;
  }

  void dispose() {
    _timer?.cancel();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _position += const Duration(seconds: 1);
      onPositionChanged(_position);
      if (_duration.inSeconds > 0 && _position >= _duration) {
        _timer?.cancel();
        onTrackCompleted();
      }
    });
  }
}

import 'dart:async';
import 'package:just_audio/just_audio.dart';
import '../models/track.dart';

/// Mobile audio delegate — wraps just_audio's AudioPlayer.
/// PlayerProvider calls these methods; this file is only compiled on iOS/Android.
class AudioDelegate {
  final void Function(Duration) onPositionChanged;
  final void Function() onTrackCompleted;

  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _stateSub;

  AudioDelegate({
    required this.onPositionChanged,
    required this.onTrackCompleted,
  }) {
    // Stream real playback position every ~200ms.
    _positionSub = _player.positionStream.listen((pos) {
      onPositionChanged(pos);
    });

    // Detect natural track completion.
    _stateSub = _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        onTrackCompleted();
      }
    });
  }

  Future<void> play(Track track) async {
    try {
      await _player.stop();
      if (track.audioUrl != null && track.audioUrl!.isNotEmpty) {
        await _player.setUrl(track.audioUrl!);
        await _player.play();
      } else {
        // No audio URL — simulate position with a timer so UI still works.
        _simulatePlayback(track.duration);
      }
    } catch (_) {
      // Audio load failed — simulate so UI remains functional.
      _simulatePlayback(track.duration);
    }
  }

  Future<void> pause() async {
    _simulationTimer?.cancel();
    await _player.pause();
  }

  Future<void> resume() async {
    if (_player.audioSource != null) {
      await _player.play();
    } else {
      _simulationTimer?.cancel();
      // Resume simulation from current position.
      _startSimulation(_simulatedPosition, _simulatedDuration);
    }
  }

  Future<void> seek(Duration position) async {
    _simulatedPosition = position;
    if (_player.audioSource != null) {
      await _player.seek(position);
    }
  }

  void dispose() {
    _positionSub?.cancel();
    _stateSub?.cancel();
    _simulationTimer?.cancel();
    _player.dispose();
  }

  // ── Simulation fallback (for tracks without a real audio URL) ──────────────

  Timer? _simulationTimer;
  Duration _simulatedPosition = Duration.zero;
  Duration _simulatedDuration = Duration.zero;

  void _simulatePlayback(Duration duration) {
    _simulatedPosition = Duration.zero;
    _simulatedDuration = duration;
    _startSimulation(Duration.zero, duration);
  }

  void _startSimulation(Duration from, Duration total) {
    _simulationTimer?.cancel();
    _simulatedPosition = from;
    _simulationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _simulatedPosition += const Duration(seconds: 1);
      onPositionChanged(_simulatedPosition);
      if (_simulatedPosition >= total) {
        _simulationTimer?.cancel();
        onTrackCompleted();
      }
    });
  }
}

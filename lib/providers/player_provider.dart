import 'package:flutter/foundation.dart';
import '../models/track.dart';
import '../services/music_service.dart';

// just_audio is only available on mobile (iOS/Android).
// On web (preview), we keep the Timer-based simulation so the preview works.
import 'player_provider_audio.dart'
    if (dart.library.html) 'player_provider_stub.dart' as _audio;

class PlayerProvider extends ChangeNotifier {
  final MusicService _service;
  PlayerProvider({required MusicService service}) : _service = service {
    _audioDelegate = _audio.AudioDelegate(onPositionChanged: _onPositionChanged,
        onTrackCompleted: _onTrackCompleted);
  }

  late final _audio.AudioDelegate _audioDelegate;

  Track? _currentTrack;
  Track? get currentTrack => _currentTrack;

  List<Track> _queue = [];
  List<Track> get queue => _queue;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  Duration _position = Duration.zero;
  Duration get position => _position;

  bool _shuffle = false;
  bool get shuffle => _shuffle;

  bool _repeat = false;
  bool get repeat => _repeat;

  // Called by the audio delegate when position updates.
  void _onPositionChanged(Duration pos) {
    _position = pos;
    notifyListeners();
  }

  // Called by the audio delegate when a track finishes naturally.
  void _onTrackCompleted() {
    skipNext();
  }

  void playTrack(Track track, {List<Track>? queue}) {
    _currentTrack = track;
    _isPlaying = true;
    _position = Duration.zero;
    if (queue != null) _queue = queue;
    _audioDelegate.play(track);
    notifyListeners();
  }

  void playAlbum(String albumId) {
    final tracks = _service.getTracksByAlbum(albumId);
    if (tracks.isNotEmpty) {
      _queue = tracks;
      playTrack(tracks.first, queue: tracks);
    }
  }

  void togglePlayPause() {
    if (_isPlaying) {
      _audioDelegate.pause();
    } else {
      _audioDelegate.resume();
    }
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  void seek(Duration position) {
    _position = position;
    _audioDelegate.seek(position);
    notifyListeners();
  }

  void skipNext() {
    if (_queue.isEmpty || _currentTrack == null) return;
    final idx = _queue.indexWhere((t) => t.id == _currentTrack!.id);
    if (_shuffle) {
      final available = List<int>.generate(_queue.length, (i) => i)
        ..remove(idx);
      if (available.isNotEmpty) {
        available.shuffle();
        playTrack(_queue[available.first]);
      }
    } else if (idx < _queue.length - 1) {
      playTrack(_queue[idx + 1]);
    } else if (_repeat) {
      playTrack(_queue.first);
    }
  }

  void skipPrevious() {
    if (_queue.isEmpty || _currentTrack == null) return;
    if (_position.inSeconds > 3) {
      seek(Duration.zero);
      return;
    }
    final idx = _queue.indexWhere((t) => t.id == _currentTrack!.id);
    if (idx > 0) {
      playTrack(_queue[idx - 1]);
    }
  }

  void toggleShuffle() {
    _shuffle = !_shuffle;
    notifyListeners();
  }

  void toggleRepeat() {
    _repeat = !_repeat;
    notifyListeners();
  }

  @override
  void dispose() {
    _audioDelegate.dispose();
    super.dispose();
  }
}

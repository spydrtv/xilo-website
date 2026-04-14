import 'package:flutter/foundation.dart';
import '../models/playlist.dart';
import '../services/library_service.dart';

class LibraryProvider extends ChangeNotifier {
  final LibraryService _service;
  LibraryProvider({required LibraryService service}) : _service = service;

  Set<String> get favoriteIds => _service.getFavoriteIds();
  List<Playlist> get playlists => _service.getPlaylists();

  bool isFavorite(String trackId) => _service.isFavorite(trackId);

  void toggleFavorite(String trackId) {
    _service.toggleFavorite(trackId);
    notifyListeners();
  }

  void createPlaylist(String name) {
    _service.createPlaylist(name);
    notifyListeners();
  }

  void addTrackToPlaylist(String playlistId, String trackId) {
    _service.addTrackToPlaylist(playlistId, trackId);
    notifyListeners();
  }

  void removeTrackFromPlaylist(String playlistId, String trackId) {
    _service.removeTrackFromPlaylist(playlistId, trackId);
    notifyListeners();
  }

  void deletePlaylist(String playlistId) {
    _service.deletePlaylist(playlistId);
    notifyListeners();
  }
}

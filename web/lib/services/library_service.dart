import '../models/playlist.dart';
import '../repositories/library_repository.dart';

class LibraryService {
  final LibraryRepository _repository;
  LibraryService({required LibraryRepository repository}) : _repository = repository;

  Set<String> getFavoriteIds() => _repository.getFavoriteIds();
  bool isFavorite(String trackId) => _repository.isFavorite(trackId);
  void toggleFavorite(String trackId) => _repository.toggleFavorite(trackId);

  List<Playlist> getPlaylists() => _repository.getPlaylists();
  Playlist createPlaylist(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError('Playlist name cannot be empty');
    return _repository.createPlaylist(trimmed);
  }

  void addTrackToPlaylist(String playlistId, String trackId) =>
      _repository.addTrackToPlaylist(playlistId, trackId);

  void removeTrackFromPlaylist(String playlistId, String trackId) =>
      _repository.removeTrackFromPlaylist(playlistId, trackId);

  void deletePlaylist(String playlistId) =>
      _repository.deletePlaylist(playlistId);
}

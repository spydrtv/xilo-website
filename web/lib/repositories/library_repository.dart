import '../models/playlist.dart';

class LibraryRepository {
  final Set<String> _favoriteTrackIds = {};
  final List<Playlist> _playlists = [];

  Set<String> getFavoriteIds() => Set.unmodifiable(_favoriteTrackIds);

  void toggleFavorite(String trackId) {
    if (_favoriteTrackIds.contains(trackId)) {
      _favoriteTrackIds.remove(trackId);
    } else {
      _favoriteTrackIds.add(trackId);
    }
  }

  bool isFavorite(String trackId) => _favoriteTrackIds.contains(trackId);

  List<Playlist> getPlaylists() => List.unmodifiable(_playlists);

  Playlist createPlaylist(String name) {
    final playlist = Playlist(
      id: 'pl_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      createdAt: DateTime.now(),
    );
    _playlists.add(playlist);
    return playlist;
  }

  void addTrackToPlaylist(String playlistId, String trackId) {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      final pl = _playlists[index];
      if (!pl.trackIds.contains(trackId)) {
        _playlists[index] = pl.copyWith(trackIds: [...pl.trackIds, trackId]);
      }
    }
  }

  void removeTrackFromPlaylist(String playlistId, String trackId) {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      final pl = _playlists[index];
      _playlists[index] = pl.copyWith(
        trackIds: pl.trackIds.where((id) => id != trackId).toList(),
      );
    }
  }

  void deletePlaylist(String playlistId) {
    _playlists.removeWhere((p) => p.id == playlistId);
  }
}

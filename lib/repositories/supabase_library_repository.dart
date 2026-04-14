import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/playlist.dart';
import 'library_repository.dart';

/// Extends [LibraryRepository] with Supabase persistence.
/// When the user is not signed in, all operations fall back to in-memory state.
class SupabaseLibraryRepository extends LibraryRepository {
  final SupabaseClient _client;

  SupabaseLibraryRepository({required SupabaseClient client})
      : _client = client;

  String? get _userId => _client.auth.currentUser?.id;
  bool get _isSignedIn => _userId != null;

  // ---------------------------------------------------------------------------
  // Favorites
  // ---------------------------------------------------------------------------

  @override
  void toggleFavorite(String trackId) {
    // Always update local in-memory state immediately for responsive UI.
    super.toggleFavorite(trackId);

    // Persist to Supabase in the background if signed in.
    if (_isSignedIn) {
      _persistFavorite(trackId);
    }
  }

  Future<void> _persistFavorite(String trackId) async {
    try {
      final isFav = super.isFavorite(trackId);
      if (isFav) {
        await _client.from('user_favorites').insert({
          'user_id': _userId,
          'track_id': trackId,
        });
      } else {
        await _client
            .from('user_favorites')
            .delete()
            .eq('user_id', _userId!)
            .eq('track_id', trackId);
      }
    } catch (_) {
      // Persistence failed silently — in-memory state already updated.
    }
  }

  /// Loads persisted favorites from Supabase for the signed-in user.
  Future<void> loadFavorites() async {
    if (!_isSignedIn) return;
    try {
      final response = await _client
          .from('user_favorites')
          .select('track_id')
          .eq('user_id', _userId!);

      for (final row in response as List) {
        final trackId = row['track_id']?.toString();
        if (trackId != null) {
          super.toggleFavorite(trackId); // add to in-memory set
        }
      }
    } catch (_) {
      // Load failed silently — app works with empty favorites.
    }
  }

  // ---------------------------------------------------------------------------
  // Playlists
  // ---------------------------------------------------------------------------

  @override
  Playlist createPlaylist(String name) {
    final playlist = super.createPlaylist(name);

    if (_isSignedIn) {
      _persistPlaylistCreate(playlist);
    }

    return playlist;
  }

  Future<void> _persistPlaylistCreate(Playlist playlist) async {
    try {
      await _client.from('playlists').insert({
        'id': playlist.id,
        'user_id': _userId,
        'name': playlist.name,
        'created_at': playlist.createdAt.toIso8601String(),
      });
    } catch (_) {
      // Persistence failed silently.
    }
  }

  @override
  void addTrackToPlaylist(String playlistId, String trackId) {
    super.addTrackToPlaylist(playlistId, trackId);

    if (_isSignedIn) {
      _persistPlaylistTrackAdd(playlistId, trackId);
    }
  }

  Future<void> _persistPlaylistTrackAdd(
      String playlistId, String trackId) async {
    try {
      await _client.from('playlist_tracks').insert({
        'playlist_id': playlistId,
        'track_id': trackId,
      });
    } catch (_) {}
  }

  @override
  void removeTrackFromPlaylist(String playlistId, String trackId) {
    super.removeTrackFromPlaylist(playlistId, trackId);

    if (_isSignedIn) {
      _persistPlaylistTrackRemove(playlistId, trackId);
    }
  }

  Future<void> _persistPlaylistTrackRemove(
      String playlistId, String trackId) async {
    try {
      await _client
          .from('playlist_tracks')
          .delete()
          .eq('playlist_id', playlistId)
          .eq('track_id', trackId);
    } catch (_) {}
  }

  @override
  void deletePlaylist(String playlistId) {
    super.deletePlaylist(playlistId);

    if (_isSignedIn) {
      _persistPlaylistDelete(playlistId);
    }
  }

  Future<void> _persistPlaylistDelete(String playlistId) async {
    try {
      await _client
          .from('playlists')
          .delete()
          .eq('id', playlistId)
          .eq('user_id', _userId!);
    } catch (_) {}
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/track.dart';
import '../models/artist.dart';
import '../models/album.dart';
import 'music_repository.dart';

/// Implements the same interface as [MusicRepository] so it can be swapped in
/// transparently. Fetches real data from Supabase; falls back to mock data
/// per-method if a table is empty or a query fails.
class SupabaseMusicRepository extends MusicRepository {
  final SupabaseClient _client;

  List<Artist> _artists = [];
  List<Album> _albums = [];
  List<Track> _tracks = [];

  bool _loaded = false;

  SupabaseMusicRepository({required SupabaseClient client}) : _client = client;

  /// Fetches all catalog data from Supabase up front so sync getters work.
  /// Falls back to mock data silently if any table is empty or unreachable.
  Future<void> preload() async {
    try {
      final artistsFuture = _fetchArtists();
      final albumsFuture = _fetchAlbums();
      final tracksFuture = _fetchTracks();

      final results = await Future.wait([
        artistsFuture,
        albumsFuture,
        tracksFuture,
      ]);

      final artists = results[0] as List<Artist>;
      final albums = results[1] as List<Album>;
      final tracks = results[2] as List<Track>;

      // Only use Supabase data if all three tables returned something.
      if (artists.isNotEmpty && albums.isNotEmpty && tracks.isNotEmpty) {
        _artists = artists;
        _albums = albums;
        _tracks = tracks;
        _loaded = true;
      }
    } catch (_) {
      // Supabase failed — leave _loaded false so mock data is used.
    }
  }

  // ---------------------------------------------------------------------------
  // Sync getters — return Supabase data if loaded, otherwise mock data.
  // ---------------------------------------------------------------------------

  @override
  List<Artist> getArtists() => _loaded ? _artists : super.getArtists();

  @override
  List<Album> getAlbums() => _loaded ? _albums : super.getAlbums();

  @override
  List<Track> getTracks() => _loaded ? _tracks : super.getTracks();

  @override
  Artist? getArtistById(String id) {
    if (!_loaded) return super.getArtistById(id);
    try {
      return _artists.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Album? getAlbumById(String id) {
    if (!_loaded) return super.getAlbumById(id);
    try {
      return _albums.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Track? getTrackById(String id) {
    if (!_loaded) return super.getTrackById(id);
    try {
      return _tracks.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  List<Track> getTracksByArtist(String artistId) {
    if (!_loaded) return super.getTracksByArtist(artistId);
    return _tracks.where((t) => t.artistId == artistId).toList();
  }

  @override
  List<Album> getAlbumsByArtist(String artistId) {
    if (!_loaded) return super.getAlbumsByArtist(artistId);
    return _albums.where((a) => a.artistId == artistId).toList();
  }

  @override
  List<Track> getTracksByAlbum(String albumId) {
    if (!_loaded) return super.getTracksByAlbum(albumId);
    return _tracks.where((t) => t.albumId == albumId).toList();
  }

  @override
  List<String> getGenres() {
    if (!_loaded) return super.getGenres();
    return _tracks.map((t) => t.genre).toSet().toList()..sort();
  }

  @override
  List<String> getMoods() {
    if (!_loaded) return super.getMoods();
    return _tracks.map((t) => t.mood).toSet().toList()..sort();
  }

  @override
  List<int> getYears() {
    if (!_loaded) return super.getYears();
    final years = {
      ..._tracks.map((t) => t.releaseYear),
      ..._albums.map((a) => a.year),
    }.toList();
    years.sort((a, b) => b.compareTo(a));
    return years;
  }

  // ---------------------------------------------------------------------------
  // Private fetch helpers — each catches its own errors independently.
  // ---------------------------------------------------------------------------

  Future<List<Artist>> _fetchArtists() async {
    try {
      final response = await _client
          .from('artists')
          .select()
          .order('created_at', ascending: false);

      return (response as List).map((row) => _rowToArtist(row)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Album>> _fetchAlbums() async {
    try {
      final response = await _client
          .from('albums')
          .select()
          .order('created_at', ascending: false);

      return (response as List).map((row) => _rowToAlbum(row)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Track>> _fetchTracks() async {
    try {
      final response = await _client
          .from('tracks')
          .select()
          .order('created_at', ascending: false);

      return (response as List).map((row) => _rowToTrack(row)).toList();
    } catch (_) {
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Row mappers — map Supabase JSON rows to Flutter model objects.
  // ---------------------------------------------------------------------------

  Artist _rowToArtist(Map<String, dynamic> row) {
    return Artist(
      id: row['id']?.toString() ?? '',
      name: row['name']?.toString() ?? '',
      imageUrl: row['image_url']?.toString() ?? '',
      bio: row['bio']?.toString() ?? '',
      isAiCreator: row['is_ai_creator'] as bool? ?? false,
      followerCount: (row['follower_count'] as num?)?.toInt() ?? 0,
      playCount: (row['play_count'] as num?)?.toInt() ?? 0,
      uploadCount: (row['upload_count'] as num?)?.toInt() ?? 0,
      genres: _parseStringList(row['genres']),
    );
  }

  Album _rowToAlbum(Map<String, dynamic> row) {
    final typeStr = row['type']?.toString() ?? 'album';
    final albumType = typeStr == 'single'
        ? AlbumType.single
        : typeStr == 'ep'
            ? AlbumType.ep
            : AlbumType.album;

    return Album(
      id: row['id']?.toString() ?? '',
      title: row['title']?.toString() ?? '',
      artistId: row['artist_id']?.toString() ?? '',
      artistName: row['artist_name']?.toString() ?? '',
      artUrl: row['art_url']?.toString() ?? '',
      type: albumType,
      year: (row['release_year'] as num?)?.toInt() ??
          DateTime.now().year,
      genre: row['genre']?.toString() ?? '',
      mood: row['mood']?.toString() ?? '',
      trackIds: _parseStringList(row['track_ids']),
      credits: row['credits']?.toString() ?? '',
      isExplicit: row['is_explicit'] as bool? ?? false,
      isAvailableForPurchase: row['is_available_for_purchase'] as bool? ?? true,
      isAvailableForLicensing:
          row['is_available_for_licensing'] as bool? ?? false,
      price: (row['price'] as num?)?.toDouble() ?? 9.99,
    );
  }

  Track _rowToTrack(Map<String, dynamic> row) {
    final durationMs = (row['duration_ms'] as num?)?.toInt() ?? 0;

    return Track(
      id: row['id']?.toString() ?? '',
      title: row['title']?.toString() ?? '',
      artistId: row['artist_id']?.toString() ?? '',
      artistName: row['artist_name']?.toString() ?? '',
      albumId: row['album_id']?.toString(),
      albumTitle: row['album_title']?.toString(),
      artUrl: row['art_url']?.toString() ?? '',
      duration: Duration(milliseconds: durationMs),
      genre: row['genre']?.toString() ?? '',
      mood: row['mood']?.toString() ?? '',
      isAiCreated: row['is_ai_created'] as bool? ?? false,
      credits: row['credits']?.toString() ?? '',
      releaseYear:
          (row['release_year'] as num?)?.toInt() ?? DateTime.now().year,
      isExplicit: row['is_explicit'] as bool? ?? false,
      previewStartMs: (row['preview_start_ms'] as num?)?.toInt() ?? 0,
      lyrics: row['lyrics']?.toString() ?? '',
      isAvailableForPurchase: row['is_available_for_purchase'] as bool? ?? true,
      isAvailableForLicensing:
          row['is_available_for_licensing'] as bool? ?? false,
      price: (row['price'] as num?)?.toDouble() ?? 1.29,
      audioUrl: row['audio_url']?.toString(),
    );
  }

  List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }
}

import '../models/track.dart';
import '../models/artist.dart';
import '../models/album.dart';
import '../models/search_filter.dart';
import '../repositories/music_repository.dart';

class MusicService {
  final MusicRepository _repository;
  MusicService({required MusicRepository repository}) : _repository = repository;

  List<Track> getAllTracks() => _repository.getTracks();
  List<Artist> getAllArtists() => _repository.getArtists();
  List<Artist> getArtists() => _repository.getArtists();
  List<Album> getAllAlbums() => _repository.getAlbums();

  Artist? getArtistById(String id) => _repository.getArtistById(id);
  Album? getAlbumById(String id) => _repository.getAlbumById(id);
  Track? getTrackById(String id) => _repository.getTrackById(id);

  List<Track> getTracksByArtist(String artistId) => _repository.getTracksByArtist(artistId);
  List<Album> getAlbumsByArtist(String artistId) => _repository.getAlbumsByArtist(artistId);
  List<Track> getTracksByAlbum(String albumId) => _repository.getTracksByAlbum(albumId);

  List<String> getGenres() => _repository.getGenres();
  List<String> getMoods() => _repository.getMoods();
  List<int> getYears() => _repository.getYears();

  List<Track> getFeaturedTracks() {
    final tracks = _repository.getTracks();
    return tracks.take(6).toList();
  }

  List<Album> getNewReleases() {
    final albums = _repository.getAlbums();
    final sorted = List<Album>.from(albums)..sort((a, b) => b.year.compareTo(a.year));
    return sorted.take(6).toList();
  }

  List<Artist> getTrendingArtists() {
    final artists = _repository.getArtists();
    final sorted = List<Artist>.from(artists)
      ..sort((a, b) => b.followerCount.compareTo(a.followerCount));
    return sorted.take(6).toList();
  }

  List<Track> getTracksByGenre(String genre) {
    return _repository.getTracks().where((t) => t.genre == genre).toList();
  }

  List<Track> getTracksByMood(String mood) {
    return _repository.getTracks().where((t) => t.mood == mood).toList();
  }

  /// Basic text-only search (no filters). Returns artists + albums + tracks.
  List<dynamic> search(String query) {
    final q = query.toLowerCase();
    if (q.isEmpty) return [];

    final tracks = _repository.getTracks().where((t) =>
        t.title.toLowerCase().contains(q) ||
        t.artistName.toLowerCase().contains(q) ||
        t.genre.toLowerCase().contains(q) ||
        t.mood.toLowerCase().contains(q)).toList();

    final artists = _repository.getArtists().where((a) =>
        a.name.toLowerCase().contains(q) ||
        a.genres.any((g) => g.toLowerCase().contains(q))).toList();

    final albums = _repository.getAlbums().where((a) =>
        a.title.toLowerCase().contains(q) ||
        a.artistName.toLowerCase().contains(q) ||
        a.genre.toLowerCase().contains(q)).toList();

    return [...artists, ...albums, ...tracks];
  }

  /// Search with granular filters applied on top of a text query.
  List<dynamic> filteredSearch(String query, SearchFilter filter) {
    final q = query.toLowerCase();

    // --- tracks ---
    Iterable<Track> tracks = _repository.getTracks();
    if (q.isNotEmpty) {
      tracks = tracks.where((t) =>
          t.title.toLowerCase().contains(q) ||
          t.artistName.toLowerCase().contains(q) ||
          t.genre.toLowerCase().contains(q) ||
          t.mood.toLowerCase().contains(q));
    }
    if (filter.genre != null) {
      tracks = tracks.where((t) => t.genre == filter.genre);
    }
    if (filter.mood != null) {
      tracks = tracks.where((t) => t.mood == filter.mood);
    }
    if (filter.releaseYearFrom != null) {
      tracks = tracks.where((t) => t.releaseYear >= filter.releaseYearFrom!);
    }
    if (filter.releaseYearTo != null) {
      tracks = tracks.where((t) => t.releaseYear <= filter.releaseYearTo!);
    }
    if (filter.isExplicit != null) {
      tracks = tracks.where((t) => t.isExplicit == filter.isExplicit);
    }
    if (filter.isAiCreated != null) {
      tracks = tracks.where((t) => t.isAiCreated == filter.isAiCreated);
    }
    // contentType filter: singles have no albumId; others are filtered via albums
    if (filter.contentType != null) {
      tracks = tracks.where((_) => false); // tracks shown under album results
    }

    // --- albums ---
    Iterable<Album> albums = _repository.getAlbums();
    if (q.isNotEmpty) {
      albums = albums.where((a) =>
          a.title.toLowerCase().contains(q) ||
          a.artistName.toLowerCase().contains(q) ||
          a.genre.toLowerCase().contains(q));
    }
    if (filter.genre != null) {
      albums = albums.where((a) => a.genre == filter.genre);
    }
    if (filter.contentType != null) {
      albums = albums.where((a) => a.type == filter.contentType);
    }
    if (filter.releaseYearFrom != null) {
      albums = albums.where((a) => a.year >= filter.releaseYearFrom!);
    }
    if (filter.releaseYearTo != null) {
      albums = albums.where((a) => a.year <= filter.releaseYearTo!);
    }
    if (filter.isExplicit != null) {
      albums = albums.where((a) => a.isExplicit == filter.isExplicit);
    }

    // --- artists ---
    Iterable<Artist> artists = _repository.getArtists();
    if (q.isNotEmpty) {
      artists = artists.where((a) =>
          a.name.toLowerCase().contains(q) ||
          a.genres.any((g) => g.toLowerCase().contains(q)));
    }
    if (filter.genre != null) {
      artists = artists.where((a) =>
          a.genres.any((g) => g == filter.genre));
    }
    if (filter.isAiCreated != null) {
      artists = artists.where((a) => a.isAiCreator == filter.isAiCreated);
    }
    // contentType applies to releases, not artists
    if (filter.contentType != null) {
      artists = artists.where((_) => false);
    }

    return [...artists.toList(), ...albums.toList(), ...tracks.toList()];
  }
}

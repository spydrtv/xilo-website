class Track {
  final String id;
  final String title;
  final String artistId;
  final String artistName;
  final String? albumId;
  final String? albumTitle;
  final String artUrl;
  final Duration duration;
  final String genre;
  final String mood;
  final bool isAiCreated;
  final String credits;
  final bool isFavorite;
  final int releaseYear;
  final bool isExplicit;
  final int previewStartMs;
  final String lyrics;
  final bool isAvailableForPurchase;
  final bool isAvailableForLicensing;
  final double price;
  final String? audioUrl;

  const Track({
    required this.id,
    required this.title,
    required this.artistId,
    required this.artistName,
    this.albumId,
    this.albumTitle,
    required this.artUrl,
    required this.duration,
    required this.genre,
    required this.mood,
    this.isAiCreated = false,
    this.credits = '',
    this.isFavorite = false,
    this.releaseYear = 2025,
    this.isExplicit = false,
    this.previewStartMs = 0,
    this.lyrics = '',
    this.isAvailableForPurchase = true,
    this.isAvailableForLicensing = false,
    this.price = 1.29,
    this.audioUrl,
  });

  Track copyWith({bool? isFavorite}) => Track(
        id: id,
        title: title,
        artistId: artistId,
        artistName: artistName,
        albumId: albumId,
        albumTitle: albumTitle,
        artUrl: artUrl,
        duration: duration,
        genre: genre,
        mood: mood,
        isAiCreated: isAiCreated,
        credits: credits,
        isFavorite: isFavorite ?? this.isFavorite,
        releaseYear: releaseYear,
        isExplicit: isExplicit,
        previewStartMs: previewStartMs,
        lyrics: lyrics,
        isAvailableForPurchase: isAvailableForPurchase,
        isAvailableForLicensing: isAvailableForLicensing,
        price: price,
        audioUrl: audioUrl,
      );

  String get durationString {
    final m = duration.inMinutes;
    final s = duration.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

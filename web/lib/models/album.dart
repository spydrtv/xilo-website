enum AlbumType { single, ep, album }

class Album {
  final String id;
  final String title;
  final String artistId;
  final String artistName;
  final String artUrl;
  final AlbumType type;
  final int year;
  final String genre;
  final String mood;
  final List<String> trackIds;
  final String credits;
  final bool isExplicit;
  final bool isAvailableForPurchase;
  final bool isAvailableForLicensing;
  final double price;

  const Album({
    required this.id,
    required this.title,
    required this.artistId,
    required this.artistName,
    required this.artUrl,
    required this.type,
    required this.year,
    required this.genre,
    this.mood = '',
    this.trackIds = const [],
    this.credits = '',
    this.isExplicit = false,
    this.isAvailableForPurchase = true,
    this.isAvailableForLicensing = false,
    this.price = 9.99,
  });

  String get typeLabel {
    switch (type) {
      case AlbumType.single:
        return 'Single';
      case AlbumType.ep:
        return 'EP';
      case AlbumType.album:
        return 'Album';
    }
  }
}

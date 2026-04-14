class Artist {
  final String id;
  final String name;
  final String imageUrl;
  final String bio;
  final bool isAiCreator;
  final int followerCount;
  final List<String> genres;
  final int playCount;
  final int uploadCount;

  const Artist({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.bio = '',
    this.isAiCreator = false,
    this.followerCount = 0,
    this.genres = const [],
    this.playCount = 0,
    this.uploadCount = 0,
  });

  /// Weighted score: 60% play count + 40% upload count (normalized to 10k scale).
  double get featuredScore =>
      (playCount / 10000.0) * 0.6 + (uploadCount / 10.0) * 0.4;
}

class Playlist {
  final String id;
  final String name;
  final String? artUrl;
  final List<String> trackIds;
  final DateTime createdAt;

  const Playlist({
    required this.id,
    required this.name,
    this.artUrl,
    this.trackIds = const [],
    required this.createdAt,
  });

  Playlist copyWith({String? name, List<String>? trackIds}) => Playlist(
        id: id,
        name: name ?? this.name,
        artUrl: artUrl,
        trackIds: trackIds ?? this.trackIds,
        createdAt: createdAt,
      );
}

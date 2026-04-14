import 'album.dart';

class SearchFilter {
  final String? genre;
  final String? mood;
  final AlbumType? contentType;
  final int? releaseYearFrom;
  final int? releaseYearTo;
  final bool? isExplicit;
  final bool? isAiCreated;

  const SearchFilter({
    this.genre,
    this.mood,
    this.contentType,
    this.releaseYearFrom,
    this.releaseYearTo,
    this.isExplicit,
    this.isAiCreated,
  });

  bool get hasActiveFilters =>
      genre != null ||
      mood != null ||
      contentType != null ||
      releaseYearFrom != null ||
      releaseYearTo != null ||
      isExplicit != null ||
      isAiCreated != null;

  int get activeFilterCount {
    int count = 0;
    if (genre != null) count++;
    if (mood != null) count++;
    if (contentType != null) count++;
    if (releaseYearFrom != null || releaseYearTo != null) count++;
    if (isExplicit != null) count++;
    if (isAiCreated != null) count++;
    return count;
  }

  SearchFilter copyWith({
    Object? genre = _sentinel,
    Object? mood = _sentinel,
    Object? contentType = _sentinel,
    Object? releaseYearFrom = _sentinel,
    Object? releaseYearTo = _sentinel,
    Object? isExplicit = _sentinel,
    Object? isAiCreated = _sentinel,
  }) {
    return SearchFilter(
      genre: genre == _sentinel ? this.genre : genre as String?,
      mood: mood == _sentinel ? this.mood : mood as String?,
      contentType: contentType == _sentinel
          ? this.contentType
          : contentType as AlbumType?,
      releaseYearFrom: releaseYearFrom == _sentinel
          ? this.releaseYearFrom
          : releaseYearFrom as int?,
      releaseYearTo: releaseYearTo == _sentinel
          ? this.releaseYearTo
          : releaseYearTo as int?,
      isExplicit:
          isExplicit == _sentinel ? this.isExplicit : isExplicit as bool?,
      isAiCreated:
          isAiCreated == _sentinel ? this.isAiCreated : isAiCreated as bool?,
    );
  }

  static const _sentinel = Object();
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/track.dart';
import '../models/artist.dart';
import '../models/album.dart';
import '../providers/search_provider.dart';
import '../providers/player_provider.dart';
import '../providers/library_provider.dart';
import '../services/music_service.dart';
import '../theme/theme.dart';
import '../widgets/common/track_tile.dart';
import '../widgets/common/artist_card.dart';
import '../widgets/common/album_card.dart';
import '../widgets/search/search_filter_sheet.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openFilterSheet(BuildContext context) {
    final search = context.read<SearchProvider>();
    final service = context.read<MusicService>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SearchFilterSheet(
        initialFilter: search.filter,
        genres: service.getGenres(),
        moods: service.getMoods(),
        years: service.getYears(),
        onApply: (filter) => search.applyFilter(filter),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final search = context.watch<SearchProvider>();
    final player = context.read<PlayerProvider>();
    final library = context.watch<LibraryProvider>();
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    final artists = search.results.whereType<Artist>().toList();
    final albums = search.results.whereType<Album>().toList();
    final tracks = search.results.whereType<Track>().toList();

    final hasQuery = search.query.isNotEmpty;
    final hasFilters = search.hasActiveFilters;
    final showEmptyState = !hasQuery && !hasFilters;
    final showNoResults =
        (hasQuery || hasFilters) && search.results.isEmpty;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search bar row ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingMd,
              AppTheme.spacingMd,
              AppTheme.spacingMd,
              AppTheme.spacingXs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onChanged: (v) => search.search(v),
                    decoration: InputDecoration(
                      hintText: 'Search artists, albums, songs...',
                      prefixIcon:
                          Icon(Icons.search, color: appColors.subtleText),
                      suffixIcon: search.query.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close,
                                  color: appColors.subtleText),
                              onPressed: () {
                                _controller.clear();
                                search.search('');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                // Filter button with badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Material(
                      color: hasFilters
                          ? appColors.gradient1
                              .withValues(alpha: AppTheme.opacityOverlay)
                          : colors.surfaceContainerHighest,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusSmall),
                      child: InkWell(
                        onTap: () => _openFilterSheet(context),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSmall),
                        child: Container(
                          padding: const EdgeInsets.all(AppTheme.spacingSm),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: hasFilters
                                  ? appColors.gradient1
                                  : colors.outline,
                              width: hasFilters
                                  ? AppTheme.borderSelected
                                  : AppTheme.borderDefault,
                            ),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSmall),
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            color: hasFilters
                                ? appColors.gradient1
                                : colors.onSurface,
                            size: AppTheme.iconMd,
                          ),
                        ),
                      ),
                    ),
                    if (search.activeFilterCount > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: appColors.gradient1,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${search.activeFilterCount}',
                            style: text.labelSmall?.copyWith(
                              color: colors.onPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ── Active filter chips ─────────────────────────────────────
          if (hasFilters) _ActiveFilterChips(search: search, appColors: appColors, colors: colors, text: text),

          // ── Result count summary ────────────────────────────────────
          if (!showEmptyState && !showNoResults)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd,
                vertical: AppTheme.spacingXs,
              ),
              child: Text(
                '${search.results.length} result${search.results.length == 1 ? '' : 's'}',
                style: text.labelMedium?.copyWith(color: appColors.subtleText),
              ),
            ),

          // ── Body ────────────────────────────────────────────────────
          if (showEmptyState)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search,
                        size: AppTheme.iconXl * 1.5,
                        color: colors.outlineVariant),
                    const SizedBox(height: AppTheme.spacingMd),
                    Text(
                      'Search by genre, mood, artist,\nalbum, or song title',
                      style: text.bodyMedium
                          ?.copyWith(color: appColors.subtleText),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    TextButton.icon(
                      onPressed: () => _openFilterSheet(context),
                      icon: Icon(Icons.tune_rounded,
                          size: AppTheme.iconSm, color: appColors.gradient2),
                      label: Text(
                        'Or filter by genre, mood & more',
                        style: text.labelMedium
                            ?.copyWith(color: appColors.gradient2),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (showNoResults)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_off_rounded,
                        size: AppTheme.iconXl * 1.5,
                        color: colors.outlineVariant),
                    const SizedBox(height: AppTheme.spacingMd),
                    Text(
                      'No results found',
                      style: text.bodyMedium
                          ?.copyWith(color: appColors.subtleText),
                    ),
                    if (hasFilters) ...[
                      const SizedBox(height: AppTheme.spacingSm),
                      TextButton(
                        onPressed: search.clearFilters,
                        child: Text(
                          'Clear filters',
                          style: text.labelMedium
                              ?.copyWith(color: appColors.gradient2),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView(
                children: [
                  if (artists.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingMd,
                          vertical: AppTheme.spacingSm),
                      child: Text('Artists', style: text.titleSmall),
                    ),
                    SizedBox(
                      height: 140,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingMd),
                        scrollDirection: Axis.horizontal,
                        itemCount: artists.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: AppTheme.spacingMd),
                        itemBuilder: (_, i) => ArtistCard(
                          artist: artists[i],
                          size: 100,
                          onTap: () =>
                              context.push('/artist/${artists[i].id}'),
                        ),
                      ),
                    ),
                  ],
                  if (albums.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingMd,
                          vertical: AppTheme.spacingSm),
                      child: Text('Albums & EPs', style: text.titleSmall),
                    ),
                    SizedBox(
                      height: 190,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingMd),
                        scrollDirection: Axis.horizontal,
                        itemCount: albums.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: AppTheme.spacingMd),
                        itemBuilder: (_, i) => AlbumCard(
                          album: albums[i],
                          width: 130,
                          onTap: () =>
                              context.push('/album/${albums[i].id}'),
                        ),
                      ),
                    ),
                  ],
                  if (tracks.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingMd,
                          vertical: AppTheme.spacingSm),
                      child: Text('Tracks', style: text.titleSmall),
                    ),
                    ...tracks.map((track) => TrackTile(
                          track: track,
                          isPlaying: player.currentTrack?.id == track.id,
                          isFavorite: library.isFavorite(track.id),
                          onTap: () =>
                              player.playTrack(track, queue: tracks),
                          onFavorite: () =>
                              library.toggleFavorite(track.id),
                        )),
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Active filter chips row
// ─────────────────────────────────────────────────────────────────────────────

class _ActiveFilterChips extends StatelessWidget {
  final SearchProvider search;
  final AppColorsExtension appColors;
  final ColorScheme colors;
  final TextTheme text;

  const _ActiveFilterChips({
    required this.search,
    required this.appColors,
    required this.colors,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final filter = search.filter;
    final chips = <_ChipData>[];

    if (filter.genre != null) chips.add(_ChipData('Genre: ${filter.genre}', () => search.applyFilter(filter.copyWith(genre: null))));
    if (filter.mood != null) chips.add(_ChipData('Mood: ${filter.mood}', () => search.applyFilter(filter.copyWith(mood: null))));
    if (filter.contentType != null) chips.add(_ChipData('Type: ${filter.contentType!.name[0].toUpperCase()}${filter.contentType!.name.substring(1)}', () => search.applyFilter(filter.copyWith(contentType: null))));
    if (filter.releaseYearFrom != null || filter.releaseYearTo != null) {
      final from = filter.releaseYearFrom?.toString() ?? '∞';
      final to = filter.releaseYearTo?.toString() ?? '∞';
      chips.add(_ChipData('Year: $from–$to', () => search.applyFilter(filter.copyWith(releaseYearFrom: null, releaseYearTo: null))));
    }
    if (filter.isExplicit != null) chips.add(_ChipData(filter.isExplicit! ? 'Explicit: Yes' : 'Explicit: No', () => search.applyFilter(filter.copyWith(isExplicit: null))));
    if (filter.isAiCreated != null) chips.add(_ChipData(filter.isAiCreated! ? 'AI Music: Yes' : 'AI Music: No', () => search.applyFilter(filter.copyWith(isAiCreated: null))));

    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppTheme.spacingXs),
        itemBuilder: (_, i) => _ActiveChip(
          data: chips[i],
          colors: colors,
          appColors: appColors,
          text: text,
        ),
      ),
    );
  }
}

class _ChipData {
  final String label;
  final VoidCallback onRemove;
  const _ChipData(this.label, this.onRemove);
}

class _ActiveChip extends StatelessWidget {
  final _ChipData data;
  final ColorScheme colors;
  final AppColorsExtension appColors;
  final TextTheme text;

  const _ActiveChip({
    required this.data,
    required this.colors,
    required this.appColors,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: AppTheme.spacingXxs,
      ),
      decoration: BoxDecoration(
        color: appColors.gradient1.withValues(alpha: AppTheme.opacityOverlay),
        border: Border.all(
            color: appColors.gradient1, width: AppTheme.borderDefault),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            data.label,
            style: text.labelSmall?.copyWith(
              color: appColors.gradient1,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppTheme.spacingXxs),
          GestureDetector(
            onTap: data.onRemove,
            child: Icon(Icons.close_rounded,
                size: 14, color: appColors.gradient1),
          ),
        ],
      ),
    );
  }
}


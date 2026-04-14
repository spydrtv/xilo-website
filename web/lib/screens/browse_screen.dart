import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/music_service.dart';
import '../models/artist.dart';
import '../theme/theme.dart';
import '../widgets/common/album_card.dart';
import '../widgets/common/artist_card.dart';
import '../widgets/common/section_header.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  final Set<String> _selectedGenres = {};
  final Set<String> _selectedMoods = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasFilters =>
      _query.isNotEmpty || _selectedGenres.isNotEmpty || _selectedMoods.isNotEmpty;

  void _clearAll() {
    setState(() {
      _query = '';
      _searchController.clear();
      _selectedGenres.clear();
      _selectedMoods.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    final service = context.read<MusicService>();

    final genres = service.getGenres();
    final moods = service.getMoods();
    final allArtists = service.getArtists();
    final allAlbums = service.getAllAlbums();

    // Featured artists: sort by featuredScore descending, take top 4
    final featured = [...allArtists]
      ..sort((a, b) => b.featuredScore.compareTo(a.featuredScore));
    final featuredArtists = featured.take(4).toList();

    // Apply combined genre + mood + search filters
    final filteredAlbums = allAlbums.where((album) {
      final matchesGenre = _selectedGenres.isEmpty ||
          _selectedGenres.contains(album.genre);
      final matchesSearch = _query.isEmpty ||
          album.title.toLowerCase().contains(_query.toLowerCase()) ||
          album.artistName.toLowerCase().contains(_query.toLowerCase());
      return matchesGenre && matchesSearch;
    }).toList();

    final filteredArtists = allArtists.where((artist) {
      final matchesGenre = _selectedGenres.isEmpty ||
          artist.genres.any((g) => _selectedGenres.contains(g));
      final matchesMood = _selectedMoods.isEmpty; // moods are track-level
      final matchesSearch = _query.isEmpty ||
          artist.name.toLowerCase().contains(_query.toLowerCase());
      return matchesGenre && matchesMood && matchesSearch;
    }).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: Text(
              'Browse',
              style: theme.textTheme.titleLarge,
            ),
            actions: [
              if (_hasFilters)
                TextButton(
                  onPressed: _clearAll,
                  child: Text(
                    'Clear All',
                    style: TextStyle(color: colors.gradient2),
                  ),
                ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingMd,
                  0,
                  AppTheme.spacingMd,
                  AppTheme.spacingSm,
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Artists, songs, albums…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () =>
                                setState(() {
                                  _query = '';
                                  _searchController.clear();
                                }),
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),

          // ── Genre chips ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingMd,
                AppTheme.spacingMd,
                AppTheme.spacingMd,
                AppTheme.spacingSm,
              ),
              child: Text('Genres', style: theme.textTheme.titleSmall),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                ),
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppTheme.spacingSm),
                itemCount: genres.length,
                itemBuilder: (context, i) {
                  final g = genres[i];
                  final selected = _selectedGenres.contains(g);
                  return _FilterChip(
                    label: g,
                    selected: selected,
                    onTap: () => setState(() => selected
                        ? _selectedGenres.remove(g)
                        : _selectedGenres.add(g)),
                  );
                },
              ),
            ),
          ),

          // ── Mood chips ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingMd,
                AppTheme.spacingMd,
                AppTheme.spacingMd,
                AppTheme.spacingSm,
              ),
              child: Text('Moods', style: theme.textTheme.titleSmall),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                ),
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppTheme.spacingSm),
                itemCount: moods.length,
                itemBuilder: (context, i) {
                  final m = moods[i];
                  final selected = _selectedMoods.contains(m);
                  return _FilterChip(
                    label: m,
                    selected: selected,
                    onTap: () => setState(() => selected
                        ? _selectedMoods.remove(m)
                        : _selectedMoods.add(m)),
                    useSecondary: true,
                  );
                },
              ),
            ),
          ),

          // ── Active filter summary ────────────────────────────────
          if (_hasFilters)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                  vertical: AppTheme.spacingSm,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMd,
                    vertical: AppTheme.spacingSm,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer
                        .withOpacity(AppTheme.opacitySubtle),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(
                      color: theme.colorScheme.primary
                          .withOpacity(AppTheme.opacitySubtle),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.filter_list_rounded,
                        size: AppTheme.iconSm,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: AppTheme.spacingXs),
                      Expanded(
                        child: Text(
                          _buildFilterSummary(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: AppTheme.spacingMd)),

          // ── Featured Artists (only when no filters active) ───────
          if (!_hasFilters) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                ),
                child: SectionHeader(
                  title: 'Featured Artists',
                  subtitle: 'Ranked by streams & releases',
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 180,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMd,
                  ),
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AppTheme.spacingMd),
                  itemCount: featuredArtists.length,
                  itemBuilder: (context, i) {
                    return _FeaturedArtistCard(
                      artist: featuredArtists[i],
                      rank: i + 1,
                      onTap: () =>
                          context.push('/artist/${featuredArtists[i].id}'),
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: AppTheme.spacingLg),
            ),
          ],

          // ── Albums/EPs/Singles ───────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd,
              ),
              child: SectionHeader(
                title: _hasFilters ? 'Results' : 'Albums, EPs & Singles',
                subtitle: _hasFilters
                    ? '${filteredAlbums.length} releases found'
                    : null,
              ),
            ),
          ),
          filteredAlbums.isEmpty
              ? SliverToBoxAdapter(
                  child: _EmptyState(
                    message: 'No releases match your filters.',
                    onClear: _clearAll,
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMd,
                  ),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 180,
                      mainAxisSpacing: AppTheme.spacingMd,
                      crossAxisSpacing: AppTheme.spacingMd,
                      childAspectRatio: 0.72,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => AlbumCard(
                        album: filteredAlbums[i],
                        onTap: () =>
                            context.push('/album/${filteredAlbums[i].id}'),
                      ),
                      childCount: filteredAlbums.length,
                    ),
                  ),
                ),

          // ── Artists ──────────────────────────────────────────────
          if (_hasFilters) ...[
            const SliverToBoxAdapter(
              child: SizedBox(height: AppTheme.spacingLg),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                ),
                child: SectionHeader(
                  title: 'Artists',
                  subtitle: '${filteredArtists.length} found',
                ),
              ),
            ),
            filteredArtists.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingLg),
                      child: Center(
                        child: Text(
                          'No artists match your filters.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.subtleText,
                          ),
                        ),
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingMd,
                          vertical: AppTheme.spacingXs,
                        ),
                        child: ArtistCard(
                          artist: filteredArtists[i],
                          onTap: () => context
                              .push('/artist/${filteredArtists[i].id}'),
                        ),
                      ),
                      childCount: filteredArtists.length,
                    ),
                  ),
          ],

          const SliverToBoxAdapter(
            child: SizedBox(height: AppTheme.spacingXxl),
          ),
        ],
      ),
    );
  }

  String _buildFilterSummary() {
    final parts = <String>[];
    if (_query.isNotEmpty) parts.add('"$_query"');
    if (_selectedGenres.isNotEmpty) {
      parts.add(_selectedGenres.join(', '));
    }
    if (_selectedMoods.isNotEmpty) {
      parts.add(_selectedMoods.join(', '));
    }
    return 'Filtering by: ${parts.join(' · ')}';
  }
}

// ── Private sub-widgets ───────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool useSecondary;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.useSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    final activeColor = useSecondary ? colors.gradient2 : colors.gradient1;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingXs,
        ),
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withOpacity(0.18)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          border: Border.all(
            color: selected ? activeColor : theme.colorScheme.outlineVariant,
            width: selected ? AppTheme.borderSelected : AppTheme.borderDefault,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: selected ? activeColor : theme.colorScheme.onSurface,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _FeaturedArtistCard extends StatelessWidget {
  final Artist artist;
  final int rank;
  final VoidCallback onTap;

  const _FeaturedArtistCard({
    required this.artist,
    required this.rank,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 130,
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [colors.gradient1, colors.gradient2],
                    ),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      artist.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(
                          artist.name[0],
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: rank == 1
                          ? colors.warning
                          : rank == 2
                              ? colors.subtleText
                              : colors.gradient1,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: AppTheme.borderSelected,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '#$rank',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
                ),
                if (artist.isAiCreator)
                  Positioned(
                    bottom: 0,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.spacingXxs),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        size: AppTheme.iconSm,
                        color: theme.colorScheme.onSecondary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              artist.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXxs),
            Text(
              artist.genres.take(1).join(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.subtleText,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final VoidCallback onClear;

  const _EmptyState({required this.message, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingXxl),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: AppTheme.iconXl,
            color: colors.subtleText,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.subtleText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          TextButton(
            onPressed: onClear,
            child: const Text('Clear filters'),
          ),
        ],
      ),
    );
  }
}

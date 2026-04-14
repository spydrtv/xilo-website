import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/album.dart';
import '../models/track.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../services/music_service.dart';
import '../theme/theme.dart';
import '../widgets/common/add_to_playlist_sheet.dart';

class AlbumDetailScreen extends StatelessWidget {
  final String albumId;
  const AlbumDetailScreen({super.key, required this.albumId});

  @override
  Widget build(BuildContext context) {
    final service = context.read<MusicService>();
    final album = service.getAlbumById(albumId);
    final tracks = service.getTracksByAlbum(albumId);

    if (album == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Album not found')),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _HeroAppBar(album: album, tracks: tracks),
          _CreditsAndActions(album: album, tracks: tracks),
          _TrackList(album: album, tracks: tracks),
          const SliverToBoxAdapter(
            child: SizedBox(height: AppTheme.spacingXxl),
          ),
        ],
      ),
    );
  }
}

// ── Hero AppBar with large artwork ───────────────────────────────────────────

class _HeroAppBar extends StatelessWidget {
  final Album album;
  final List<Track> tracks;

  const _HeroAppBar({required this.album, required this.tracks});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      stretch: true,
      backgroundColor: theme.colorScheme.surface,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(AppTheme.spacingXs),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(AppTheme.opacityOverlay),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_rounded),
        ),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: album.artUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              errorWidget: (_, __, ___) => Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.album_rounded,
                  size: AppTheme.iconXl,
                  color: colors.subtleText,
                ),
              ),
            ),
            // Dark gradient for text readability
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    theme.colorScheme.surface.withOpacity(0.5),
                    theme.colorScheme.surface,
                  ],
                  stops: const [0.4, 0.75, 1.0],
                ),
              ),
            ),
            // Album info overlay at bottom
            Positioned(
              left: AppTheme.spacingMd,
              right: AppTheme.spacingMd,
              bottom: AppTheme.spacingMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Type badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingSm,
                      vertical: AppTheme.spacingXxs,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colors.gradient1, colors.gradient2],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    ),
                    child: Text(
                      album.typeLabel.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  Text(
                    album.title,
                    style: theme.textTheme.headlineMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppTheme.spacingXxs),
                  GestureDetector(
                    onTap: () => context.push('/artist/${album.artistId}'),
                    child: Text(
                      album.artistName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.gradient2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXxs),
                  Row(
                    children: [
                      Text(
                        '${album.year}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.subtleText,
                        ),
                      ),
                      Text(
                        ' · ${tracks.length} tracks',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.subtleText,
                        ),
                      ),
                      if (album.isExplicit) ...[
                        const SizedBox(width: AppTheme.spacingXs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingXxs + 2,
                            vertical: AppTheme.spacingXxs,
                          ),
                          decoration: BoxDecoration(
                            color: colors.subtleText,
                            borderRadius: BorderRadius.circular(AppTheme.spacingXxs),
                          ),
                          child: Text(
                            'E',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.surface,
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Credits notice + Play All + Bulk Add ─────────────────────────────────────

class _CreditsAndActions extends StatelessWidget {
  final Album album;
  final List<Track> tracks;

  const _CreditsAndActions({required this.album, required this.tracks});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    final player = context.read<PlayerProvider>();

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Credits notice — directly under artwork
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd,
                vertical: AppTheme.spacingSm,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.store_rounded,
                    size: AppTheme.iconSm,
                    color: colors.subtleText,
                  ),
                  const SizedBox(width: AppTheme.spacingXs),
                  Expanded(
                    child: Text(
                      'Music available for licensing and purchase at xilo-music.com.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.subtleText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // Creator credits
            if (album.credits.isNotEmpty) ...[
              Text(
                album.credits,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.subtleText,
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
            ],

            // Play All + Add All buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: tracks.isEmpty
                        ? null
                        : () => player.playAlbum(album.id),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Play All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      minimumSize: const Size(0, AppTheme.buttonHeight),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: tracks.isEmpty
                        ? null
                        : () => _bulkAddToPlaylist(context, tracks),
                    icon: const Icon(Icons.playlist_add_rounded),
                    label: const Text('Add All'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            const Divider(height: 1),
          ],
        ),
      ),
    );
  }

  Future<void> _bulkAddToPlaylist(
      BuildContext context, List<Track> tracks) async {
    final library = context.read<LibraryProvider>();
    final playlists = library.playlists;

    if (playlists.isEmpty) {
      // Create a new playlist and add all tracks
      final controller = TextEditingController();
      final name = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('New Playlist'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Playlist name…'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Create'),
            ),
          ],
        ),
      );
      if (name != null && name.isNotEmpty) {
        library.createPlaylist(name);
        final pl = library.playlists.last;
        for (final t in tracks) {
          library.addTrackToPlaylist(pl.id, t.id);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${tracks.length} tracks added to $name'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
      return;
    }

    // Show playlist picker
    await showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final ctxTheme = Theme.of(ctx);
        return ChangeNotifierProvider.value(
        value: context.read<LibraryProvider>(),
        child: Container(
          decoration: BoxDecoration(
            color: ctxTheme.colorScheme.surfaceContainerHigh,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusXl),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppTheme.spacingMd),
              Text('Add ${tracks.length} tracks to…',
                  style: ctxTheme.textTheme.titleSmall),
              const SizedBox(height: AppTheme.spacingSm),
              ...playlists.map(
                (pl) => ListTile(
                  leading: const Icon(Icons.queue_music_rounded),
                  title: Text(pl.name),
                  onTap: () {
                    for (final t in tracks) {
                      library.addTrackToPlaylist(pl.id, t.id);
                    }
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${tracks.length} tracks added to ${pl.name}',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
            ],
          ),
        ),
      );
      },
    );
  }
}

// ── Track list ────────────────────────────────────────────────────────────────

class _TrackList extends StatelessWidget {
  final Album album;
  final List<Track> tracks;

  const _TrackList({required this.album, required this.tracks});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) => _TrackRow(track: tracks[i], index: i + 1),
        childCount: tracks.length,
      ),
    );
  }
}

class _TrackRow extends StatelessWidget {
  final Track track;
  final int index;

  const _TrackRow({required this.track, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    final player = context.watch<PlayerProvider>();
    final library = context.watch<LibraryProvider>();
    final isPlaying = player.currentTrack?.id == track.id && player.isPlaying;
    final isFav = library.isFavorite(track.id);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingXs,
      ),
      leading: SizedBox(
        width: 32,
        child: Center(
          child: isPlaying
              ? Icon(
                  Icons.equalizer_rounded,
                  color: colors.gradient1,
                  size: AppTheme.iconMd,
                )
              : Text(
                  '$index',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.subtleText,
                  ),
                ),
        ),
      ),
      title: Text(
        track.title,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isPlaying ? colors.gradient2 : theme.colorScheme.onSurface,
          fontWeight: isPlaying ? FontWeight.w700 : FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          if (track.isAiCreated) ...[
            Icon(
              Icons.auto_awesome_rounded,
              size: AppTheme.iconSm,
              color: theme.colorScheme.secondary,
            ),
            const SizedBox(width: AppTheme.spacingXxs),
          ],
          if (track.isExplicit) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingXxs + 1,
                vertical: AppTheme.spacingXxs,
              ),
              decoration: BoxDecoration(
                color: colors.subtleText,
                borderRadius: BorderRadius.circular(AppTheme.spacingXxs),
              ),
              child: Text(
                'E',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.surface,
                  fontWeight: FontWeight.bold,
                  fontSize: 8,
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingXxs),
          ],
          Text(
            track.durationString,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.subtleText,
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play button
          IconButton(
            icon: Icon(
              isPlaying
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_filled_rounded,
              color: isPlaying ? colors.gradient1 : colors.subtleText,
              size: AppTheme.iconLg,
            ),
            onPressed: () {
              final p = context.read<PlayerProvider>();
              if (isPlaying) {
                p.togglePlayPause();
              } else {
                p.playTrack(track);
                context.push('/now-playing');
              }
            },
          ),
          // Add to playlist
          IconButton(
            icon: Icon(
              Icons.playlist_add_rounded,
              color: colors.subtleText,
              size: AppTheme.iconMd,
            ),
            onPressed: () => AddToPlaylistSheet.show(
              context,
              trackId: track.id,
              trackTitle: track.title,
            ),
          ),
          // Favorite
          IconButton(
            icon: Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFav ? colors.danger : colors.subtleText,
              size: AppTheme.iconMd,
            ),
            onPressed: () =>
                context.read<LibraryProvider>().toggleFavorite(track.id),
          ),
        ],
      ),
    );
  }
}

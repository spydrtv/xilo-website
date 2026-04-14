import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/music_service.dart';
import '../providers/player_provider.dart';
import '../providers/library_provider.dart';
import '../theme/theme.dart';
import '../widgets/common/track_tile.dart';
import '../widgets/common/album_card.dart';
import '../widgets/common/section_header.dart';

class ArtistDetailScreen extends StatelessWidget {
  final String artistId;
  const ArtistDetailScreen({super.key, required this.artistId});

  @override
  Widget build(BuildContext context) {
    final musicService = context.read<MusicService>();
    final player = context.read<PlayerProvider>();
    final library = context.watch<LibraryProvider>();
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    final artist = musicService.getArtistById(artistId);
    if (artist == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Artist not found', style: text.bodyLarge)),
      );
    }

    final tracks = musicService.getTracksByArtist(artistId);
    final albums = musicService.getAlbumsByArtist(artistId);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: artist.imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(color: colors.surfaceContainerHighest),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          colors.surface.withOpacity(AppTheme.opacityOverlay),
                          colors.surface,
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: AppTheme.spacingMd,
                    left: AppTheme.spacingMd,
                    right: AppTheme.spacingMd,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (artist.isAiCreator)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSm, vertical: AppTheme.spacingXs),
                            margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                            decoration: BoxDecoration(
                              color: colors.secondary.withOpacity(AppTheme.opacitySubtle * 2),
                              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.auto_awesome, size: AppTheme.iconSm, color: colors.secondary),
                                const SizedBox(width: AppTheme.spacingXs),
                                Text('AI Creator', style: text.labelSmall?.copyWith(color: colors.secondary)),
                              ],
                            ),
                          ),
                        Text(artist.name, style: text.headlineMedium),
                        const SizedBox(height: AppTheme.spacingXs),
                        Text(
                          '${_formatCount(artist.followerCount)} followers',
                          style: text.bodySmall?.copyWith(color: appColors.subtleText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (artist.bio.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Text(
                  artist.bio,
                  style: text.bodyMedium?.copyWith(color: appColors.subtleText),
                ),
              ),
            ),
          if (albums.isNotEmpty) ...[
            const SliverToBoxAdapter(child: SectionHeader(title: 'Discography')),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 210,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                  scrollDirection: Axis.horizontal,
                  itemCount: albums.length,
                  separatorBuilder: (_, __) => const SizedBox(width: AppTheme.spacingMd),
                  itemBuilder: (_, i) => AlbumCard(
                    album: albums[i],
                    onTap: () => context.push('/album/${albums[i].id}'),
                  ),
                ),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SectionHeader(title: 'Tracks')),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) {
                final track = tracks[i];
                return TrackTile(
                  track: track,
                  index: i + 1,
                  isPlaying: player.currentTrack?.id == track.id,
                  isFavorite: library.isFavorite(track.id),
                  onTap: () => player.playTrack(track, queue: tracks),
                  onFavorite: () => library.toggleFavorite(track.id),
                );
              },
              childCount: tracks.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}

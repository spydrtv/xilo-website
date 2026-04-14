import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/music_service.dart';
import '../providers/player_provider.dart';
import '../providers/library_provider.dart';
import '../theme/theme.dart';
import '../widgets/common/xilo_logo.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/album_card.dart';
import '../widgets/common/artist_card.dart';
import '../widgets/common/track_tile.dart';
import '../widgets/common/hero_slider.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final musicService = context.read<MusicService>();
    final player = context.read<PlayerProvider>();
    final library = context.watch<LibraryProvider>();

    final featured = musicService.getFeaturedTracks();
    final newReleases = musicService.getNewReleases();
    final trending = musicService.getTrendingArtists();

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          title: XiloLogo(onTap: () => context.go('/')),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded),
              onPressed: () {},
            ),
            const SizedBox(width: AppTheme.spacingSm),
          ],
        ),
        const SliverToBoxAdapter(
          child: HeroSlider(),
        ),
        SliverToBoxAdapter(
          child: SectionHeader(title: 'New Releases', onSeeAll: () {}),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 210,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
              scrollDirection: Axis.horizontal,
              itemCount: newReleases.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppTheme.spacingMd),
              itemBuilder: (_, i) => AlbumCard(
                album: newReleases[i],
                onTap: () => context.push('/album/${newReleases[i].id}'),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppTheme.spacingMd)),
        SliverToBoxAdapter(
          child: SectionHeader(title: 'Trending Artists', onSeeAll: () {}),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 160,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
              scrollDirection: Axis.horizontal,
              itemCount: trending.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppTheme.spacingMd),
              itemBuilder: (_, i) => ArtistCard(
                artist: trending[i],
                onTap: () => context.push('/artist/${trending[i].id}'),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppTheme.spacingSm)),
        SliverToBoxAdapter(
          child: SectionHeader(title: 'For You', onSeeAll: () {}),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) {
              final track = featured[i];
              return TrackTile(
                track: track,
                index: i + 1,
                isPlaying: player.currentTrack?.id == track.id,
                isFavorite: library.isFavorite(track.id),
                onTap: () => player.playTrack(track, queue: featured),
                onFavorite: () => library.toggleFavorite(track.id),
              );
            },
            childCount: featured.length,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}



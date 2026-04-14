import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/music_service.dart';
import '../providers/player_provider.dart';
import '../providers/library_provider.dart';
import '../theme/theme.dart';
import '../widgets/common/track_tile.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppTheme.spacingMd, AppTheme.spacingMd, AppTheme.spacingMd, 0),
            child: Text('Your Library', style: text.titleLarge),
          ),
          TabBar(
            controller: _tabController,
            labelColor: colors.primary,
            unselectedLabelColor: appColors.subtleText,
            indicatorColor: colors.primary,
            tabs: const [
              Tab(text: 'Favorites'),
              Tab(text: 'Playlists'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _FavoritesTab(),
                _PlaylistsTab(),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            dense: true,
            leading: Icon(Icons.privacy_tip_outlined,
                size: AppTheme.iconMd,
                color: appColors.subtleText),
            title: Text(
              'Privacy Policy',
              style: text.bodySmall?.copyWith(color: appColors.subtleText),
            ),
            trailing: Icon(Icons.chevron_right,
                size: AppTheme.iconMd,
                color: appColors.subtleText),
            onTap: () => context.push('/privacy-policy'),
          ),
          ListTile(
            dense: true,
            leading: Icon(Icons.gavel_outlined,
                size: AppTheme.iconMd,
                color: appColors.subtleText),
            title: Text(
              'Terms of Service',
              style: text.bodySmall?.copyWith(color: appColors.subtleText),
            ),
            trailing: Icon(Icons.chevron_right,
                size: AppTheme.iconMd,
                color: appColors.subtleText),
            onTap: () => context.push('/terms-of-service'),
          ),
        ],
      ),
    );
  }
}

class _FavoritesTab extends StatelessWidget {
  const _FavoritesTab();

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final musicService = context.read<MusicService>();
    final player = context.read<PlayerProvider>();
    final text = Theme.of(context).textTheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    final favIds = library.favoriteIds.toList();
    final favTracks = favIds
        .map((id) => musicService.getTrackById(id))
        .where((t) => t != null)
        .toList();

    if (favTracks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border, size: AppTheme.iconXl * 1.5, color: appColors.subtleText),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'No favorites yet',
              style: text.bodyMedium?.copyWith(color: appColors.subtleText),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              'Tap the heart on any track to save it',
              style: text.bodySmall?.copyWith(color: appColors.subtleText),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: favTracks.length,
      itemBuilder: (_, i) {
        final track = favTracks[i]!;
        return TrackTile(
          track: track,
          isPlaying: player.currentTrack?.id == track.id,
          isFavorite: true,
          onTap: () => player.playTrack(track, queue: favTracks.cast()),
          onFavorite: () => library.toggleFavorite(track.id),
        );
      },
    );
  }
}

class _PlaylistsTab extends StatelessWidget {
  const _PlaylistsTab();

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final playlists = library.playlists;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: OutlinedButton.icon(
            onPressed: () => _showCreatePlaylist(context),
            icon: const Icon(Icons.add),
            label: const Text('New Playlist'),
          ),
        ),
        if (playlists.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                'Create your first playlist',
                style: text.bodyMedium?.copyWith(color: appColors.subtleText),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: playlists.length,
              itemBuilder: (_, i) {
                final pl = playlists[i];
                return ListTile(
                  leading: Container(
                    width: AppTheme.albumArtSmall,
                    height: AppTheme.albumArtSmall,
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Icon(Icons.queue_music, color: appColors.subtleText),
                  ),
                  title: Text(pl.name, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${pl.trackIds.length} tracks',
                    style: text.bodySmall?.copyWith(color: appColors.subtleText),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline, color: appColors.subtleText),
                    onPressed: () => library.deletePlaylist(pl.id),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  void _showCreatePlaylist(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Playlist name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<LibraryProvider>().createPlaylist(controller.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

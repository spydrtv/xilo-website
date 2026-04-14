import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/track.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../theme/theme.dart';
import '../widgets/common/add_to_playlist_sheet.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    final player = context.watch<PlayerProvider>();
    final library = context.watch<LibraryProvider>();
    final track = player.currentTrack;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    if (track == null) {
      return Scaffold(
        appBar: AppBar(leading: const CloseButton()),
        body: const Center(child: Text('Nothing playing')),
      );
    }

    final progress = track.duration.inSeconds > 0
        ? player.position.inSeconds / track.duration.inSeconds
        : 0.0;
    final isFav = library.isFavorite(track.id);

    return Scaffold(
      backgroundColor: colors.playerBg,
      body: Column(
        children: [
          // ── Top bar ──────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingSm,
                vertical: AppTheme.spacingXs,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        size: AppTheme.iconLg),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'NOW PLAYING',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.subtleText,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingXxs),
                        Text(
                          track.albumTitle ?? track.artistName,
                          style: theme.textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.playlist_add_rounded,
                      size: AppTheme.iconMd,
                      color: colors.subtleText,
                    ),
                    onPressed: () => AddToPlaylistSheet.show(
                      context,
                      trackId: track.id,
                      trackTitle: track.title,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Tabs: Player / Lyrics ─────────────────────────────────
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Player'),
              Tab(text: 'Lyrics'),
            ],
            indicatorColor: colors.gradient1,
            labelColor: colors.gradient1,
            unselectedLabelColor: colors.subtleText,
            indicatorSize: TabBarIndicatorSize.label,
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // ── Player tab ────────────────────────────────────
                SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: AppTheme.spacingLg),
                      _AlbumArt(artUrl: track.artUrl),
                      const SizedBox(height: AppTheme.spacingLg),
                      _TrackInfo(
                        track: track,
                        isFav: isFav,
                        onFavorite: () =>
                            library.toggleFavorite(track.id),
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      _ProgressBar(
                        progress: progress.clamp(0.0, 1.0),
                        position: player.position,
                        duration: track.duration,
                        onSeek: (d) => player.seek(d),
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      _Controls(player: player),
                      const SizedBox(height: AppTheme.spacingLg),
                      // Credits notice
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingXl,
                        ),
                        child: Text(
                          'Music available for licensing and purchase at xilo-music.com.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.subtleText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXl),
                    ],
                  ),
                ),

                // ── Lyrics tab ────────────────────────────────────
                _LyricsView(track: track),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Album Art ────────────────────────────────────────────────────────────────

class _AlbumArt extends StatelessWidget {
  final String artUrl;
  const _AlbumArt({required this.artUrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: colors.gradient1.withOpacity(0.3),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: AspectRatio(
          aspectRatio: 1,
          child: CachedNetworkImage(
            imageUrl: artUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            errorWidget: (_, __, ___) => Container(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.music_note_rounded,
                size: AppTheme.iconXl,
                color: colors.subtleText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Track Info ───────────────────────────────────────────────────────────────

class _TrackInfo extends StatelessWidget {
  final Track track;
  final bool isFav;
  final VoidCallback onFavorite;

  const _TrackInfo({
    required this.track,
    required this.isFav,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (track.isAiCreated) ...[
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: AppTheme.iconSm,
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: AppTheme.spacingXs),
                    ],
                    Expanded(
                      child: Text(
                        track.title,
                        style: theme.textTheme.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingXxs),
                Text(
                  track.artistName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.gradient2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFav ? colors.danger : colors.subtleText,
              size: AppTheme.iconLg,
            ),
            onPressed: onFavorite,
          ),
        ],
      ),
    );
  }
}

// ── Progress Bar ─────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final double progress;
  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;

  const _ProgressBar({
    required this.progress,
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: colors.gradient1,
              inactiveTrackColor:
                  theme.colorScheme.outline.withOpacity(AppTheme.opacitySubtle),
              thumbColor: colors.gradient1,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: progress,
              onChanged: (v) =>
                  onSeek(Duration(seconds: (v * duration.inSeconds).round())),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingXs,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _fmt(position),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.subtleText,
                  ),
                ),
                Text(
                  _fmt(duration),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.subtleText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Controls ─────────────────────────────────────────────────────────────────

class _Controls extends StatelessWidget {
  final PlayerProvider player;
  const _Controls({required this.player});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Shuffle
          IconButton(
            icon: Icon(
              Icons.shuffle_rounded,
              size: AppTheme.iconMd,
              color:
                  player.shuffle ? colors.gradient1 : colors.subtleText,
            ),
            onPressed: player.toggleShuffle,
          ),
          // Skip previous
          IconButton(
            icon: Icon(
              Icons.skip_previous_rounded,
              size: AppTheme.iconLg,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: player.skipPrevious,
          ),
          // Play / Pause
          GestureDetector(
            onTap: player.togglePlayPause,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors.gradient1, colors.gradient2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors.gradient1.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                player.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                size: AppTheme.iconXl,
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
          // Skip next
          IconButton(
            icon: Icon(
              Icons.skip_next_rounded,
              size: AppTheme.iconLg,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: player.skipNext,
          ),
          // Repeat
          IconButton(
            icon: Icon(
              Icons.repeat_rounded,
              size: AppTheme.iconMd,
              color:
                  player.repeat ? colors.gradient1 : colors.subtleText,
            ),
            onPressed: player.toggleRepeat,
          ),
        ],
      ),
    );
  }
}

// ── Lyrics View ───────────────────────────────────────────────────────────────

class _LyricsView extends StatelessWidget {
  final Track track;
  const _LyricsView({required this.track});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    if (track.lyrics.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lyrics_outlined,
              size: AppTheme.iconXl,
              color: colors.subtleText,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'Lyrics not available',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.subtleText,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              'Creators can add lyrics when uploading.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.subtleText,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingXl),
      child: Text(
        track.lyrics,
        style: theme.textTheme.bodyLarge?.copyWith(
          height: 2.0,
          color: theme.colorScheme.onSurface,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

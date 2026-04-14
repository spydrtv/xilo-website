import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/player_provider.dart';
import '../../theme/theme.dart';

class MiniPlayer extends StatelessWidget {
  final VoidCallback onTap;
  const MiniPlayer({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final track = player.currentTrack;

    if (track == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    final progress = track.duration.inSeconds > 0
        ? player.position.inSeconds / track.duration.inSeconds
        : 0.0;

    return GestureDetector(
      onTap: () => context.push('/now-playing'),
      onVerticalDragEnd: (details) {
        // Swipe up to open full player
        if (details.primaryVelocity != null &&
            details.primaryVelocity! < -200) {
          context.push('/now-playing');
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Swipe-up affordance arrow ────────────────────────────
          Container(
            width: double.infinity,
            height: 20,
            alignment: Alignment.center,
            child: Icon(
              Icons.keyboard_arrow_up_rounded,
              color: colors.subtleText,
              size: AppTheme.iconMd,
            ),
          ),

          // ── Mini player bar ───────────────────────────────────────
          Container(
            height: AppTheme.miniPlayerHeight,
            decoration: BoxDecoration(
              color: colors.playerBg,
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                  width: AppTheme.borderDefault,
                ),
              ),
            ),
            child: Column(
              children: [
                // Progress line at very top
                LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: theme.colorScheme.outlineVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.gradient1),
                  minHeight: 2,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMd,
                    ),
                    child: Row(
                      children: [
                        // Artwork
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSmall),
                          child: CachedNetworkImage(
                            imageUrl: track.artUrl,
                            width: AppTheme.albumArtSmall,
                            height: AppTheme.albumArtSmall,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.music_note_rounded,
                                size: AppTheme.iconMd,
                                color: colors.subtleText,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingMd),

                        // Track info
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track.title,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                track.artistName,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.subtleText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Skip previous
                        IconButton(
                          icon: Icon(
                            Icons.skip_previous_rounded,
                            size: AppTheme.iconMd,
                            color: theme.colorScheme.onSurface,
                          ),
                          onPressed: player.skipPrevious,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                        ),

                        // Play / Pause
                        IconButton(
                          icon: Icon(
                            player.isPlaying
                                ? Icons.pause_circle_filled_rounded
                                : Icons.play_circle_filled_rounded,
                            size: AppTheme.iconLg,
                            color: colors.gradient1,
                          ),
                          onPressed: player.togglePlayPause,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                        ),

                        // Skip next
                        IconButton(
                          icon: Icon(
                            Icons.skip_next_rounded,
                            size: AppTheme.iconMd,
                            color: theme.colorScheme.onSurface,
                          ),
                          onPressed: player.skipNext,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                        ),
                      ],
                    ),
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

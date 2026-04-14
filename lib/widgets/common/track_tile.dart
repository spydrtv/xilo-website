import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/track.dart';
import '../../theme/theme.dart';

class TrackTile extends StatelessWidget {
  final Track track;
  final int? index;
  final bool isPlaying;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback? onFavorite;

  const TrackTile({
    super.key,
    required this.track,
    this.index,
    this.isPlaying = false,
    this.isFavorite = false,
    required this.onTap,
    this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMd,
            vertical: AppTheme.spacingSm,
          ),
          child: Row(
            children: [
              if (index != null) ...[
                SizedBox(
                  width: AppTheme.spacingLg,
                  child: Text(
                    '${index!}',
                    style: text.bodySmall?.copyWith(color: appColors.subtleText),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
              ],
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.spacingXs),
                child: CachedNetworkImage(
                  imageUrl: track.artUrl,
                  width: AppTheme.albumArtSmall,
                  height: AppTheme.albumArtSmall,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: colors.surfaceContainerHighest,
                    child: Icon(Icons.music_note, color: appColors.subtleText, size: AppTheme.iconMd),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: colors.surfaceContainerHighest,
                    child: Icon(Icons.music_note, color: appColors.subtleText, size: AppTheme.iconMd),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      style: text.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isPlaying ? colors.primary : colors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTheme.spacingXs / 2),
                    Row(
                      children: [
                        if (track.isAiCreated) ...[
                          Icon(Icons.auto_awesome, size: AppTheme.iconSm - 2, color: colors.secondary),
                          const SizedBox(width: AppTheme.spacingXs),
                        ],
                        Expanded(
                          child: Text(
                            track.artistName,
                            style: text.bodySmall?.copyWith(color: appColors.subtleText),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                track.durationString,
                style: text.bodySmall?.copyWith(color: appColors.subtleText),
              ),
              if (onFavorite != null) ...[
                const SizedBox(width: AppTheme.spacingXs),
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? colors.primary : appColors.subtleText,
                    size: AppTheme.iconSm + 4,
                  ),
                  onPressed: onFavorite,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

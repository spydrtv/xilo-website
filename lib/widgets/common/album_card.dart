import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/album.dart';
import '../../theme/theme.dart';

class AlbumCard extends StatelessWidget {
  final Album album;
  final VoidCallback onTap;
  final double width;

  const AlbumCard({
    super.key,
    required this.album,
    required this.onTap,
    this.width = 150,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              child: CachedNetworkImage(
                imageUrl: album.artUrl,
                width: width,
                height: width,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: width,
                  height: width,
                  color: colors.surfaceContainerHighest,
                  child: Icon(Icons.album, color: appColors.subtleText, size: AppTheme.iconXl),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: width,
                  height: width,
                  color: colors.surfaceContainerHighest,
                  child: Icon(Icons.album, color: appColors.subtleText, size: AppTheme.iconXl),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              album.title,
              style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppTheme.spacingXs / 2),
            Text(
              '${album.artistName} · ${album.typeLabel}',
              style: text.bodySmall?.copyWith(color: appColors.subtleText),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

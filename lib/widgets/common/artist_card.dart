import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/artist.dart';
import '../../theme/theme.dart';

class ArtistCard extends StatelessWidget {
  final Artist artist;
  final VoidCallback onTap;
  final double size;

  const ArtistCard({
    super.key,
    required this.artist,
    required this.onTap,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        child: Column(
          children: [
            ClipOval(
              child: CachedNetworkImage(
                imageUrl: artist.imageUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: size,
                  height: size,
                  color: colors.surfaceContainerHighest,
                  child: Icon(Icons.person, color: appColors.subtleText, size: AppTheme.iconLg),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: size,
                  height: size,
                  color: colors.surfaceContainerHighest,
                  child: Icon(Icons.person, color: appColors.subtleText, size: AppTheme.iconLg),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              artist.name,
              style: text.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            if (artist.isAiCreator) ...[
              const SizedBox(height: AppTheme.spacingXs / 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, size: AppTheme.iconSm - 4, color: colors.secondary),
                  const SizedBox(width: AppTheme.spacingXs / 2),
                  Text(
                    'AI Creator',
                    style: text.labelSmall?.copyWith(color: colors.secondary),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

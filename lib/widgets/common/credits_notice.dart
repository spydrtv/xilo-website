import 'package:flutter/material.dart';
import '../../theme/theme.dart';

class CreditsNotice extends StatelessWidget {
  final String credits;
  const CreditsNotice({super.key, required this.credits});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (credits.isNotEmpty) ...[
            Text('Credits', style: text.labelLarge),
            const SizedBox(height: AppTheme.spacingXs),
            Text(credits, style: text.bodySmall?.copyWith(color: appColors.subtleText)),
            const SizedBox(height: AppTheme.spacingMd),
          ],
          Row(
            children: [
              Icon(Icons.storefront_rounded, size: AppTheme.iconSm, color: appColors.subtleText),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  'Music available for licensing and purchase at xilo-music.com.',
                  style: text.bodySmall?.copyWith(
                    color: appColors.subtleText,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

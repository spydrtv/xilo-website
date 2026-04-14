import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/theme.dart';

class XiloLogo extends StatelessWidget {
  final double size;
  final VoidCallback? onTap;

  /// Optional URL to your hosted XILO logo image (e.g. Cloudinary).
  /// When null the branded text + icon fallback is shown.
  static const String? logoUrl =
      'https://res.cloudinary.com/dtoryfbxl/image/upload/v1775803176/XILO_mobileApp_header_uz5gqr.png';

  const XiloLogo({super.key, this.size = 28, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    Widget logoContent;

    if (logoUrl != null) {
      // Image logo — shown once you provide a hosted URL
      logoContent = CachedNetworkImage(
        imageUrl: logoUrl!,
        height: size * 1.4,
        fit: BoxFit.contain,
        placeholder: (_, __) => _buildTextLogo(context, appColors, colors),
        errorWidget: (_, __, ___) => _buildTextLogo(context, appColors, colors),
      );
    } else {
      // Branded text + icon fallback
      logoContent = _buildTextLogo(context, appColors, colors);
    }

    if (onTap == null) return logoContent;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: logoContent,
      ),
    );
  }

  Widget _buildTextLogo(
    BuildContext context,
    AppColorsExtension appColors,
    ColorScheme colors,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.25),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [appColors.gradient1, appColors.gradient2],
            ),
          ),
          child: Icon(
            Icons.music_note_rounded,
            color: colors.onPrimary,
            size: size * 0.6,
          ),
        ),
        SizedBox(width: AppTheme.spacingSm),
        Text(
          'XILO',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
        ),
      ],
    );
  }
}

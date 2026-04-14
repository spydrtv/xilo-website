import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/theme.dart';

class HeroSlider extends StatefulWidget {
  const HeroSlider({super.key});

  static const List<String> _imageUrls = [
    'https://res.cloudinary.com/dtoryfbxl/image/upload/v1775754812/Music_Studio_mixingBoard_fdpfix.png',
    'https://res.cloudinary.com/dtoryfbxl/image/upload/v1775754496/spydrtv_cinematic_portrait_photo_of_a_female_singer_singing_int_162cc80d-b476-422a-95f0-e83847b2ca1d_ony2dp.png',
    'https://res.cloudinary.com/dtoryfbxl/image/upload/v1775754495/spydrtv_Artistic_photo_of_an_alternative_rock_band_writing_musi_9672f6c8-d2d8-436d-8e4c-14f502cfa467_zhjtxh.png',
    'https://res.cloudinary.com/dtoryfbxl/image/upload/v1775754495/spydrtv_rear-of-stage_viewpoint_at_night_camera_centered_behind_9c4aa723-371b-4253-bf50-2351c2d86f8c_auy4lf.png',
    'https://res.cloudinary.com/dtoryfbxl/image/upload/v1775754495/spydrtv_Close-up_profile_photo_of_fingers_pushing_the_dials_on__ae2b89b9-fa2b-44d4-8a31-4a26095503f3_dmv2k4.png',
  ];

  @override
  State<HeroSlider> createState() => _HeroSliderState();
}

class _HeroSliderState extends State<HeroSlider>
    with SingleTickerProviderStateMixin {
  Timer? _autoAdvanceTimer;
  int _currentPage = 0;

  static const Duration _autoAdvanceDuration = Duration(seconds: 5);
  static const Duration _fadeDuration = Duration(milliseconds: 900);

  @override
  void initState() {
    super.initState();
    _startAutoAdvance();
  }

  void _startAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer.periodic(_autoAdvanceDuration, (_) {
      if (!mounted) return;
      setState(() {
        _currentPage = (_currentPage + 1) % HeroSlider._imageUrls.length;
      });
    });
  }

  void _onDotTapped(int index) {
    _autoAdvanceTimer?.cancel();
    setState(() => _currentPage = index);
    _startAutoAdvance();
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final isWide = MediaQuery.of(context).size.width >= 600;
    final sliderHeight = isWide ? 580.0 : 380.0;

    return SizedBox(
      height: sliderHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // — Fade crossfade between images —
          AnimatedSwitcher(
            duration: _fadeDuration,
            switchInCurve: Curves.easeIn,
            switchOutCurve: Curves.easeOut,
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: CachedNetworkImage(
              key: ValueKey(_currentPage),
              imageUrl: HeroSlider._imageUrls[_currentPage],
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              placeholder: (_, __) => Container(
                color: colors.surfaceContainerHighest,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: AppTheme.borderSelected,
                    color: appColors.gradient1,
                  ),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                color: colors.surfaceContainerHighest,
                child: Icon(
                  Icons.image_not_supported_rounded,
                  color: colors.outline,
                  size: AppTheme.iconXl,
                ),
              ),
            ),
          ),

          // — Bottom-only dark gradient for text legibility —
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.45, 0.75, 1.0],
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.65),
                    Colors.black.withOpacity(0.88),
                  ],
                ),
              ),
            ),
          ),

          // — Text content + dot indicators —
          Positioned(
            left: AppTheme.spacingLg,
            right: AppTheme.spacingLg,
            bottom: AppTheme.spacingLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Welcome pill badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSm,
                    vertical: AppTheme.spacingXxs,
                  ),
                  decoration: BoxDecoration(
                    color: appColors.gradient1.withOpacity(AppTheme.opacitySubtle + 0.08),
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    border: Border.all(
                      color: appColors.gradient1.withOpacity(0.45),
                      width: AppTheme.borderDefault,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: AppTheme.iconSm,
                        color: appColors.gradient2,
                      ),
                      const SizedBox(width: AppTheme.spacingXxs + 2),
                      Text(
                        'Welcome to XILO Music',
                        style: text.labelSmall?.copyWith(
                          color: Colors.white,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppTheme.spacingSm),

                // Main headline
                Text(
                  'True Independent\nMusic Lives Here.',
                  style: (isWide ? text.displaySmall : text.headlineMedium)?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.12,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.6),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppTheme.spacingXs),

                // Subtitle
                Text(
                  'Human & AI artists — all free to stream',
                  style: text.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(AppTheme.opacityHint + 0.1),
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppTheme.spacingMd),

                // Dot indicators
                _DotIndicator(
                  count: HeroSlider._imageUrls.length,
                  current: _currentPage,
                  activeColor: appColors.gradient2,
                  inactiveColor: Colors.white.withOpacity(0.35),
                  onTap: _onDotTapped,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  final int count;
  final int current;
  final Color activeColor;
  final Color inactiveColor;
  final ValueChanged<int> onTap;

  const _DotIndicator({
    required this.count,
    required this.current,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return GestureDetector(
          onTap: () => onTap(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.only(right: AppTheme.spacingXs),
            width: isActive ? 24.0 : 8.0,
            height: 8.0,
            decoration: BoxDecoration(
              color: isActive ? activeColor : inactiveColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            ),
          ),
        );
      }),
    );
  }
}

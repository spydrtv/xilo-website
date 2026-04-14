import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../theme/theme.dart';
import '../widgets/common/mini_player.dart';

class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final player = context.watch<PlayerProvider>();
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (player.currentTrack != null)
            MiniPlayer(
              onTap: () => context.push('/now-playing'),
            ),
          NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (i) => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex),
            destinations: [
              NavigationDestination(
                icon: Icon(Icons.home_outlined, color: appColors.subtleText),
                selectedIcon: Icon(Icons.home_rounded, color: colors.primary),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.explore_outlined, color: appColors.subtleText),
                selectedIcon: Icon(Icons.explore_rounded, color: colors.primary),
                label: 'Browse',
              ),
              NavigationDestination(
                icon: Icon(Icons.search_rounded, color: appColors.subtleText),
                selectedIcon: Icon(Icons.search_rounded, color: colors.primary),
                label: 'Search',
              ),
              NavigationDestination(
                icon: Icon(Icons.library_music_outlined, color: appColors.subtleText),
                selectedIcon: Icon(Icons.library_music_rounded, color: colors.primary),
                label: 'Library',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

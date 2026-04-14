import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/album.dart';
import '../../models/artist.dart';
import '../../models/cart_item.dart';
import '../../models/track.dart';
import '../../providers/cart_provider.dart';
import '../../providers/player_provider.dart';
import '../../services/creator_upload_service.dart';
import '../../services/music_service.dart';
import '../../theme/theme.dart';
import '../../widgets/common/hero_slider.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/xilo_logo.dart';
import '../../widgets/web/shopping_cart_sheet.dart';
import '../../widgets/web/preview_trimmer.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Web Home / Store / Creator Hub
// ─────────────────────────────────────────────────────────────────────────────

class WebHomeScreen extends StatefulWidget {
  final String section;
  const WebHomeScreen({super.key, this.section = 'home'});

  @override
  State<WebHomeScreen> createState() => _WebHomeScreenState();
}

class _WebHomeScreenState extends State<WebHomeScreen> {
  late String _section;
  User? _currentUser;
  late final CreatorUploadService _uploadService;

  @override
  void initState() {
    super.initState();
    _section = widget.section;
    _uploadService = CreatorUploadService(Supabase.instance.client);
    _currentUser = _uploadService.currentUser;
    _uploadService.authStateChanges.listen((data) {
      if (mounted) {
        setState(() => _currentUser = data.session?.user);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      body: Column(
        children: [
          // ── Web Nav Bar ────────────────────────────────────────────
          _WebNavBar(
            currentSection: _section,
            cartCount: cart.itemCount,
            currentUser: _currentUser,
            onNav: (s) => setState(() => _section = s),
            onCart: () => ShoppingCartSheet.show(context),
            onSignOut: () async {
              await _uploadService.signOut();
              if (mounted) setState(() => _currentUser = null);
            },
          ),
          Expanded(
            child: _buildSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildSection() {
    switch (_section) {
      case 'store':
        return const _StoreSection();
      case 'creator':
        return _currentUser != null
            ? _CreatorDashboardSection(
                uploadService: _uploadService,
                currentUser: _currentUser!,
              )
            : _CreatorLoginGate(onNav: (s) => setState(() => _section = s));
      case 'licensing':
        return const _LicensingInfoSection();
      default:
        return _HomeSection(onNav: (s) => setState(() => _section = s));
    }
  }
}

// ── Web Nav Bar ───────────────────────────────────────────────────────────────

class _WebNavBar extends StatelessWidget {
  final String currentSection;
  final int cartCount;
  final User? currentUser;
  final ValueChanged<String> onNav;
  final VoidCallback onCart;
  final VoidCallback onSignOut;

  const _WebNavBar({
    required this.currentSection,
    required this.cartCount,
    required this.currentUser,
    required this.onNav,
    required this.onCart,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    final isSignedIn = currentUser != null;
    final email = currentUser?.email ?? '';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : '?';

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          XiloLogo(onTap: () => onNav('home')),
          const SizedBox(width: AppTheme.spacingXl),
          ...[
            ('home', 'Discover'),
            ('store', 'Store'),
            ('licensing', 'Licensing'),
            ('creator', 'Creator Hub'),
          ].map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingSm),
              child: TextButton(
                onPressed: () => onNav(item.$1),
                child: Text(
                  item.$2,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: currentSection == item.$1
                        ? colors.gradient1
                        : theme.colorScheme.onSurface,
                    fontWeight: currentSection == item.$1
                        ? FontWeight.bold
                        : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          // Cart button with badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: onCart,
                color: theme.colorScheme.onSurface,
              ),
              if (cartCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: colors.gradient1,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$cartCount',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppTheme.spacingSm),
          if (isSignedIn) ...[
            // My Tracks link
            TextButton.icon(
              onPressed: () => context.go('/web/my-tracks'),
              icon: const Icon(Icons.library_music_rounded,
                  size: AppTheme.iconSm),
              label: const Text('My Tracks'),
              style: TextButton.styleFrom(
                foregroundColor: colors.gradient2,
              ),
            ),
            const SizedBox(width: AppTheme.spacingXs),
            // Avatar + sign out menu
            PopupMenuButton<String>(
              offset: const Offset(0, 48),
              tooltip: email,
              itemBuilder: (_) => [
                PopupMenuItem(
                  enabled: false,
                  child: Text(
                    email,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colors.subtleText),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'my_tracks',
                  child: ListTile(
                    leading: Icon(Icons.library_music_rounded),
                    title: Text('My Tracks'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'sign_out',
                  child: ListTile(
                    leading: Icon(Icons.logout_rounded),
                    title: Text('Sign Out'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'my_tracks') {
                  context.go('/web/my-tracks');
                } else if (value == 'sign_out') {
                  onSignOut();
                }
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor: colors.gradient1,
                child: Text(
                  initial,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ] else ...[
            OutlinedButton(
              onPressed: () => context.go('/web/creator-login'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 36),
              ),
              child: const Text('Creator Login'),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            ElevatedButton(
              onPressed: () => context.go('/web/creator-login'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 36),
              ),
              child: const Text('Join Free'),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Home Section ──────────────────────────────────────────────────────────────

class _HomeSection extends StatelessWidget {
  final ValueChanged<String> onNav;
  const _HomeSection({required this.onNav});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    final service = context.read<MusicService>();
    final artists = service.getArtists();
    final featured = [...artists]
      ..sort((a, b) => b.featuredScore.compareTo(a.featuredScore));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero slider
          const HeroSlider(),

          // Featured Artists
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingXl,
              AppTheme.spacingXl,
              AppTheme.spacingXl,
              AppTheme.spacingMd,
            ),
            child: SectionHeader(
              title: 'Featured Artists',
              subtitle: 'Ranked by streams & releases',
            ),
          ),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingXl),
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppTheme.spacingLg),
              itemCount: featured.take(6).length,
              itemBuilder: (context, i) {
                final artist = featured[i];
                return _WebArtistCard(artist: artist);
              },
            ),
          ),

          // Creator CTA
          Container(
            margin: const EdgeInsets.all(AppTheme.spacingXl),
            padding: const EdgeInsets.all(AppTheme.spacingXl),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.gradient1.withOpacity(0.15),
                  colors.gradient2.withOpacity(0.10),
                ],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.upload_rounded,
                        size: AppTheme.iconLg,
                        color: colors.gradient1,
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      Text(
                        'Ready to share your music?',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      Text(
                        'Create a free account and upload your first track today. Traditional artist or AI creator — everyone is welcome at XILO.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.subtleText,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      ElevatedButton(
                        onPressed: () => onNav('creator'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                        ),
                        child: const Text('Create Free Account'),
                      ),
                    ],
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

// ── Store Section ────────────────────────────────────────────────────────────

class _StoreSection extends StatefulWidget {
  const _StoreSection();

  @override
  State<_StoreSection> createState() => _StoreSectionState();
}

class _StoreSectionState extends State<_StoreSection> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _selectedGenres = {};
  final Set<String> _selectedMoods = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesFilters({
    required String genre,
    required String mood,
    required String title,
    required String artist,
  }) {
    final q = _searchQuery.toLowerCase();
    final matchesSearch = q.isEmpty ||
        title.toLowerCase().contains(q) ||
        artist.toLowerCase().contains(q) ||
        genre.toLowerCase().contains(q);
    final matchesGenre =
        _selectedGenres.isEmpty || _selectedGenres.contains(genre);
    final matchesMood =
        _selectedMoods.isEmpty || _selectedMoods.contains(mood);
    return matchesSearch && matchesGenre && matchesMood;
  }

  void _toggleGenre(String g) =>
      setState(() => _selectedGenres.contains(g)
          ? _selectedGenres.remove(g)
          : _selectedGenres.add(g));

  void _toggleMood(String m) =>
      setState(() => _selectedMoods.contains(m)
          ? _selectedMoods.remove(m)
          : _selectedMoods.add(m));

  void _clearAllFilters() => setState(() {
        _selectedGenres.clear();
        _selectedMoods.clear();
        _searchController.clear();
        _searchQuery = '';
      });

  bool get _hasActiveFilters =>
      _selectedGenres.isNotEmpty ||
      _selectedMoods.isNotEmpty ||
      _searchQuery.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    final service = context.read<MusicService>();
    final cart = context.watch<CartProvider>();

    final genres = service.getGenres();
    final moods = service.getMoods();

    final albums = service.getAllAlbums().where((a) => _matchesFilters(
          genre: a.genre,
          mood: a.mood,
          title: a.title,
          artist: a.artistName,
        )).toList();

    final tracks = service.getAllTracks().where((t) => _matchesFilters(
          genre: t.genre,
          mood: t.mood,
          title: t.title,
          artist: t.artistName,
        )).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Music Store', style: theme.textTheme.headlineMedium),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            'Purchase and license music directly from independent artists.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: colors.subtleText),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // ── Search bar ───────────────────────────────────────────────
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search artist, song, album…',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () => setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                      }),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // ── Genre filter chips ───────────────────────────────────────
          Text('Genre',
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: colors.subtleText)),
          const SizedBox(height: AppTheme.spacingXs),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: genres
                  .map((g) => Padding(
                        padding: const EdgeInsets.only(
                            right: AppTheme.spacingSm),
                        child: _WebFilterChip(
                          label: g,
                          selected: _selectedGenres.contains(g),
                          onTap: () => _toggleGenre(g),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // ── Mood filter chips ────────────────────────────────────────
          Text('Mood',
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: colors.subtleText)),
          const SizedBox(height: AppTheme.spacingXs),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: moods
                  .map((m) => Padding(
                        padding: const EdgeInsets.only(
                            right: AppTheme.spacingSm),
                        child: _WebFilterChip(
                          label: m,
                          selected: _selectedMoods.contains(m),
                          onTap: () => _toggleMood(m),
                        ),
                      ))
                  .toList(),
            ),
          ),

          // ── Active filter summary + clear ────────────────────────────
          if (_hasActiveFilters) ...[
            const SizedBox(height: AppTheme.spacingMd),
            Row(
              children: [
                Icon(Icons.filter_alt_rounded,
                    size: AppTheme.iconSm, color: colors.gradient1),
                const SizedBox(width: AppTheme.spacingXs),
                Text(
                  [
                    if (_selectedGenres.isNotEmpty)
                      _selectedGenres.join(', '),
                    if (_selectedMoods.isNotEmpty)
                      _selectedMoods.join(', '),
                    if (_searchQuery.isNotEmpty) '"$_searchQuery"',
                  ].join(' · '),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colors.gradient1),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _clearAllFilters,
                  icon: const Icon(Icons.clear_all_rounded,
                      size: AppTheme.iconSm),
                  label: const Text('Clear all'),
                  style: TextButton.styleFrom(
                    foregroundColor: colors.subtleText,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: AppTheme.spacingXl),

          // ── Albums grid ──────────────────────────────────────────────
          SectionHeader(
            title: 'Albums & EPs',
            subtitle: '${albums.length} releases',
          ),
          const SizedBox(height: AppTheme.spacingMd),
          albums.isEmpty
              ? _EmptyFilterResult(onClear: _clearAllFilters)
              : Wrap(
                  spacing: AppTheme.spacingMd,
                  runSpacing: AppTheme.spacingMd,
                  children: albums.map((album) {
                    final inCart =
                        cart.contains(album.id, LicenseType.none);
                    return _StoreAlbumCard(
                      album: album,
                      inCart: inCart,
                      onBuy: () => cart.addItem(CartItem(
                        id: '${album.id}_buy',
                        title: album.title,
                        artistName: album.artistName,
                        artUrl: album.artUrl,
                        price: album.price,
                        itemType: album.type == AlbumType.album
                            ? CartItemType.album
                            : CartItemType.ep,
                        sourceId: album.id,
                      )),
                      onLicense: album.isAvailableForLicensing
                          ? () => _showLicenseDialog(context, album)
                          : null,
                    );
                  }).toList(),
                ),

          const SizedBox(height: AppTheme.spacingXxl),

          // ── Singles ──────────────────────────────────────────────────
          SectionHeader(
            title: 'Singles',
            subtitle:
                '${tracks.where((t) => t.albumId == null).length} tracks',
          ),
          const SizedBox(height: AppTheme.spacingMd),
          if (tracks.isEmpty)
            _EmptyFilterResult(onClear: _clearAllFilters)
          else
            ...tracks
                .where(
                    (t) => t.albumId == null || t.isAvailableForPurchase)
                .take(20)
                .map((track) {
              final inCart =
                  cart.contains(track.id, LicenseType.none);
              return _StoreTrackRow(
                track: track,
                inCart: inCart,
                onBuy: () => cart.addItem(CartItem(
                  id: '${track.id}_buy',
                  title: track.title,
                  artistName: track.artistName,
                  artUrl: track.artUrl,
                  price: track.price,
                  itemType: CartItemType.track,
                  sourceId: track.id,
                )),
                onLicense: track.isAvailableForLicensing
                    ? () => _showTrackLicenseDialog(context, track)
                    : null,
              );
            }),
        ],
      ),
    );
  }

  void _showLicenseDialog(BuildContext context, Album album) {
    showDialog(
      context: context,
      builder: (ctx) => _LicenseDialog(
        title: album.title,
        artistName: album.artistName,
        artUrl: album.artUrl,
        sourceId: album.id,
        basePrice: album.price,
      ),
    );
  }

  void _showTrackLicenseDialog(BuildContext context, Track track) {
    showDialog(
      context: context,
      builder: (ctx) => _LicenseDialog(
        title: track.title,
        artistName: track.artistName,
        artUrl: track.artUrl,
        sourceId: track.id,
        basePrice: track.price,
      ),
    );
  }
}

// ── Empty filter result placeholder ──────────────────────────────────────────

class _EmptyFilterResult extends StatelessWidget {
  final VoidCallback onClear;
  const _EmptyFilterResult({required this.onClear});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXl),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded,
              size: AppTheme.iconXl, color: colors.subtleText),
          const SizedBox(height: AppTheme.spacingMd),
          Text('No results match your filters',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: AppTheme.spacingXs),
          TextButton(
              onPressed: onClear, child: const Text('Clear all filters')),
        ],
      ),
    );
  }
}

// ── License Dialog ───────────────────────────────────────────────────────────

class _LicenseDialog extends StatefulWidget {
  final String title;
  final String artistName;
  final String artUrl;
  final String sourceId;
  final double basePrice;

  const _LicenseDialog({
    required this.title,
    required this.artistName,
    required this.artUrl,
    required this.sourceId,
    required this.basePrice,
  });

  @override
  State<_LicenseDialog> createState() => _LicenseDialogState();
}

class _LicenseDialogState extends State<_LicenseDialog> {
  LicenseType _selected = LicenseType.personal;

  double get _price {
    switch (_selected) {
      case LicenseType.personal:
        return widget.basePrice * 2;
      case LicenseType.commercial:
        return widget.basePrice * 8;
      case LicenseType.sync:
        return widget.basePrice * 20;
      default:
        return widget.basePrice;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    final cart = context.read<CartProvider>();

    return AlertDialog(
      title: Text('License "${widget.title}"'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'By ${widget.artistName}',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.subtleText),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            ...[
              (LicenseType.personal, 'Personal',
                  'Non-commercial personal use, home videos, social media (no monetization).'),
              (LicenseType.commercial, 'Commercial',
                  'Ads, branded content, monetized video, podcasts, and other commercial use.'),
              (LicenseType.sync, 'Sync',
                  'Film, TV, game, and media synchronization rights. Broadest usage.'),
            ].map(
              (item) => Padding(
                padding:
                    const EdgeInsets.only(bottom: AppTheme.spacingSm),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  onTap: () => setState(() => _selected = item.$1),
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    decoration: BoxDecoration(
                      color: _selected == item.$1
                          ? theme.colorScheme.primary
                              .withOpacity(AppTheme.opacitySubtle)
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                      border: Border.all(
                        color: _selected == item.$1
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                        width: _selected == item.$1
                            ? AppTheme.borderSelected
                            : AppTheme.borderDefault,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _selected == item.$1
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: _selected == item.$1
                              ? theme.colorScheme.primary
                              : colors.subtleText,
                          size: AppTheme.iconMd,
                        ),
                        const SizedBox(width: AppTheme.spacingMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.$2,
                                style: theme.textTheme.titleSmall,
                              ),
                              const SizedBox(height: AppTheme.spacingXxs),
                              Text(
                                item.$3,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.subtleText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('License fee:', style: theme.textTheme.bodyMedium),
                Text(
                  '\$${_price.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.gradient2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            cart.addItem(CartItem(
              id: '${widget.sourceId}_${_selected.name}',
              title: widget.title,
              artistName: widget.artistName,
              artUrl: widget.artUrl,
              price: _price,
              itemType: CartItemType.track,
              sourceId: widget.sourceId,
              licenseType: _selected,
            ));
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('License added to cart'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: const Text('Add to Cart'),
        ),
      ],
    );
  }
}

// ── Licensing Info Section ────────────────────────────────────────────────────

class _LicensingInfoSection extends StatelessWidget {
  const _LicensingInfoSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingXxl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Music Licensing', style: theme.textTheme.headlineMedium),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              'Use XILO Music in your next project.',
              style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.subtleText),
            ),
            const SizedBox(height: AppTheme.spacingXl),
            ...[
              (
                Icons.person_rounded,
                'Personal License',
                '\$2.99 – \$19.99',
                'For personal, non-commercial projects. Perfect for personal vlogs, home videos, and social media content without monetization. Cannot be used in ads or revenue-generating projects.',
                colors.gradient1,
              ),
              (
                Icons.business_rounded,
                'Commercial License',
                '\$9.99 – \$79.99',
                'For business use, advertising, branded content, and monetized video. Includes usage in YouTube monetized channels, podcasts, and online ads.',
                colors.gradient2,
              ),
              (
                Icons.movie_rounded,
                'Sync License',
                '\$24.99 – \$199.99',
                'Synchronization rights for film, TV, games, and broadcast media. The broadest and most flexible license type — covers nearly any media use. Pricing varies by project scope.',
                colors.warning,
              ),
            ].map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: AppTheme.spacingLg),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  border: Border.all(
                    color: item.$5.withOpacity(0.35),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header bar ──────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingLg,
                        vertical: AppTheme.spacingMd,
                      ),
                      decoration: BoxDecoration(
                        color: item.$5.withOpacity(AppTheme.opacitySubtle),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppTheme.radiusLarge),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(item.$1,
                              color: item.$5, size: AppTheme.iconLg),
                          const SizedBox(width: AppTheme.spacingMd),
                          Expanded(
                            child: Text(
                              item.$2,
                              style:
                                  theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ── Price badge ──────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.spacingLg,
                        AppTheme.spacingMd,
                        AppTheme.spacingLg,
                        AppTheme.spacingXs,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingMd,
                              vertical: AppTheme.spacingSm,
                            ),
                            decoration: BoxDecoration(
                              color: item.$5
                                  .withOpacity(AppTheme.opacitySubtle),
                              borderRadius: BorderRadius.circular(
                                  AppTheme.radiusPill),
                              border: Border.all(
                                  color:
                                      item.$5.withOpacity(0.5)),
                            ),
                            child: Text(
                              item.$3,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(
                                color: item.$5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ── Description ───────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.spacingLg,
                        AppTheme.spacingSm,
                        AppTheme.spacingLg,
                        AppTheme.spacingXl,
                      ),
                      child: Text(
                        item.$4,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colors.subtleText,
                          height: 1.65,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Text(
                '💡  To license a specific track, browse the Store, find the track or album, and click "License This". You\'ll be guided through selecting the right license type for your project.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.subtleText,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Creator Dashboard Section ─────────────────────────────────────────────────

// ── Bulk track model (local UI only) ─────────────────────────────────────────

class _BulkTrack {
  final String fileName;
  final String title;
  final int trackNumber;
  final int durationMs;
  int previewStartMs = 0;

  _BulkTrack({
    required this.fileName,
    required this.title,
    required this.trackNumber,
    required this.durationMs,
  });
}

// ── Creator Login Gate ────────────────────────────────────────────────────────

class _CreatorLoginGate extends StatelessWidget {
  final ValueChanged<String> onNav;
  const _CreatorLoginGate({required this.onNav});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [colors.gradient1, colors.gradient2],
                ).createShader(bounds),
                child: const Icon(
                  Icons.mic_external_on_rounded,
                  size: AppTheme.iconXl,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              Text(
                'Creator Hub',
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingXs),
              Text(
                'Sign in to upload your music and manage your catalog. Your tracks sync automatically to the XILO mobile app.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: colors.subtleText),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingXl),
              ElevatedButton.icon(
                onPressed: () => context.go('/web/creator-login'),
                icon: const Icon(Icons.login_rounded),
                label: const Text('Sign In / Join Free'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, AppTheme.buttonHeight),
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                'New creators get a free account automatically — no credit card required.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: colors.subtleText),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Creator Dashboard ─────────────────────────────────────────────────────────

class _CreatorDashboardSection extends StatefulWidget {
  final CreatorUploadService uploadService;
  final User currentUser;

  const _CreatorDashboardSection({
    required this.uploadService,
    required this.currentUser,
  });

  @override
  State<_CreatorDashboardSection> createState() =>
      _CreatorDashboardSectionState();
}

class _CreatorDashboardSectionState
    extends State<_CreatorDashboardSection> {
  // ── Artwork ────────────────────────────────────────────────────────────────
  String? _artworkFileName;
  // ignore: avoid_web_libraries_in_flutter
  dynamic _artworkFile; // dart:html File
  bool _artworkDragOver = false;

  // ── Release metadata ───────────────────────────────────────────────────────
  final _releaseTitleController = TextEditingController();
  final _artistNameController = TextEditingController();
  final _creditsController = TextEditingController();
  final _lyricsController = TextEditingController();
  String _selectedGenre = 'Electronic';
  String _selectedMood = 'Chill';
  String _selectedType = 'Single';
  bool _isExplicit = false;
  bool _isAiCreated = false;
  bool _availableForPurchase = true;
  bool _availableForLicensing = false;
  bool _allowPersonalLicense = true;
  bool _allowCommercialLicense = false;
  bool _allowSyncLicense = false;

  // ── Bulk upload ────────────────────────────────────────────────────────────
  bool _bulkMode = false;
  bool _tracksDragOver = false;
  final List<_BulkTrack> _bulkTracks = [];
  // ignore: avoid_web_libraries_in_flutter
  final List<dynamic> _bulkAudioFiles = []; // dart:html File list

  // ── Single-track mode state ────────────────────────────────────────────────
  final _singleTitleController = TextEditingController();
  // ignore: avoid_web_libraries_in_flutter
  dynamic _singleAudioFile; // dart:html File
  String? _singleAudioFileName;
  int _previewStartMs = 0;
  static const int _mockSingleDurationMs = 210000;

  // ── Upload state ───────────────────────────────────────────────────────────
  bool _uploading = false;
  String _uploadStatus = '';
  double _uploadProgress = 0.0;

  @override
  void dispose() {
    _releaseTitleController.dispose();
    _artistNameController.dispose();
    _creditsController.dispose();
    _lyricsController.dispose();
    _singleTitleController.dispose();
    super.dispose();
  }

  // ── File pickers ──────────────────────────────────────────────────────────

  Future<void> _pickArtwork() async {
    final file = await widget.uploadService.pickFile(
      acceptedTypes: ['.jpg', '.jpeg', '.png', '.webp'],
    );
    if (file != null && mounted) {
      setState(() {
        _artworkFile = file;
        _artworkFileName = file.name;
      });
    }
  }

  Future<void> _pickSingleAudio() async {
    final file = await widget.uploadService.pickFile(
      acceptedTypes: ['.mp3', '.wav', '.flac', '.aiff', '.aif'],
    );
    if (file != null && mounted) {
      setState(() {
        _singleAudioFile = file;
        _singleAudioFileName = file.name;
      });
    }
  }

  Future<void> _pickBulkAudio() async {
    final files = await widget.uploadService.pickMultipleAudioFiles();
    if (files.isNotEmpty && mounted) {
      setState(() {
        _bulkAudioFiles.clear();
        _bulkAudioFiles.addAll(files);
        _bulkTracks.clear();
        for (final f in files) {
          _bulkTracks.add(_parseBulkTrack(f.name.toString()));
        }
      });
    }
  }

  _BulkTrack _parseBulkTrack(String fileName) {
    final base = fileName.replaceAll(
        RegExp(r'\.(mp3|wav|flac|aiff?)$', caseSensitive: false), '');
    final patterns = [
      RegExp(r'^(\d+)\s*[-_.]\s*(.+)$'),
      RegExp(r'^[Tt]rack\s*(\d+)\s+(.+)$'),
    ];
    int trackNum = _bulkTracks.length + 1;
    String title = base;
    for (final p in patterns) {
      final m = p.firstMatch(base);
      if (m != null) {
        trackNum = int.tryParse(m.group(1)!) ?? trackNum;
        title = m.group(2)!.trim();
        break;
      }
    }
    final mockDuration = 150000 + (trackNum * 37000) % 150000;
    return _BulkTrack(
      fileName: fileName,
      title: title,
      trackNumber: trackNum,
      durationMs: mockDuration,
    );
  }

  void _removeBulkTrack(int index) {
    setState(() {
      _bulkTracks.removeAt(index);
      if (index < _bulkAudioFiles.length) {
        _bulkAudioFiles.removeAt(index);
      }
    });
  }

  String _formatDuration(int ms) {
    final s = ms ~/ 1000;
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  // ── Real upload ───────────────────────────────────────────────────────────

  Future<void> _handleUpload() async {
    final releaseTitle = _releaseTitleController.text.trim();
    final artistName = _artistNameController.text.trim();

    if (releaseTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter a release title.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    if (artistName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter your artist name.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    if (_artworkFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please upload artwork before submitting.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    if (!_bulkMode && _singleAudioFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please upload an audio file.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    if (_bulkMode && _bulkAudioFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please upload at least one audio file.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() {
      _uploading = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'Uploading artwork…';
    });

    try {
      // 1. Upload artwork
      final artUrl = await widget.uploadService.uploadArtwork(
        file: _artworkFile,
        releaseTitle: releaseTitle,
      );
      setState(() {
        _uploadProgress = 0.15;
        _uploadStatus = 'Creating artist profile…';
      });

      // 2. Ensure artist profile exists
      final artistId = await widget.uploadService.ensureArtistProfile(
        artistName: artistName,
        imageUrl: artUrl,
        isAiCreator: _isAiCreated,
      );
      setState(() {
        _uploadProgress = 0.25;
        _uploadStatus = 'Creating release…';
      });

      // 3. Insert album row
      final albumId = await widget.uploadService.insertAlbum(
        title: releaseTitle,
        artistId: artistId,
        artistName: artistName,
        artUrl: artUrl,
        type: _selectedType,
        genre: _selectedGenre,
        mood: _selectedMood,
        credits: _creditsController.text.trim(),
        isExplicit: _isExplicit,
        isAiCreated: _isAiCreated,
        availableForPurchase: _availableForPurchase,
        availableForLicensing: _availableForLicensing,
        allowPersonalLicense: _allowPersonalLicense,
        allowCommercialLicense: _allowCommercialLicense,
        allowSyncLicense: _allowSyncLicense,
      );

      // 4. Upload audio files and insert track rows
      final List<String> trackIds = [];
      final totalFiles = _bulkMode ? _bulkAudioFiles.length : 1;

      if (!_bulkMode) {
        setState(() {
          _uploadProgress = 0.4;
          _uploadStatus = 'Uploading audio…';
        });
        final audioUrl = await widget.uploadService.uploadAudio(
          file: _singleAudioFile,
          releaseTitle: releaseTitle,
          trackNumber: 1,
        );
        setState(() {
          _uploadProgress = 0.75;
          _uploadStatus = 'Saving track…';
        });
        final trackId = await widget.uploadService.insertTrack(
          title: _singleTitleController.text.trim().isNotEmpty
              ? _singleTitleController.text.trim()
              : releaseTitle,
          artistId: artistId,
          artistName: artistName,
          albumId: albumId,
          albumTitle: releaseTitle,
          artUrl: artUrl,
          audioUrl: audioUrl,
          genre: _selectedGenre,
          mood: _selectedMood,
          credits: _creditsController.text.trim(),
          lyrics: _lyricsController.text.trim(),
          isExplicit: _isExplicit,
          isAiCreated: _isAiCreated,
          availableForPurchase: _availableForPurchase,
          availableForLicensing: _availableForLicensing,
          trackNumber: 1,
          durationMs: _mockSingleDurationMs,
          previewStartMs: _previewStartMs,
        );
        trackIds.add(trackId);
      } else {
        for (int i = 0; i < _bulkAudioFiles.length; i++) {
          final bulkTrack = _bulkTracks[i];
          setState(() {
            _uploadProgress = 0.3 + (0.6 * i / totalFiles);
            _uploadStatus =
                'Uploading track ${i + 1} of $totalFiles…';
          });
          final audioUrl = await widget.uploadService.uploadAudio(
            file: _bulkAudioFiles[i],
            releaseTitle: releaseTitle,
            trackNumber: bulkTrack.trackNumber,
          );
          final trackId = await widget.uploadService.insertTrack(
            title: bulkTrack.title,
            artistId: artistId,
            artistName: artistName,
            albumId: albumId,
            albumTitle: releaseTitle,
            artUrl: artUrl,
            audioUrl: audioUrl,
            genre: _selectedGenre,
            mood: _selectedMood,
            credits: _creditsController.text.trim(),
            lyrics: '',
            isExplicit: _isExplicit,
            isAiCreated: _isAiCreated,
            availableForPurchase: _availableForPurchase,
            availableForLicensing: _availableForLicensing,
            trackNumber: bulkTrack.trackNumber,
            durationMs: bulkTrack.durationMs,
            previewStartMs: bulkTrack.previewStartMs,
          );
          trackIds.add(trackId);
        }
      }

      // 5. Link track IDs back to album
      setState(() {
        _uploadProgress = 0.95;
        _uploadStatus = 'Finalizing…';
      });
      await widget.uploadService.updateAlbumTrackIds(
        albumId: albumId,
        trackIds: trackIds,
      );

      if (mounted) {
        setState(() {
          _uploading = false;
          _uploadProgress = 1.0;
          _uploadStatus = '';
          // Reset form
          _artworkFile = null;
          _artworkFileName = null;
          _singleAudioFile = null;
          _singleAudioFileName = null;
          _bulkAudioFiles.clear();
          _bulkTracks.clear();
          _releaseTitleController.clear();
          _artistNameController.clear();
          _creditsController.clear();
          _lyricsController.clear();
          _singleTitleController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🎵  ${trackIds.length} track${trackIds.length == 1 ? '' : 's'} uploaded successfully! Your music is now live in the XILO catalog.',
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            backgroundColor: Theme.of(context)
                .extension<AppColorsExtension>()!
                .success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploading = false;
          _uploadProgress = 0;
          _uploadStatus = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor:
                Theme.of(context).extension<AppColorsExtension>()!.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    final service = context.read<MusicService>();
    final genres = service.getGenres();
    final moods = service.getMoods();

    // Show upload progress overlay when uploading
    if (_uploading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Uploading your music…',
                    style: theme.textTheme.headlineSmall),
                const SizedBox(height: AppTheme.spacingLg),
                LinearProgressIndicator(
                  value: _uploadProgress,
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusPill),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Text(
                  _uploadStatus,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: colors.subtleText),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingXl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Creator Dashboard',
                          style: theme.textTheme.headlineMedium),
                      const SizedBox(height: AppTheme.spacingXs),
                      Text(
                        'Upload your music, manage metadata, and set availability.',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: colors.subtleText),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => context.go('/web/my-tracks'),
                  icon: const Icon(Icons.library_music_rounded,
                      size: AppTheme.iconSm),
                  label: const Text('My Tracks'),
                  style: TextButton.styleFrom(
                    foregroundColor: colors.gradient2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingXl),

            // ── Album Artwork Upload ───────────────────────────────────
            _SectionCard(
              title: 'Album / Release Artwork',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upload your cover art. Recommended: 3000 × 3000 px square JPG or PNG.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colors.subtleText),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  MouseRegion(
                    onEnter: (_) =>
                        setState(() => _artworkDragOver = true),
                    onExit: (_) =>
                        setState(() => _artworkDragOver = false),
                    child: GestureDetector(
                      onTap: _pickArtwork,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 160,
                        decoration: BoxDecoration(
                          color: _artworkDragOver
                              ? colors.gradient1
                                  .withOpacity(AppTheme.opacitySubtle)
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(
                              AppTheme.radiusLarge),
                          border: Border.all(
                            color: _artworkDragOver
                                ? colors.gradient1
                                : theme.colorScheme.outlineVariant,
                            width: _artworkDragOver ? 2 : 1,
                          ),
                        ),
                        child: _artworkFileName != null
                            ? Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_rounded,
                                      color: colors.gradient2,
                                      size: AppTheme.iconLg),
                                  const SizedBox(
                                      width: AppTheme.spacingSm),
                                  Text(_artworkFileName!,
                                      style: theme.textTheme.bodyMedium),
                                  const SizedBox(
                                      width: AppTheme.spacingMd),
                                  TextButton(
                                    onPressed: () => setState(() {
                                      _artworkFileName = null;
                                      _artworkFile = null;
                                    }),
                                    child: const Text('Remove'),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_rounded,
                                      size: AppTheme.iconXl,
                                      color: _artworkDragOver
                                          ? colors.gradient1
                                          : colors.subtleText),
                                  const SizedBox(
                                      height: AppTheme.spacingSm),
                                  Text(
                                    'Drag & drop artwork here, or click to browse',
                                    style:
                                        theme.textTheme.bodyMedium?.copyWith(
                                      color: _artworkDragOver
                                          ? colors.gradient1
                                          : colors.subtleText,
                                    ),
                                  ),
                                  const SizedBox(
                                      height: AppTheme.spacingXs),
                                  Text('JPG, PNG · Max 10 MB',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                              color: colors.subtleText)),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // ── Release Metadata ──────────────────────────────────────
            _SectionCard(
              title: 'Release Info',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Artist Name', style: theme.textTheme.titleSmall),
                  const SizedBox(height: AppTheme.spacingXs),
                  TextField(
                    controller: _artistNameController,
                    decoration: const InputDecoration(
                        hintText: 'Your artist or project name…'),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Text('Release Title', style: theme.textTheme.titleSmall),
                  const SizedBox(height: AppTheme.spacingXs),
                  TextField(
                    controller: _releaseTitleController,
                    decoration: const InputDecoration(
                        hintText: 'Album, EP, or single title…'),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Genre',
                                style: theme.textTheme.titleSmall),
                            const SizedBox(height: AppTheme.spacingXs),
                            DropdownButtonFormField<String>(
                              value: _selectedGenre,
                              items: genres
                                  .map((g) => DropdownMenuItem(
                                      value: g, child: Text(g)))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedGenre = v!),
                              decoration: const InputDecoration(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Mood',
                                style: theme.textTheme.titleSmall),
                            const SizedBox(height: AppTheme.spacingXs),
                            DropdownButtonFormField<String>(
                              value: _selectedMood,
                              items: moods
                                  .map((m) => DropdownMenuItem(
                                      value: m, child: Text(m)))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedMood = v!),
                              decoration: const InputDecoration(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Text('Release Type', style: theme.textTheme.titleSmall),
                  const SizedBox(height: AppTheme.spacingXs),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                          value: 'Single', label: Text('Single')),
                      ButtonSegment(value: 'EP', label: Text('EP')),
                      ButtonSegment(
                          value: 'Album', label: Text('Album')),
                    ],
                    selected: {_selectedType},
                    onSelectionChanged: (s) =>
                        setState(() => _selectedType = s.first),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Wrap(
                    spacing: AppTheme.spacingMd,
                    runSpacing: AppTheme.spacingXs,
                    children: [
                      _LabeledSwitch(
                        label: 'Explicit Content',
                        value: _isExplicit,
                        onChanged: (v) =>
                            setState(() => _isExplicit = v),
                      ),
                      _LabeledSwitch(
                        label: 'AI Created',
                        value: _isAiCreated,
                        onChanged: (v) =>
                            setState(() => _isAiCreated = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Text('Creator Credits',
                      style: theme.textTheme.titleSmall),
                  const SizedBox(height: AppTheme.spacingXs),
                  TextField(
                    controller: _creditsController,
                    decoration: const InputDecoration(
                      hintText: 'Produced by…, Written by…, Mixed at…',
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // ── Track Upload — mode toggle ─────────────────────────────
            _SectionCard(
              title: 'Track Upload',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mode selector
                  Row(
                    children: [
                      Expanded(
                        child: _ModeButton(
                          icon: Icons.audio_file_rounded,
                          label: 'Single Track',
                          selected: !_bulkMode,
                          onTap: () =>
                              setState(() => _bulkMode = false),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingMd),
                      Expanded(
                        child: _ModeButton(
                          icon: Icons.library_music_rounded,
                          label: 'Bulk Upload (Album/EP)',
                          selected: _bulkMode,
                          onTap: () =>
                              setState(() => _bulkMode = true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingLg),

                  if (!_bulkMode) ...[
                    // ── Single track mode ──────────────────────────────
                    Text('Track Title',
                        style: theme.textTheme.titleSmall),
                    const SizedBox(height: AppTheme.spacingXs),
                    TextField(
                      controller: _singleTitleController,
                      decoration: const InputDecoration(
                          hintText: 'Enter track title…'),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    // Audio file drop zone
                    _AudioDropZone(
                      dragOver: _tracksDragOver,
                      hasFiles: _singleAudioFile != null,
                      onDragEnter: () =>
                          setState(() => _tracksDragOver = true),
                      onDragExit: () =>
                          setState(() => _tracksDragOver = false),
                      onTap: _pickSingleAudio,
                      label: _singleAudioFileName != null
                          ? _singleAudioFileName!
                          : 'Click to browse your audio file',
                      sublabel: 'MP3, WAV, FLAC, AIFF · Max 200 MB',
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                    Text('Lyrics (optional)',
                        style: theme.textTheme.titleSmall),
                    const SizedBox(height: AppTheme.spacingXs),
                    TextField(
                      controller: _lyricsController,
                      decoration: const InputDecoration(
                          hintText: 'Paste lyrics here…'),
                      maxLines: 5,
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                    // Preview trimmer
                    PreviewTrimmer(
                      totalDurationMs: _mockSingleDurationMs,
                      initialStartMs: _previewStartMs,
                      onChanged: (ms) =>
                          setState(() => _previewStartMs = ms),
                    ),
                  ] else ...[
                    // ── Bulk upload mode ───────────────────────────────
                    Text(
                      'Drop all your album tracks at once. XILO auto-detects track numbers and titles from your filenames.',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: colors.subtleText),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    _AudioDropZone(
                      dragOver: _tracksDragOver,
                      hasFiles: _bulkTracks.isNotEmpty,
                      onDragEnter: () =>
                          setState(() => _tracksDragOver = true),
                      onDragExit: () =>
                          setState(() => _tracksDragOver = false),
                      onTap: _pickBulkAudio,
                      label: _bulkTracks.isEmpty
                          ? 'Click to browse and select all album tracks'
                          : '${_bulkTracks.length} tracks selected — click to replace',
                      sublabel:
                          'Tip: name files "01 - Title.mp3" for auto-detection',
                    ),

                    if (_bulkTracks.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.spacingLg),
                      Row(
                        children: [
                          Text(
                            'Tracks — Set Preview Start Points',
                            style: theme.textTheme.titleSmall,
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => setState(() {
                              _bulkTracks.clear();
                              _bulkAudioFiles.clear();
                            }),
                            icon: const Icon(Icons.clear_all_rounded,
                                size: AppTheme.iconSm),
                            label: const Text('Clear all'),
                            style: TextButton.styleFrom(
                              foregroundColor: colors.danger,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      ...List.generate(_bulkTracks.length, (i) {
                        final t = _bulkTracks[i];
                        return _BulkTrackRow(
                          track: t,
                          index: i,
                          formattedDuration:
                              _formatDuration(t.durationMs),
                          onRemove: () => _removeBulkTrack(i),
                          onPreviewChanged: (ms) => setState(
                              () => _bulkTracks[i].previewStartMs = ms),
                        );
                      }),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // ── Availability & Monetization ───────────────────────────
            _SectionCard(
              title: 'Availability & Monetization',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LabeledSwitch(
                    label: 'Available for Purchase',
                    value: _availableForPurchase,
                    onChanged: (v) =>
                        setState(() => _availableForPurchase = v),
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  _LabeledSwitch(
                    label: 'Available for Licensing',
                    value: _availableForLicensing,
                    onChanged: (v) =>
                        setState(() => _availableForLicensing = v),
                  ),
                  if (_availableForLicensing) ...[
                    const SizedBox(height: AppTheme.spacingSm),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: AppTheme.spacingMd),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'License types to offer:',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.subtleText),
                          ),
                          const SizedBox(height: AppTheme.spacingXs),
                          _LabeledCheckbox(
                            label: 'Personal License',
                            value: _allowPersonalLicense,
                            onChanged: (v) => setState(
                                () => _allowPersonalLicense = v!),
                          ),
                          _LabeledCheckbox(
                            label: 'Commercial License',
                            value: _allowCommercialLicense,
                            onChanged: (v) => setState(
                                () => _allowCommercialLicense = v!),
                          ),
                          _LabeledCheckbox(
                            label: 'Sync License  (Film / TV / Games)',
                            value: _allowSyncLicense,
                            onChanged: (v) => setState(
                                () => _allowSyncLicense = v!),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingXl),

            // ── Submit ────────────────────────────────────────────────
            ElevatedButton.icon(
              onPressed: _handleUpload,
              icon: const Icon(Icons.upload_rounded),
              label: Text(_bulkMode && _bulkTracks.isNotEmpty
                  ? 'Submit ${_bulkTracks.length} Tracks for Review'
                  : 'Submit for Review'),
              style: ElevatedButton.styleFrom(
                minimumSize:
                    const Size(double.infinity, AppTheme.buttonHeight),
              ),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              'All uploads are reviewed before appearing in the app. Approved music syncs automatically to the XILO streaming catalog.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: colors.subtleText),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Audio Drop Zone ───────────────────────────────────────────────────────────

class _AudioDropZone extends StatelessWidget {
  final bool dragOver;
  final bool hasFiles;
  final VoidCallback onDragEnter;
  final VoidCallback onDragExit;
  final VoidCallback onTap;
  final String label;
  final String sublabel;

  const _AudioDropZone({
    required this.dragOver,
    required this.hasFiles,
    required this.onDragEnter,
    required this.onDragExit,
    required this.onTap,
    required this.label,
    required this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    return MouseRegion(
      onEnter: (_) => onDragEnter(),
      onExit: (_) => onDragExit(),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 120,
          decoration: BoxDecoration(
            color: dragOver
                ? colors.gradient2.withOpacity(AppTheme.opacitySubtle)
                : hasFiles
                    ? colors.gradient1
                        .withOpacity(AppTheme.opacitySubtle * 0.5)
                    : theme.colorScheme.surfaceContainerHighest,
            borderRadius:
                BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(
              color: dragOver
                  ? colors.gradient2
                  : hasFiles
                      ? colors.gradient1.withOpacity(0.5)
                      : theme.colorScheme.outlineVariant,
              width: dragOver ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                dragOver
                    ? Icons.file_download_rounded
                    : hasFiles
                        ? Icons.playlist_add_check_rounded
                        : Icons.cloud_upload_rounded,
                size: AppTheme.iconXl,
                color: dragOver
                    ? colors.gradient2
                    : hasFiles
                        ? colors.gradient1
                        : colors.subtleText,
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: dragOver
                      ? colors.gradient2
                      : hasFiles
                          ? colors.gradient1
                          : colors.subtleText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingXxs),
              Text(sublabel,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colors.subtleText)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mode Button ───────────────────────────────────────────────────────────────

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          vertical: AppTheme.spacingMd,
          horizontal: AppTheme.spacingMd,
        ),
        decoration: BoxDecoration(
          color: selected
              ? colors.gradient1.withOpacity(AppTheme.opacitySubtle)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: selected
                ? colors.gradient1
                : theme.colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: AppTheme.iconMd,
                color: selected
                    ? colors.gradient1
                    : colors.subtleText),
            const SizedBox(width: AppTheme.spacingSm),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: selected
                      ? colors.gradient1
                      : theme.colorScheme.onSurface,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bulk Track Row ────────────────────────────────────────────────────────────

class _BulkTrackRow extends StatelessWidget {
  final _BulkTrack track;
  final int index;
  final String formattedDuration;
  final VoidCallback onRemove;
  final ValueChanged<int> onPreviewChanged;

  const _BulkTrackRow({
    required this.track,
    required this.index,
    required this.formattedDuration,
    required this.onRemove,
    required this.onPreviewChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Track header ─────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color:
                      colors.gradient1.withOpacity(AppTheme.opacitySubtle),
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusSmall),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${track.trackNumber}',
                  style: theme.textTheme.labelLarge?.copyWith(
                      color: colors.gradient1,
                      fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(track.title,
                        style: theme.textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis),
                    Text(
                      '${track.fileName}  ·  $formattedDuration',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: colors.subtleText),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded,
                    size: AppTheme.iconSm, color: colors.danger),
                onPressed: onRemove,
                tooltip: 'Remove track',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          // ── Preview trimmer ───────────────────────────────────────────
          PreviewTrimmer(
            totalDurationMs: track.durationMs,
            initialStartMs: track.previewStartMs,
            onChanged: onPreviewChanged,
          ),
        ],
      ),
    );
  }
}

// ── Web Artist Card ───────────────────────────────────────────────────────────

class _WebArtistCard extends StatelessWidget {
  final Artist artist;
  const _WebArtistCard({required this.artist});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    return SizedBox(
      width: 110,
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [colors.gradient1, colors.gradient2],
                  ),
                ),
                child: ClipOval(
                  child: Image.network(
                    artist.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(
                        artist.name[0],
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (artist.isAiCreator)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.spacingXxs),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: AppTheme.iconSm,
                      color: theme.colorScheme.onSecondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            artist.name,
            style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          Text(
            artist.genres.take(1).join(),
            style: theme.textTheme.bodySmall?.copyWith(
                color: colors.subtleText),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Store Album Card ──────────────────────────────────────────────────────────

class _StoreAlbumCard extends StatelessWidget {
  final Album album;
  final bool inCart;
  final VoidCallback onBuy;
  final VoidCallback? onLicense;

  const _StoreAlbumCard({
    required this.album,
    required this.inCart,
    required this.onBuy,
    this.onLicense,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusMedium),
                ),
                child: CachedNetworkImage(
                  imageUrl: album.artUrl,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              // 30-sec preview play button
              Positioned(
                bottom: AppTheme.spacingSm,
                right: AppTheme.spacingSm,
                child: GestureDetector(
                  onTap: () => _playPreview(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface
                          .withOpacity(AppTheme.opacityOverlay),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: theme.colorScheme.onSurface,
                      size: AppTheme.iconMd,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingSm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  album.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  album.artistName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.subtleText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Row(
                  children: [
                    Text(
                      '\$${album.price.toStringAsFixed(2)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.gradient2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (inCart)
                      Icon(Icons.check_circle_rounded,
                          color: colors.success, size: AppTheme.iconMd)
                    else
                      GestureDetector(
                        onTap: onBuy,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingSm,
                            vertical: AppTheme.spacingXxs,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(
                                AppTheme.radiusPill),
                          ),
                          child: Text(
                            'Buy',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (onLicense != null) ...[
                  const SizedBox(height: AppTheme.spacingXs),
                  GestureDetector(
                    onTap: onLicense,
                    child: Text(
                      'License This →',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.gradient1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _playPreview(BuildContext context) {
    final player = context.read<PlayerProvider>();
    final service = context.read<MusicService>();
    final tracks = service.getTracksByAlbum(album.id);
    if (tracks.isNotEmpty) {
      player.playTrack(tracks.first, queue: tracks);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Playing 30-sec preview of "${album.title}"'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

// ── Store Track Row ───────────────────────────────────────────────────────────

class _StoreTrackRow extends StatelessWidget {
  final Track track;
  final bool inCart;
  final VoidCallback onBuy;
  final VoidCallback? onLicense;

  const _StoreTrackRow({
    required this.track,
    required this.inCart,
    required this.onBuy,
    this.onLicense,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    final player = context.read<PlayerProvider>();

    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        child: CachedNetworkImage(
          imageUrl: track.artUrl,
          width: AppTheme.albumArtSmall,
          height: AppTheme.albumArtSmall,
          fit: BoxFit.cover,
        ),
      ),
      title: Text(
        track.title,
        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${track.artistName} · ${track.durationString}',
        style:
            theme.textTheme.bodySmall?.copyWith(color: colors.subtleText),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 30-sec preview
          IconButton(
            icon: Icon(Icons.play_circle_outline_rounded,
                size: AppTheme.iconMd, color: colors.subtleText),
            onPressed: () {
              player.playTrack(track);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Playing preview: "${track.title}"'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            tooltip: '30-sec preview',
          ),
          Text(
            '\$${track.price.toStringAsFixed(2)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.gradient2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: AppTheme.spacingXs),
          if (inCart)
            Icon(Icons.check_circle_rounded,
                color: colors.success, size: AppTheme.iconMd)
          else
            TextButton(onPressed: onBuy, child: const Text('Buy')),
          if (onLicense != null)
            TextButton(
              onPressed: onLicense,
              child: Text(
                'License',
                style: TextStyle(color: colors.gradient1),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppTheme.spacingMd),
          const Divider(height: 1),
          const SizedBox(height: AppTheme.spacingMd),
          child,
        ],
      ),
    );
  }
}

class _LabeledSwitch extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _LabeledSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Switch(value: value, onChanged: onChanged),
        const SizedBox(width: AppTheme.spacingXs),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _LabeledCheckbox extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _LabeledCheckbox({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(value: value, onChanged: onChanged),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _WebFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _WebFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingXs,
        ),
        decoration: BoxDecoration(
          color: selected
              ? colors.gradient1.withOpacity(0.18)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          border: Border.all(
            color: selected
                ? colors.gradient1
                : theme.colorScheme.outlineVariant,
            width: selected ? AppTheme.borderSelected : AppTheme.borderDefault,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color:
                selected ? colors.gradient1 : theme.colorScheme.onSurface,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

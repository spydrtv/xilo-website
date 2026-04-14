import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/creator_upload_service.dart';
import '../../theme/theme.dart';
import '../../widgets/common/xilo_logo.dart';

// ─────────────────────────────────────────────────────────────────────────────
// My Tracks Screen — creator's uploaded tracks with delete support
// ─────────────────────────────────────────────────────────────────────────────

class MyTracksScreen extends StatefulWidget {
  const MyTracksScreen({super.key});

  @override
  State<MyTracksScreen> createState() => _MyTracksScreenState();
}

class _MyTracksScreenState extends State<MyTracksScreen> {
  late final CreatorUploadService _service;
  List<Map<String, dynamic>> _tracks = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = CreatorUploadService(Supabase.instance.client);
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tracks = await _service.fetchMyTracks();
      if (mounted) setState(() {
        _tracks = tracks;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = 'Could not load your tracks. Please try again.';
        _loading = false;
      });
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> track) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final colors = theme.extension<AppColorsExtension>()!;
        return AlertDialog(
          title: const Text('Delete track?'),
          content: Text(
            'This will permanently remove "${track['title']}" from the XILO catalog. This cannot be undone.',
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.danger,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 40),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _service.deleteTrack(
        trackId: track['id'].toString(),
        audioUrl: track['audio_url']?.toString() ?? '',
      );
      await _loadTracks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Track deleted successfully.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not delete track. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatDuration(int? ms) {
    if (ms == null || ms == 0) return '--:--';
    final s = ms ~/ 1000;
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    return Scaffold(
      body: Column(
        children: [
          // ── Nav Bar ───────────────────────────────────────────────────
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingXl),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              border: Border(
                bottom: BorderSide(
                    color: theme.colorScheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                XiloLogo(onTap: () => context.go('/web')),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => context.go('/web/creator'),
                  icon: const Icon(Icons.upload_rounded,
                      size: AppTheme.iconSm),
                  label: const Text('Upload Music'),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                OutlinedButton.icon(
                  onPressed: () async {
                    await _service.signOut();
                    if (context.mounted) context.go('/web');
                  },
                  icon: const Icon(Icons.logout_rounded,
                      size: AppTheme.iconSm),
                  label: const Text('Sign Out'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                  ),
                ),
              ],
            ),
          ),
          // ── Content ───────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _ErrorView(
                        message: _error!,
                        onRetry: _loadTracks,
                      )
                    : SingleChildScrollView(
                        padding:
                            const EdgeInsets.all(AppTheme.spacingXl),
                        child: ConstrainedBox(
                          constraints:
                              const BoxConstraints(maxWidth: 900),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('My Tracks',
                                            style: theme.textTheme
                                                .headlineMedium),
                                        const SizedBox(
                                            height:
                                                AppTheme.spacingXs),
                                        Text(
                                          '${_tracks.length} track${_tracks.length == 1 ? '' : 's'} in your catalog',
                                          style: theme.textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                  color: colors
                                                      .subtleText),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        context.go('/web/creator'),
                                    icon: const Icon(
                                        Icons.add_rounded,
                                        size: AppTheme.iconSm),
                                    label:
                                        const Text('Upload New'),
                                    style: ElevatedButton.styleFrom(
                                      minimumSize:
                                          const Size(0, 40),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                  height: AppTheme.spacingXl),

                              if (_tracks.isEmpty)
                                _EmptyState(
                                  onUpload: () =>
                                      context.go('/web/creator'),
                                )
                              else
                                ..._tracks.map((track) => _TrackRow(
                                      track: track,
                                      formattedDuration:
                                          _formatDuration(track[
                                                  'duration_ms']
                                              as int?),
                                      onDelete: () =>
                                          _confirmDelete(track),
                                    )),
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Track Row ─────────────────────────────────────────────────────────────────

class _TrackRow extends StatelessWidget {
  final Map<String, dynamic> track;
  final String formattedDuration;
  final VoidCallback onDelete;

  const _TrackRow({
    required this.track,
    required this.formattedDuration,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    final artUrl = track['art_url']?.toString() ?? '';
    final title = track['title']?.toString() ?? 'Untitled';
    final albumTitle = track['album_title']?.toString() ?? '';
    final genre = track['genre']?.toString() ?? '';
    final isAi = track['is_ai_created'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          // Artwork
          ClipRRect(
            borderRadius:
                BorderRadius.circular(AppTheme.radiusSmall),
            child: artUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: artUrl,
                    width: AppTheme.albumArtSmall,
                    height: AppTheme.albumArtSmall,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _ArtPlaceholder(),
                  )
                : _ArtPlaceholder(),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isAi) ...[
                      const SizedBox(width: AppTheme.spacingXs),
                      Icon(
                        Icons.auto_awesome,
                        size: AppTheme.iconSm,
                        color: theme.colorScheme.secondary,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppTheme.spacingXxs),
                Text(
                  [
                    if (albumTitle.isNotEmpty) albumTitle,
                    if (genre.isNotEmpty) genre,
                    formattedDuration,
                  ].join(' · '),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colors.subtleText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          // Delete button
          IconButton(
            onPressed: onDelete,
            icon: Icon(Icons.delete_outline_rounded,
                color: colors.danger),
            tooltip: 'Delete track',
          ),
        ],
      ),
    );
  }
}

class _ArtPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: AppTheme.albumArtSmall,
      height: AppTheme.albumArtSmall,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.music_note_rounded,
        color: theme.colorScheme.onSurface
            .withOpacity(AppTheme.opacityDisabled),
        size: AppTheme.iconMd,
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onUpload;
  const _EmptyState({required this.onUpload});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXxl),
        child: Column(
          children: [
            Icon(
              Icons.library_music_outlined,
              size: AppTheme.iconXl,
              color: colors.subtleText,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'No tracks yet',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              'Upload your first track to get started.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: colors.subtleText),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            ElevatedButton.icon(
              onPressed: onUpload,
              icon: const Icon(Icons.upload_rounded,
                  size: AppTheme.iconSm),
              label: const Text('Upload Music'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, AppTheme.buttonHeight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error View ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: AppTheme.iconXl, color: colors.danger),
            const SizedBox(height: AppTheme.spacingMd),
            Text(message,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: colors.subtleText),
                textAlign: TextAlign.center),
            const SizedBox(height: AppTheme.spacingLg),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

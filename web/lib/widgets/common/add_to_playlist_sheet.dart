import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/library_provider.dart';
import '../../theme/theme.dart';

class AddToPlaylistSheet extends StatefulWidget {
  final String trackId;
  final String trackTitle;

  const AddToPlaylistSheet({
    super.key,
    required this.trackId,
    required this.trackTitle,
  });

  static Future<void> show(
    BuildContext context, {
    required String trackId,
    required String trackTitle,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddToPlaylistSheet(
        trackId: trackId,
        trackTitle: trackTitle,
      ),
    );
  }

  @override
  State<AddToPlaylistSheet> createState() => _AddToPlaylistSheetState();
}

class _AddToPlaylistSheetState extends State<AddToPlaylistSheet> {
  final _controller = TextEditingController();
  bool _showCreate = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    final library = context.watch<LibraryProvider>();
    final playlists = library.playlists;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spacingMd,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: AppTheme.spacingMd),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline,
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingMd,
              AppTheme.spacingMd,
              AppTheme.spacingMd,
              AppTheme.spacingSm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add to Playlist',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  widget.trackTitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.subtleText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (playlists.isEmpty && !_showCreate)
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Center(
                child: Text(
                  'No playlists yet',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.subtleText,
                  ),
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: playlists.length,
                itemBuilder: (context, i) {
                  final pl = playlists[i];
                  final alreadyAdded = pl.trackIds.contains(widget.trackId);
                  return ListTile(
                    leading: Container(
                      width: AppTheme.albumArtSmall,
                      height: AppTheme.albumArtSmall,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colors.gradient1, colors.gradient2],
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: Icon(
                        Icons.queue_music_rounded,
                        color: theme.colorScheme.onPrimary,
                        size: AppTheme.iconMd,
                      ),
                    ),
                    title: Text(
                      pl.name,
                      style: theme.textTheme.bodyMedium,
                    ),
                    subtitle: Text(
                      '${pl.trackIds.length} tracks',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.subtleText,
                      ),
                    ),
                    trailing: alreadyAdded
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: colors.success,
                            size: AppTheme.iconMd,
                          )
                        : null,
                    onTap: alreadyAdded
                        ? null
                        : () {
                            library.addTrackToPlaylist(pl.id, widget.trackId);
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Added to ${pl.name}'),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                  );
                },
              ),
            ),
          if (_showCreate)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd,
                vertical: AppTheme.spacingSm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Playlist name…',
                      ),
                      onSubmitted: (_) => _createAndAdd(context),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  IconButton.filled(
                    onPressed: () => _createAndAdd(context),
                    icon: const Icon(Icons.check_rounded),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: AppTheme.spacingSm,
            ),
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _showCreate = !_showCreate),
              icon: Icon(
                _showCreate ? Icons.close_rounded : Icons.add_rounded,
                size: AppTheme.iconMd,
              ),
              label: Text(_showCreate ? 'Cancel' : 'New Playlist'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, AppTheme.buttonHeight),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _createAndAdd(BuildContext context) {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    final library = context.read<LibraryProvider>();
    library.createPlaylist(name);
    final created = library.playlists.last;
    library.addTrackToPlaylist(created.id, widget.trackId);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added to $name'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

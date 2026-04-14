import 'package:flutter/material.dart';
import '../../models/album.dart';
import '../../models/search_filter.dart';
import '../../theme/theme.dart';

class SearchFilterSheet extends StatefulWidget {
  final SearchFilter initialFilter;
  final List<String> genres;
  final List<String> moods;
  final List<int> years;
  final ValueChanged<SearchFilter> onApply;

  const SearchFilterSheet({
    super.key,
    required this.initialFilter,
    required this.genres,
    required this.moods,
    required this.years,
    required this.onApply,
  });

  @override
  State<SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends State<SearchFilterSheet> {
  late SearchFilter _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialFilter;
  }

  void _patch(SearchFilter updated) => setState(() => _draft = updated);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusLarge),
          ),
        ),
        child: Column(
          children: [
            // drag handle
            Padding(
              padding: const EdgeInsets.only(top: AppTheme.spacingSm),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd,
                vertical: AppTheme.spacingSm,
              ),
              child: Row(
                children: [
                  Text('Filter', style: text.titleMedium),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _patch(const SearchFilter()),
                    child: Text(
                      'Clear all',
                      style: text.labelMedium?.copyWith(
                        color: appColors.gradient2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // scrollable content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                children: [
                  // ── Genre ──────────────────────────────────────────
                  _SectionLabel(label: 'Genre'),
                  _ChipWrap(
                    items: widget.genres,
                    selected: _draft.genre,
                    onSelect: (v) => _patch(
                      _draft.copyWith(genre: _draft.genre == v ? null : v),
                    ),
                    colors: colors,
                    appColors: appColors,
                    text: text,
                  ),
                  const SizedBox(height: AppTheme.spacingMd),

                  // ── Mood ───────────────────────────────────────────
                  _SectionLabel(label: 'Mood'),
                  _ChipWrap(
                    items: widget.moods,
                    selected: _draft.mood,
                    onSelect: (v) => _patch(
                      _draft.copyWith(mood: _draft.mood == v ? null : v),
                    ),
                    colors: colors,
                    appColors: appColors,
                    text: text,
                  ),
                  const SizedBox(height: AppTheme.spacingMd),

                  // ── Content Type ───────────────────────────────────
                  _SectionLabel(label: 'Content Type'),
                  _ChipWrap(
                    items: const ['Single', 'EP', 'Album'],
                    selected: _draft.contentType == null
                        ? null
                        : _albumTypeLabel(_draft.contentType!),
                    onSelect: (v) {
                      final type = _labelToAlbumType(v);
                      _patch(_draft.copyWith(
                        contentType:
                            _draft.contentType == type ? null : type,
                      ));
                    },
                    colors: colors,
                    appColors: appColors,
                    text: text,
                  ),
                  const SizedBox(height: AppTheme.spacingMd),

                  // ── Release Year ───────────────────────────────────
                  _SectionLabel(label: 'Release Year'),
                  _YearRangeRow(
                    years: widget.years,
                    from: _draft.releaseYearFrom,
                    to: _draft.releaseYearTo,
                    onFromChanged: (v) => _patch(_draft.copyWith(releaseYearFrom: v)),
                    onToChanged: (v) => _patch(_draft.copyWith(releaseYearTo: v)),
                    colors: colors,
                    appColors: appColors,
                    text: text,
                  ),
                  const SizedBox(height: AppTheme.spacingMd),

                  // ── Toggle filters ─────────────────────────────────
                  _SectionLabel(label: 'Content Flags'),
                  _ToggleRow(
                    label: 'Explicit content',
                    subtitle: 'Show only explicit tracks',
                    value: _draft.isExplicit,
                    onChanged: (v) => _patch(_draft.copyWith(isExplicit: v)),
                    colors: colors,
                    appColors: appColors,
                    text: text,
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  _ToggleRow(
                    label: 'AI-created music',
                    subtitle: 'Show only AI or AI-assisted music',
                    value: _draft.isAiCreated,
                    onChanged: (v) => _patch(_draft.copyWith(isAiCreated: v)),
                    colors: colors,
                    appColors: appColors,
                    text: text,
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                ],
              ),
            ),
            // apply button
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingMd,
                  AppTheme.spacingSm,
                  AppTheme.spacingMd,
                  AppTheme.spacingMd,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [appColors.gradient1, appColors.gradient2],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: TextButton(
                      onPressed: () {
                        widget.onApply(_draft);
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppTheme.spacingMd),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                      ),
                      child: Text(
                        'Apply Filters',
                        style: text.labelLarge?.copyWith(
                          color: colors.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _albumTypeLabel(AlbumType type) {
    switch (type) {
      case AlbumType.single:
        return 'Single';
      case AlbumType.ep:
        return 'EP';
      case AlbumType.album:
        return 'Album';
    }
  }

  AlbumType _labelToAlbumType(String label) {
    switch (label) {
      case 'EP':
        return AlbumType.ep;
      case 'Album':
        return AlbumType.album;
      default:
        return AlbumType.single;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _ChipWrap extends StatelessWidget {
  final List<String> items;
  final String? selected;
  final ValueChanged<String> onSelect;
  final ColorScheme colors;
  final AppColorsExtension appColors;
  final TextTheme text;

  const _ChipWrap({
    required this.items,
    required this.selected,
    required this.onSelect,
    required this.colors,
    required this.appColors,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppTheme.spacingXs,
      runSpacing: AppTheme.spacingXs,
      children: items.map((item) {
        final isSelected = item == selected;
        return GestureDetector(
          onTap: () => onSelect(item),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: AppTheme.spacingXs,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? appColors.gradient1.withValues(alpha: AppTheme.opacityOverlay)
                  : colors.surfaceContainerHighest,
              border: Border.all(
                color: isSelected ? appColors.gradient1 : colors.outline,
                width: isSelected ? AppTheme.borderSelected : AppTheme.borderDefault,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            ),
            child: Text(
              item,
              style: text.labelMedium?.copyWith(
                color: isSelected ? appColors.gradient1 : colors.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _YearRangeRow extends StatelessWidget {
  final List<int> years;
  final int? from;
  final int? to;
  final ValueChanged<int?> onFromChanged;
  final ValueChanged<int?> onToChanged;
  final ColorScheme colors;
  final AppColorsExtension appColors;
  final TextTheme text;

  const _YearRangeRow({
    required this.years,
    required this.from,
    required this.to,
    required this.onFromChanged,
    required this.onToChanged,
    required this.colors,
    required this.appColors,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    // Build dropdown list with a null/any option first
    final items = [
      DropdownMenuItem<int>(
        value: null,
        child: Text('Any', style: text.bodyMedium?.copyWith(color: colors.onSurface)),
      ),
      ...years.map(
        (y) => DropdownMenuItem<int>(
          value: y,
          child: Text('$y', style: text.bodyMedium?.copyWith(color: colors.onSurface)),
        ),
      ),
    ];

    final dropdownDecoration = BoxDecoration(
      color: colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      border: Border.all(color: colors.outline, width: AppTheme.borderDefault),
    );

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('From', style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
              const SizedBox(height: AppTheme.spacingXs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSm),
                decoration: dropdownDecoration,
                child: DropdownButton<int>(
                  value: from,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  dropdownColor: colors.surfaceContainer,
                  items: items,
                  onChanged: onFromChanged,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppTheme.spacingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('To', style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
              const SizedBox(height: AppTheme.spacingXs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSm),
                decoration: dropdownDecoration,
                child: DropdownButton<int>(
                  value: to,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  dropdownColor: colors.surfaceContainer,
                  items: items,
                  onChanged: onToChanged,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool? value;
  final ValueChanged<bool?> onChanged;
  final ColorScheme colors;
  final AppColorsExtension appColors;
  final TextTheme text;

  const _ToggleRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.colors,
    required this.appColors,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    // Three-state: null = any, true = yes, false = no
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingMd,
              AppTheme.spacingSm,
              AppTheme.spacingXs,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: text.bodyMedium
                              ?.copyWith(color: colors.onSurface)),
                      Text(subtitle,
                          style: text.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Show/Hide/Any segmented selector
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingSm),
            child: Row(
              children: [
                _SegmentButton(
                  label: 'Any',
                  isSelected: value == null,
                  onTap: () => onChanged(null),
                  colors: colors,
                  appColors: appColors,
                  text: text,
                ),
                const SizedBox(width: AppTheme.spacingXs),
                _SegmentButton(
                  label: 'Yes',
                  isSelected: value == true,
                  onTap: () => onChanged(value == true ? null : true),
                  colors: colors,
                  appColors: appColors,
                  text: text,
                ),
                const SizedBox(width: AppTheme.spacingXs),
                _SegmentButton(
                  label: 'No',
                  isSelected: value == false,
                  onTap: () => onChanged(value == false ? null : false),
                  colors: colors,
                  appColors: appColors,
                  text: text,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colors;
  final AppColorsExtension appColors;
  final TextTheme text;

  const _SegmentButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.colors,
    required this.appColors,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingXs,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? appColors.gradient1.withValues(alpha: AppTheme.opacityOverlay)
              : colors.surface,
          border: Border.all(
            color: isSelected ? appColors.gradient1 : colors.outlineVariant,
            width: isSelected ? AppTheme.borderSelected : AppTheme.borderDefault,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        ),
        child: Text(
          label,
          style: text.labelMedium?.copyWith(
            color: isSelected ? appColors.gradient1 : colors.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

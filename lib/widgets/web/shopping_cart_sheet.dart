import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../theme/theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ShoppingCartSheet extends StatelessWidget {
  const ShoppingCartSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<CartProvider>(),
        child: const ShoppingCartSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    final cart = context.watch<CartProvider>();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusXl),
          ),
        ),
        child: Column(
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
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Row(
                children: [
                  Text('Your Cart', style: theme.textTheme.titleMedium),
                  const SizedBox(width: AppTheme.spacingSm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingSm,
                      vertical: AppTheme.spacingXxs,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    ),
                    child: Text(
                      '${cart.itemCount}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (cart.itemCount > 0)
                    TextButton(
                      onPressed: cart.clear,
                      child: Text(
                        'Clear All',
                        style: TextStyle(color: colors.danger),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (cart.items.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: AppTheme.iconXl,
                        color: colors.subtleText,
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      Text(
                        'Your cart is empty',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colors.subtleText,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.spacingSm,
                  ),
                  itemCount: cart.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final item = cart.items[i];
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        child: CachedNetworkImage(
                          imageUrl: item.artUrl,
                          width: AppTheme.albumArtSmall,
                          height: AppTheme.albumArtSmall,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(
                        item.title,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${item.artistName} · ${item.licenseLabel}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.subtleText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.priceLabel,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: colors.gradient2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingXs),
                          IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              size: AppTheme.iconSm,
                              color: colors.subtleText,
                            ),
                            onPressed: () => cart.removeItem(item.id),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            if (cart.itemCount > 0)
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total', style: theme.textTheme.titleSmall),
                        Text(
                          cart.totalLabel,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colors.gradient2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Checkout coming soon — payment gateway integration required.',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        minimumSize: const Size(double.infinity, AppTheme.buttonHeight),
                      ),
                      child: const Text('Proceed to Checkout'),
                    ),
                    const SizedBox(height: AppTheme.spacingXs),
                    Text(
                      'Secure checkout — powered by XILO Music',
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
    );
  }
}

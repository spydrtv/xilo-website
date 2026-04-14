enum CartItemType { track, album, ep, single }
enum LicenseType { none, personal, commercial, sync }

class CartItem {
  final String id;
  final String title;
  final String artistName;
  final String artUrl;
  final double price;
  final CartItemType itemType;
  final LicenseType licenseType;
  final String sourceId;

  const CartItem({
    required this.id,
    required this.title,
    required this.artistName,
    required this.artUrl,
    required this.price,
    required this.itemType,
    required this.sourceId,
    this.licenseType = LicenseType.none,
  });

  String get licenseLabel {
    switch (licenseType) {
      case LicenseType.none:
        return 'Purchase';
      case LicenseType.personal:
        return 'Personal License';
      case LicenseType.commercial:
        return 'Commercial License';
      case LicenseType.sync:
        return 'Sync License';
    }
  }

  String get priceLabel => '\$${price.toStringAsFixed(2)}';
}

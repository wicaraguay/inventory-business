/// A sellable item (flat model): name + optional detail + stock + prices.
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.sku,
    this.detail,
    this.lowStockThreshold = 0,
    this.currentStock = 0,
    this.salePrice,
    this.minPrice,
    this.hasImage = false,
    this.imageVersion = 0,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        name: json['name'] as String,
        sku: json['sku'] as String,
        detail: json['detail'] as String?,
        lowStockThreshold: json['lowStockThreshold'] as int? ?? 0,
        currentStock: json['currentStock'] as int? ?? 0,
        salePrice: (json['salePrice'] as num?)?.toDouble(),
        minPrice: (json['minPrice'] as num?)?.toDouble(),
        hasImage: json['hasImage'] as bool? ?? false,
        imageVersion: json['imageVersion'] as int? ?? 0,
      );

  final String id;
  final String name;
  final String? detail;
  final String sku;
  final int lowStockThreshold;
  final int currentStock;
  final double? salePrice;
  final double? minPrice;

  /// Whether this product has an uploaded image.
  final bool hasImage;

  /// Bumps when the image changes — used to cache-bust the image URL.
  final int imageVersion;
}

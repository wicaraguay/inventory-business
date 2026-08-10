/// One size of a model with its stock — used to list the "available sizes" of a
/// model when scanning at the register.
class ModelSize {
  const ModelSize({required this.label, required this.currentStock});

  factory ModelSize.fromJson(Map<String, dynamic> json) => ModelSize(
        label: (json['label'] as String?) ?? '',
        currentStock: json['currentStock'] as int? ?? 0,
      );

  final String label;
  final int currentStock;
}

/// A sellable item (flat model): name + optional detail + stock + prices.
/// Sizes of the same model share [modelId].
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
    this.supplierPrice,
    this.modelId,
    this.hasImage = false,
    this.imageVersion = 0,
    this.availableSizes = const [],
    this.labeled = true,
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
        supplierPrice: (json['supplierPrice'] as num?)?.toDouble(),
        modelId: json['modelId'] as String?,
        hasImage: json['hasImage'] as bool? ?? false,
        imageVersion: json['imageVersion'] as int? ?? 0,
        availableSizes: (json['sizes'] as List?)
                ?.map((e) => ModelSize.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        // Absent on endpoints that don't track it → treat as labeled (not
        // pending), so only the inventory list surfaces pending items.
        labeled: json['labeled'] as bool? ?? true,
      );

  final String id;
  final String name;
  final String? detail;
  final String sku;
  final int lowStockThreshold;
  final int currentStock;
  final double? salePrice;
  final double? minPrice;

  /// Cost price. Only present for the owner (the API hides it from employees).
  final double? supplierPrice;

  /// Groups the sizes of the same model.
  final String? modelId;

  /// Whether this product has an uploaded image.
  final bool hasImage;

  /// Bumps when the image changes — used to cache-bust the image URL.
  final int imageVersion;

  /// The model's sizes (with stock). Only populated when resolved by scanning.
  final List<ModelSize> availableSizes;

  /// Whether this product's QR label has been printed AND applied. New products
  /// are pending (false) until the owner marks them done.
  final bool labeled;
}

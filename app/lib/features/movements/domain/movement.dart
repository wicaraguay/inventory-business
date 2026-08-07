/// A stock movement in the history (read model on the client).
class Movement {
  const Movement({
    required this.productName,
    required this.sku,
    required this.isEntry,
    required this.quantity,
    required this.createdAt,
    this.detail,
    this.note,
  });

  factory Movement.fromJson(Map<String, dynamic> json) => Movement(
        productName: json['productName'] as String,
        detail: json['detail'] as String?,
        sku: json['sku'] as String,
        isEntry: (json['type'] as String) == 'entry',
        quantity: json['quantity'] as int,
        note: json['note'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  final String productName;
  final String? detail;
  final String sku;
  final bool isEntry;
  final int quantity;
  final String? note;
  final DateTime createdAt;
}

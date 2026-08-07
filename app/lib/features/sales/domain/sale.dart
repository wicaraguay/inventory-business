/// A registered sale (read model on the client).
class Sale {
  const Sale({
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    required this.createdAt,
    this.detail,
  });

  factory Sale.fromJson(Map<String, dynamic> json) => Sale(
        productName: json['productName'] as String,
        detail: json['detail'] as String?,
        sku: json['sku'] as String,
        quantity: json['quantity'] as int,
        unitPrice: (json['unitPrice'] as num).toDouble(),
        total: (json['total'] as num).toDouble(),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  final String productName;
  final String? detail;
  final String sku;
  final int quantity;
  final double unitPrice;
  final double total;
  final DateTime createdAt;
}

/// Aggregated sales figures.
class SalesSummary {
  const SalesSummary({
    required this.count,
    required this.totalAll,
    required this.totalToday,
    required this.totalMonth,
    required this.totalYear,
  });

  factory SalesSummary.fromJson(Map<String, dynamic> json) => SalesSummary(
        count: json['count'] as int,
        totalAll: (json['totalAll'] as num).toDouble(),
        totalToday: (json['totalToday'] as num).toDouble(),
        totalMonth: (json['totalMonth'] as num?)?.toDouble() ?? 0,
        totalYear: (json['totalYear'] as num?)?.toDouble() ?? 0,
      );

  final int count;
  final double totalAll;
  final double totalToday;
  final double totalMonth;
  final double totalYear;
}

/// One point of the sales time-series (a day or hour).
class SalesBucket {
  const SalesBucket({required this.bucket, required this.total});

  factory SalesBucket.fromJson(Map<String, dynamic> json) => SalesBucket(
        bucket: DateTime.parse(json['bucket'] as String),
        total: (json['total'] as num).toDouble(),
      );

  final DateTime bucket;
  final double total;
}

/// The sales history + its summary.
class SalesReport {
  const SalesReport({required this.records, required this.summary});

  final List<Sale> records;
  final SalesSummary summary;
}

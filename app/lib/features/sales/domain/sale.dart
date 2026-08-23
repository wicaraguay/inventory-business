/// A registered sale (read model on the client).
class Sale {
  const Sale({
    required this.id,
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    required this.createdAt,
    this.detail,
    this.description,
    this.sizeLabel,
    this.voidedAt,
    this.voidedBy,
  });

  factory Sale.fromJson(Map<String, dynamic> json) => Sale(
        id: (json['id'] as String?) ?? '',
        productName: json['productName'] as String,
        detail: json['detail'] as String?,
        description: json['description'] as String?,
        sizeLabel: json['sizeLabel'] as String?,
        sku: json['sku'] as String,
        quantity: json['quantity'] as int,
        unitPrice: (json['unitPrice'] as num).toDouble(),
        total: (json['total'] as num).toDouble(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        voidedAt: json['voidedAt'] == null
            ? null
            : DateTime.parse(json['voidedAt'] as String),
        voidedBy: json['voidedBy'] as String?,
      );

  final String id;
  final String productName;
  final String? detail;

  /// Free-text description of a quick sale (null for inventory sales).
  final String? description;

  /// Size label of a quick sale (null for inventory sales).
  final String? sizeLabel;
  final String sku;
  final int quantity;
  final double unitPrice;
  final double total;
  final DateTime createdAt;
  final DateTime? voidedAt;
  final String? voidedBy;

  bool get isVoided => voidedAt != null;
}

/// Aggregated sales figures. Each range carries revenue (`total*`) and the
/// estimated profit (`profit*` = revenue - cost). Profit fields default to 0
/// for tolerance with older backends.
class SalesSummary {
  const SalesSummary({
    required this.count,
    required this.totalAll,
    required this.totalToday,
    required this.totalWeek,
    required this.totalMonth,
    required this.totalQuarter,
    required this.totalYear,
    required this.profitToday,
    required this.profitWeek,
    required this.profitMonth,
    required this.profitQuarter,
    required this.profitYear,
  });

  factory SalesSummary.fromJson(Map<String, dynamic> json) {
    double d(String k) => (json[k] as num?)?.toDouble() ?? 0;
    return SalesSummary(
      count: json['count'] as int,
      totalAll: d('totalAll'),
      totalToday: d('totalToday'),
      totalWeek: d('totalWeek'),
      totalMonth: d('totalMonth'),
      totalQuarter: d('totalQuarter'),
      totalYear: d('totalYear'),
      profitToday: d('profitToday'),
      profitWeek: d('profitWeek'),
      profitMonth: d('profitMonth'),
      profitQuarter: d('profitQuarter'),
      profitYear: d('profitYear'),
    );
  }

  final int count;
  final double totalAll;
  final double totalToday;
  final double totalWeek;
  final double totalMonth;
  final double totalQuarter;
  final double totalYear;
  final double profitToday;
  final double profitWeek;
  final double profitMonth;
  final double profitQuarter;
  final double profitYear;
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

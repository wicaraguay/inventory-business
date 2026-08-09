/// A saved end-of-day cash close (arqueo).
class CashClose {
  const CashClose({
    required this.id,
    required this.openingFloat,
    required this.salesTotal,
    required this.counted,
    required this.difference,
    required this.closedAt,
    this.closedBy,
  });

  factory CashClose.fromJson(Map<String, dynamic> json) => CashClose(
        id: json['id'] as String,
        openingFloat: (json['openingFloat'] as num).toDouble(),
        salesTotal: (json['salesTotal'] as num).toDouble(),
        counted: (json['counted'] as num).toDouble(),
        difference: (json['difference'] as num).toDouble(),
        closedBy: json['closedBy'] as String?,
        closedAt: DateTime.parse(json['closedAt'] as String),
      );

  final String id;
  final double openingFloat;
  final double salesTotal;
  final double counted;
  final double difference;
  final String? closedBy;
  final DateTime closedAt;
}

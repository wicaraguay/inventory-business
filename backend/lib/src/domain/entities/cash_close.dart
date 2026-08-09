/// A saved end-of-day cash count (arqueo).
class CashClose {
  CashClose({
    required this.id,
    required this.openingFloat,
    required this.salesTotal,
    required this.counted,
    required this.difference,
    required this.closedAt,
    this.closedBy,
  });

  final String id;
  final double openingFloat;
  final double salesTotal;
  final double counted;
  final double difference;
  final String? closedBy;
  final DateTime closedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'openingFloat': openingFloat,
        'salesTotal': salesTotal,
        'counted': counted,
        'difference': difference,
        'closedBy': closedBy,
        'closedAt': closedAt.toIso8601String(),
      };
}

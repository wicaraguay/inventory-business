/// One point of the sales time-series (a day or an hour) with its total.
class SalesBucket {
  SalesBucket({required this.bucket, required this.total});

  final DateTime bucket;
  final double total;
}

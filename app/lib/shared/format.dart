/// Formats a money amount, e.g. 1999.9 -> "$1999.90". Null -> "—".
String money(double? value) => value == null ? '—' : '\$${value.toStringAsFixed(2)}';

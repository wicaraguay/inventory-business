import 'dart:math' as math;

import 'package:inventy_app/features/products/domain/product.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

const _mm = PdfPageFormat.mm;

/// How many label columns fit reasonably on an A4 sheet. Beyond this the QR
/// gets too small to scan comfortably.
const maxLabelColumns = 5;

/// One product label: QR encoding the SKU + name / detail / sku as text.
pw.Widget _labelBody(Product product, {double qrSizeMm = 20}) {
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      pw.BarcodeWidget(
        barcode: pw.Barcode.qrCode(),
        data: product.sku,
        width: qrSizeMm * _mm,
        height: qrSizeMm * _mm,
      ),
      pw.SizedBox(width: 1.5 * _mm),
      pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              product.name,
              style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold),
              maxLines: 2,
              overflow: pw.TextOverflow.clip,
            ),
            if (product.detail != null && product.detail!.isNotEmpty)
              pw.Text(
                product.detail!,
                style: const pw.TextStyle(fontSize: 5.5),
                maxLines: 1,
                overflow: pw.TextOverflow.clip,
              ),
            pw.Text(
              product.sku,
              style: const pw.TextStyle(fontSize: 6.5),
              maxLines: 1,
              overflow: pw.TextOverflow.clip,
            ),
          ],
        ),
      ),
    ],
  );
}

/// Print a single product's label (small page).
Future<void> printProductLabel({
  required String name,
  required String sku,
  String? detail,
}) async {
  final doc = pw.Document();
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat(50 * _mm, 30 * _mm, marginAll: 2 * _mm),
      build: (context) => _labelBody(
        Product(id: '', name: name, sku: sku, detail: detail),
      ),
    ),
  );
  await Printing.layoutPdf(onLayout: (_) => doc.save());
}

/// Print MANY product labels in a single PDF as a grid on A4. Each cell's width
/// is derived from [columns] so they always fit the page (more columns → smaller
/// labels). The QR shrinks with the columns but stays scannable; the text takes
/// whatever width is left. Cut along the borders.
Future<void> printProductLabels(
  List<Product> products, {
  int columns = 3,
}) async {
  final doc = pw.Document();

  const pageMarginMm = 8.0;
  const gapMm = 3.0;
  const usableWidthMm = 210 - pageMarginMm * 2; // A4 width - margins
  const usableHeightMm = 297 - pageMarginMm * 2; // A4 height - margins
  const cellHeightMm = 28.0;

  final cols = columns.clamp(1, maxLabelColumns);
  // Subtract a tiny safety margin so N columns + gaps stay STRICTLY under the
  // usable width — otherwise rounding pushes the last column to a new row
  // (e.g. 5 columns rendered as 4).
  final cellWidthMm =
      (usableWidthMm - (cols - 1) * gapMm) / cols - 0.6;
  final rowsPerPage = ((usableHeightMm + gapMm) / (cellHeightMm + gapMm)).floor();
  final perPage = cols * rowsPerPage;

  // QR stays between 12mm and 20mm — small enough for 5 columns, big enough
  // to scan from a phone.
  final qrSizeMm =
      math.min(cellHeightMm - 4, cellWidthMm * 0.45).clamp(12.0, 20.0);

  pw.Widget cell(Product p) => pw.Container(
        width: cellWidthMm * _mm,
        height: cellHeightMm * _mm,
        padding: pw.EdgeInsets.all(1.5 * _mm),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(width: 0.5, color: PdfColors.grey400),
        ),
        child: _labelBody(p, qrSizeMm: qrSizeMm),
      );

  for (var i = 0; i < products.length; i += perPage) {
    final end = math.min(i + perPage, products.length);
    final pageItems = products.sublist(i, end);
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(pageMarginMm * _mm),
        build: (context) => pw.Wrap(
          spacing: gapMm * _mm,
          runSpacing: gapMm * _mm,
          children: [for (final p in pageItems) cell(p)],
        ),
      ),
    );
  }

  await Printing.layoutPdf(onLayout: (_) => doc.save());
}

import 'dart:math' as math;

import 'package:inventy_app/features/products/domain/product.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

const _mm = PdfPageFormat.mm;

/// The ONE QR-grid column count, so every label is the same size whether you
/// print one, two, or the whole inventory. 11 keeps each QR ~12.3mm on A4 —
/// bigger than 12 columns (~10.8mm) so phone cameras read it more reliably.
const defaultLabelColumns = 11;

/// How many label columns fit reasonably on an A4 sheet WITH text beside the QR.
/// Beyond this the QR gets too small to scan comfortably.
const maxLabelColumns = 5;

/// QR-only labels are just the code, so they pack tighter. 15 is the practical
/// ceiling: beyond it the QR drops under ~7mm and gets unreliable to scan on
/// non-laser printers.
const maxLabelColumnsQrOnly = 15;

/// The numeric size at the end of a SKU (e.g. "ECO-35" -> "35"), or null when
/// the SKU doesn't end in a short number — so we never stamp a garbled centre.
String? _sizeLabel(Product p) {
  final dash = p.sku.lastIndexOf('-');
  final tail = (dash >= 0 ? p.sku.substring(dash + 1) : p.sku).trim();
  if (tail.isEmpty || tail.length > 3 || int.tryParse(tail) == null) return null;
  return tail;
}

/// One product label. By default it's JUST the QR (encoding the SKU), centered,
/// with the size number stamped in the middle so a pair is identifiable at a
/// glance. With [showText] the name / detail / sku are printed beside it.
pw.Widget _labelBody(
  Product product, {
  double qrSizeMm = 20,
  bool showText = false,
}) {
  final sizeLabel = _sizeLabel(product);
  // With a centre stamp, use HIGH error correction so the covered ~13% area
  // still scans; plain QRs stay LOW to keep the smallest modules readable.
  final qr = pw.BarcodeWidget(
    barcode: pw.Barcode.qrCode(
      errorCorrectLevel: sizeLabel != null
          ? pw.BarcodeQRCorrectionLevel.high
          : pw.BarcodeQRCorrectionLevel.low,
    ),
    data: product.sku,
    width: qrSizeMm * _mm,
    height: qrSizeMm * _mm,
  );
  final qrWidget = sizeLabel == null
      ? qr
      : pw.Stack(
          alignment: pw.Alignment.center,
          children: [
            qr,
            pw.Container(
              width: qrSizeMm * _mm * 0.36,
              height: qrSizeMm * _mm * 0.36,
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                border: pw.Border.all(width: 0.4),
              ),
              child: pw.FittedBox(
                fit: pw.BoxFit.scaleDown,
                child: pw.Text(
                  sizeLabel,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 8,
                  ),
                ),
              ),
            ),
          ],
        );
  if (!showText) return pw.Center(child: qrWidget);
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      qrWidget,
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

/// Print product labels in a single PDF as a fixed-column QR grid on A4 — the
/// ONE label format, so every QR is the same size whether you print one, two,
/// or the whole inventory. Prints ONE label per physical pair (a size with 4
/// pairs of stock yields 4 identical QRs). Returns how many labels were printed
/// (0 when nothing has stock, so callers can warn). Cut along the borders.
Future<int> printProductLabels(
  List<Product> products, {
  int columns = defaultLabelColumns,
  bool showText = false,
}) async {
  // One QR per pair: repeat each size as many times as its current stock.
  final labels = [
    for (final p in products)
      for (var i = 0; i < p.currentStock; i++) p,
  ];
  if (labels.isEmpty) return 0;

  final doc = pw.Document();

  const pageMarginMm = 8.0;
  const gapMm = 3.0;
  const usableWidthMm = 210 - pageMarginMm * 2; // A4 width - margins
  const usableHeightMm = 297 - pageMarginMm * 2; // A4 height - margins

  final cols =
      columns.clamp(1, showText ? maxLabelColumns : maxLabelColumnsQrOnly);
  // Subtract a tiny safety margin so N columns + gaps stay STRICTLY under the
  // usable width — otherwise rounding pushes the last column to a new row
  // (e.g. 12 columns rendered as 11).
  final cellWidthMm = (usableWidthMm - (cols - 1) * gapMm) / cols - 0.6;

  // Inner padding between the cell border and the QR/text.
  final padMm = showText ? 1.5 : 1.0;

  // QR size and cell height depend on the mode:
  // - With text: the cell is a fixed 28mm tall row; the QR shares the width.
  // - QR-only: the QR FILLS the cell width (minus padding) and the cell is a
  //   compact square, so nothing overflows even at 15 columns and we don't
  //   waste vertical paper. At 12 cols → ~10.4mm QR; at 15 → ~7.1mm.
  final double cellHeightMm;
  final double qrSizeMm;
  if (showText) {
    cellHeightMm = 28.0;
    qrSizeMm =
        math.min(cellHeightMm - padMm * 2, cellWidthMm * 0.45).clamp(12.0, 20.0);
  } else {
    qrSizeMm = (cellWidthMm - padMm * 2).clamp(6.0, 24.0);
    cellHeightMm = qrSizeMm + padMm * 2;
  }

  final rowsPerPage =
      ((usableHeightMm + gapMm) / (cellHeightMm + gapMm)).floor();
  final perPage = cols * rowsPerPage;

  pw.Widget cell(Product p) => pw.Container(
        width: cellWidthMm * _mm,
        height: cellHeightMm * _mm,
        padding: pw.EdgeInsets.all(padMm * _mm),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(width: 0.5, color: PdfColors.grey400),
        ),
        child: _labelBody(p, qrSizeMm: qrSizeMm, showText: showText),
      );

  for (var i = 0; i < labels.length; i += perPage) {
    final end = math.min(i + perPage, labels.length);
    final pageItems = labels.sublist(i, end);
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
  return labels.length;
}

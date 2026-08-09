import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inventy_app/shared/image/image_compressor.dart';
import 'package:inventy_app/shared/sku.dart';
import 'package:inventy_app/shared/theme/app_colors.dart';

/// One size row inside the bulk draft: a size label and how many pairs of it.
typedef BulkSizeDraft = ({String size, int quantity});

/// What the sheet returns: a model + shared prices + the list of sizes + one
/// optional image applied to every created size.
typedef BulkDraft = ({
  String name,
  String? color,
  String skuPrefix,
  double? salePrice,
  double? minPrice,
  double? supplierPrice,
  List<BulkSizeDraft> sizes,
  Uint8List? imageBytes,
});

/// The single "Agregar producto" flow: a model + its sizes (even one), one
/// shared image, and shared prices. Each size becomes its own product with its
/// own QR. The cost (supplier) price is shown only to the owner.
class BulkCreateSheet extends StatefulWidget {
  const BulkCreateSheet({this.showCost = false, super.key});

  /// Whether to show the supplier (cost) price field — owner only.
  final bool showCost;

  @override
  State<BulkCreateSheet> createState() => _BulkCreateSheetState();
}

class _BulkCreateSheetState extends State<BulkCreateSheet> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  // Kept but hidden: the QR code prefix, auto-derived from the model name.
  final _prefix = TextEditingController();
  final _salePrice = TextEditingController();
  final _minPrice = TextEditingController();
  final _supplierPrice = TextEditingController();

  // Range generator inputs.
  final _from = TextEditingController(text: '34');
  final _to = TextEditingController(text: '40');
  // Default 0 pairs: generate the WHOLE size run at zero stock, then bump the
  // ones you actually received. Avoids creating one-off products later.
  final _qtyEach = TextEditingController(text: '0');
  final _manualSize = TextEditingController();

  bool _prefixTouched = false;
  // size -> quantity, insertion-ordered so the list is stable.
  final _sizes = <String, int>{};

  // One optional image for the whole model (applied to every size).
  Uint8List? _imageBytes;

  Future<void> _pickImage() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (x == null) return;
    final bytes = await x.readAsBytes();
    final compressed = await compressImage(bytes);
    if (!mounted) return;
    setState(() => _imageBytes = compressed);
  }

  Widget _imageRow(TextStyle muted) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: _imageBytes != null
              ? Image.memory(_imageBytes!,
                  width: 64, height: 64, fit: BoxFit.cover)
              : Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.inputBorder),
                  ),
                  child: Icon(Icons.image_outlined,
                      color: AppColors.inputBorder),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Imagen del modelo (opcional)',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              Text('Se usa la misma para todas las tallas.', style: muted),
              const SizedBox(height: 6),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.upload_outlined, size: 18),
                    label: const Text('Subir imagen'),
                  ),
                  if (_imageBytes != null)
                    TextButton(
                      onPressed: () => setState(() => _imageBytes = null),
                      child: const Text('Quitar',
                          style: TextStyle(color: AppColors.danger)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    // Auto-fill the SKU prefix from the model name until the user edits it.
    _name.addListener(() {
      if (_prefixTouched) return;
      _prefix.text = _slug(_name.text);
    });
    _prefix.addListener(() {
      // Mark as touched only on real user edits (not our own auto-fill).
      if (_prefix.text != _slug(_name.text)) _prefixTouched = true;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _prefix.dispose();
    _salePrice.dispose();
    _minPrice.dispose();
    _supplierPrice.dispose();
    _from.dispose();
    _to.dispose();
    _qtyEach.dispose();
    _manualSize.dispose();
    super.dispose();
  }

  // A short, editable base code from the model name (e.g. "BOTCA").
  static String _slug(String v) => shortSku(v);

  double? _price(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : double.tryParse(t.replaceAll(',', '.'));
  }

  void _addSize(String raw) {
    final size = raw.trim();
    if (size.isEmpty) return;
    setState(() {
      final qty = int.tryParse(_qtyEach.text.trim()) ?? 0;
      _sizes[size] = _sizes[size] ?? (qty < 0 ? 0 : qty);
    });
  }

  void _generateRange() {
    final from = int.tryParse(_from.text.trim());
    final to = int.tryParse(_to.text.trim());
    final qty = int.tryParse(_qtyEach.text.trim()) ?? 0;
    if (from == null || to == null || from > to) {
      _snack('Rango de tallas inválido');
      return;
    }
    if (to - from > 60) {
      _snack('Rango demasiado grande');
      return;
    }
    setState(() {
      for (var n = from; n <= to; n++) {
        _sizes['$n'] = _sizes['$n'] ?? (qty < 0 ? 0 : qty);
      }
    });
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  int get _totalPairs => _sizes.values.fold(0, (a, b) => a + b);

  void _submit() {
    // The model field lives in a lazy ListView, so Form.validate() can skip it
    // when it's scrolled off-screen — check the controller directly.
    if (_name.text.trim().isEmpty) {
      _snack('El modelo es obligatorio');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_sizes.isEmpty) {
      _snack('Agregá al menos una talla');
      return;
    }
    final sale = _price(_salePrice);
    final min = _price(_minPrice);
    if (sale != null && min != null && min > sale) {
      _snack('El precio mínimo no puede ser mayor al de venta');
      return;
    }
    // The QR prefix is auto-derived and hidden; guard the rare empty case.
    var prefix = _prefix.text.trim();
    if (prefix.isEmpty) {
      final fb = _name.text.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
      prefix = fb.isEmpty ? 'ITEM' : fb.substring(0, fb.length.clamp(0, 6));
    }
    Navigator.of(context).pop((
      name: _name.text.trim(),
      color: null,
      skuPrefix: prefix,
      salePrice: sale,
      minPrice: min,
      supplierPrice: _price(_supplierPrice),
      sizes: [
        for (final e in _sizes.entries) (size: e.key, quantity: e.value),
      ],
      imageBytes: _imageBytes,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final muted = TextStyle(color: AppColors.onSurface.withValues(alpha: 0.6));
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 620),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Agregar producto',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Cargá el modelo y sus tallas (aunque sea una). Se comparten '
                'imagen y precios; cada talla queda con su propio QR.',
                style: muted,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    _imageRow(muted),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _name,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Modelo — ej. Bota de cuero alto',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'El modelo es obligatorio'
                          : null,
                    ),
                    if (widget.showCost) ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _supplierPrice,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Precio de proveedor (costo)',
                          helperText: 'Privado — solo lo ves vos (el propietario).',
                          helperStyle: muted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _salePrice,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: 'Precio de venta'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _minPrice,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: 'Precio mínimo'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Tallas',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    // Range generator: from / to / qty each.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(child: _numField(_from, 'Desde')),
                        const SizedBox(width: 8),
                        Expanded(child: _numField(_to, 'Hasta')),
                        const SizedBox(width: 8),
                        Expanded(child: _numField(_qtyEach, 'Pares c/u')),
                        const SizedBox(width: 8),
                        FilledButton.tonal(
                          onPressed: _generateRange,
                          child: const Text('Generar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Manual add: a single size not in the range.
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _manualSize,
                            decoration: const InputDecoration(
                              labelText: 'Agregar talla suelta',
                              hintText: 'ej. 41',
                            ),
                            onSubmitted: (v) {
                              _addSize(v);
                              _manualSize.clear();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          onPressed: () {
                            _addSize(_manualSize.text);
                            _manualSize.clear();
                          },
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_sizes.isEmpty)
                      Text('Todavía no agregaste tallas.', style: muted)
                    else
                      ..._sizes.keys.map(_sizeRow),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_sizes.length} tallas · $_totalPairs pares',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.qr_code_2),
                    label: const Text('Registrar e imprimir QR'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _numField(TextEditingController c, String label) => TextField(
        controller: c,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(labelText: label),
      );

  Widget _sizeRow(String size) {
    final qty = _sizes[size]!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 64,
            padding: const EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('T $size',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: qty <= 0
                ? null
                : () => setState(() => _sizes[size] = qty - 1),
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text('$qty', style: const TextStyle(fontWeight: FontWeight.w600)),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => setState(() => _sizes[size] = qty + 1),
            icon: const Icon(Icons.add_circle_outline),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => setState(() => _sizes.remove(size)),
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
          ),
        ],
      ),
    );
  }
}

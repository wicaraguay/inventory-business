import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inventy_app/features/products/domain/product.dart';
import 'package:inventy_app/shared/api/api_client.dart';
import 'package:inventy_app/shared/image/image_compressor.dart';
import 'package:inventy_app/shared/sku.dart';
import 'package:inventy_app/shared/theme/app_colors.dart';
import 'package:inventy_app/shared/ui/product_image.dart';

typedef NewProduct = ({
  String name,
  String sku,
  String? detail,
  int threshold,
  int initialStock,
  double? salePrice,
  double? minPrice,
  double? supplierPrice,
  Uint8List? imageBytes,
  bool removeImage,
});

/// Form to edit a product (fields prefilled). Returns a NewProduct on submit.
/// The supplier (cost) price is shown only when [showCost] (owner).
class CreateProductSheet extends StatefulWidget {
  const CreateProductSheet({
    required this.apiBaseUrl,
    this.initialThreshold = 0,
    this.showCost = false,
    this.product,
    super.key,
  });

  final String apiBaseUrl;
  final int initialThreshold;
  final bool showCost;
  final Product? product;

  @override
  State<CreateProductSheet> createState() => _CreateProductSheetState();
}

class _CreateProductSheetState extends State<CreateProductSheet> {
  final _formKey = GlobalKey<FormState>();

  late final _name = TextEditingController(text: widget.product?.name ?? '');
  late final _detail =
      TextEditingController(text: widget.product?.detail ?? '');
  late final _sku = TextEditingController(text: widget.product?.sku ?? '');
  late final _salePrice =
      TextEditingController(text: _fmt(widget.product?.salePrice));
  late final _minPrice =
      TextEditingController(text: _fmt(widget.product?.minPrice));
  late final _supplierPrice =
      TextEditingController(text: _fmt(widget.product?.supplierPrice));
  late final _threshold = TextEditingController(
    text: '${widget.product?.lowStockThreshold ?? widget.initialThreshold}',
  );
  // Only used when creating: how many units the product starts with.
  final _initialStock = TextEditingController(text: '0');

  static String _fmt(double? v) => v == null ? '' : v.toStringAsFixed(2);

  bool _skuTouched = false;

  // Newly picked/captured (already compressed) image bytes, and whether the
  // user asked to remove the existing one.
  Uint8List? _imageBytes;
  bool _removeImage = false;

  @override
  void initState() {
    super.initState();
    // On CREATE, suggest a short SKU from the name until the user edits it.
    // On EDIT, never auto-touch the existing code.
    if (widget.product == null) {
      _name.addListener(() {
        if (_skuTouched) return;
        _sku.text = shortSku(_name.text);
      });
      _sku.addListener(() {
        if (_sku.text != shortSku(_name.text)) _skuTouched = true;
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _detail.dispose();
    _sku.dispose();
    _salePrice.dispose();
    _minPrice.dispose();
    _supplierPrice.dispose();
    _threshold.dispose();
    _initialStock.dispose();
    super.dispose();
  }

  String? _clean(TextEditingController c) {
    final v = c.text.trim();
    return v.isEmpty ? null : v;
  }

  double? _price(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : double.tryParse(t.replaceAll(',', '.'));
  }

  bool get _showsExistingImage =>
      widget.product?.hasImage == true && !_removeImage && _imageBytes == null;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final x = await ImagePicker().pickImage(source: source, imageQuality: 85);
      if (x == null) return;
      final bytes = await x.readAsBytes();
      final compressed = await compressImage(bytes);
      if (!mounted) return;
      setState(() {
        _imageBytes = compressed;
        _removeImage = false;
      });
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('No se pudo abrir la cámara o la galería.')));
      }
    }
  }

  void _clearImage() {
    setState(() {
      _imageBytes = null;
      _removeImage = true;
    });
  }

  void _submit() {
    // The name lives in a lazy ListView; check it directly (Form.validate()
    // skips off-screen fields).
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El nombre es obligatorio')));
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    var sku = _sku.text.trim();
    // Create mode hides the SKU field: it's auto-derived from the name. Guard
    // the rare case where the name has no usable letters (e.g. only symbols).
    if (widget.product == null && sku.isEmpty) {
      final fallback =
          _name.text.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
      sku = fallback.isEmpty
          ? 'ITEM'
          : fallback.substring(0, fallback.length.clamp(0, 6));
    }
    Navigator.of(context).pop((
      name: _name.text.trim(),
      sku: sku,
      detail: _clean(_detail),
      threshold: int.tryParse(_threshold.text.trim()) ?? 0,
      initialStock: int.tryParse(_initialStock.text.trim()) ?? 0,
      salePrice: _price(_salePrice),
      minPrice: _price(_minPrice),
      supplierPrice: _price(_supplierPrice),
      imageBytes: _imageBytes,
      removeImage: _removeImage,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 640),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEdit ? 'Editar producto' : 'Nuevo producto',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    _imageSection(),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _name,
                      autofocus: true,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'El nombre es obligatorio'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _detail,
                      decoration: const InputDecoration(
                        labelText: 'Detalle (opcional) — ej. Talla 40 · negro',
                      ),
                    ),
                    // The SKU is auto-generated from the name and goes into the
                    // QR. Hidden on CREATE (one less field for the owner); shown
                    // on EDIT in case the code needs a manual fix.
                    if (isEdit) ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _sku,
                        decoration: const InputDecoration(
                          labelText: 'Código interno / SKU (va en el QR)',
                          helperText: 'Se generó desde el nombre',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'El código es obligatorio'
                            : null,
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
                    if (widget.showCost) ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _supplierPrice,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Precio de proveedor (costo)',
                          helperText: 'Privado — solo lo ve el dueño.',
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    if (!isEdit) ...[
                      TextFormField(
                        controller: _initialStock,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Stock inicial',
                          helperText:
                              'Cantidad con la que empieza el producto',
                        ),
                        validator: (v) {
                          final n = int.tryParse((v ?? '').trim());
                          if (n == null || n < 0) {
                            return 'Ingresá un número válido (>= 0)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                    // The low-stock threshold is a single GLOBAL setting now
                    // (Configuración → Preferencias), so it's not asked here.
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _submit,
                child: Text(isEdit ? 'Guardar' : 'Crear'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageSection() {
    final hasImage = _imageBytes != null || _showsExistingImage;
    return Column(
      children: [
        Center(child: _preview()),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: [
            FilledButton.tonalIcon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.photo_camera_outlined, size: 18),
              label: const Text('Tomar foto'),
            ),
            OutlinedButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined, size: 18),
              label: const Text('Galería'),
            ),
          ],
        ),
        if (hasImage)
          TextButton.icon(
            onPressed: _clearImage,
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            label: const Text('Quitar imagen',
                style: TextStyle(color: AppColors.danger)),
          ),
      ],
    );
  }

  Widget _preview() {
    const size = 120.0;
    final radius = BorderRadius.circular(12);
    Widget frame(Widget child) => ClipRRect(
          borderRadius: radius,
          child: SizedBox(width: size, height: size, child: child),
        );

    if (_imageBytes != null) {
      return frame(Image.memory(_imageBytes!, fit: BoxFit.cover));
    }
    if (_showsExistingImage) {
      return frame(Image.network(
        productImageUrl(widget.apiBaseUrl, widget.product!),
        headers: apiAuthHeaders,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(size),
      ));
    }
    return _placeholder(size);
  }

  Widget _placeholder(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Icon(Icons.add_a_photo_outlined,
            color: AppColors.inputBorder, size: 32),
      );
}

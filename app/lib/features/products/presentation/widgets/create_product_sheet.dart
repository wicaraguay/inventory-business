import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inventy_app/features/products/domain/product.dart';
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
  Uint8List? imageBytes,
  bool removeImage,
});

/// Form to create OR edit a product. If [product] is given, it's edit mode
/// (fields prefilled). Returns a NewProduct on submit.
class CreateProductSheet extends StatefulWidget {
  const CreateProductSheet({
    required this.apiBaseUrl,
    this.initialThreshold = 0,
    this.product,
    super.key,
  });

  final String apiBaseUrl;
  final int initialThreshold;
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

  Future<void> _pickFile() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (x == null) return;
    final bytes = await x.readAsBytes();
    final compressed = await compressImage(bytes);
    if (!mounted) return;
    setState(() {
      _imageBytes = compressed;
      _removeImage = false;
    });
  }

  void _clearImage() {
    setState(() {
      _imageBytes = null;
      _removeImage = true;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop((
      name: _name.text.trim(),
      sku: _sku.text.trim(),
      detail: _clean(_detail),
      threshold: int.tryParse(_threshold.text.trim()) ?? 0,
      initialStock: int.tryParse(_initialStock.text.trim()) ?? 0,
      salePrice: _price(_salePrice),
      minPrice: _price(_minPrice),
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
                        labelText: 'Detalle (opcional) — ej. talle 40 · negro',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _sku,
                      decoration: const InputDecoration(
                        labelText: 'Código interno / SKU (va en el QR)',
                        helperText:
                            'Se genera solo desde el nombre — podés editarlo',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'El código es obligatorio'
                          : null,
                    ),
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
                    TextFormField(
                      controller: _threshold,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Umbral de stock bajo (alerta)',
                        helperText:
                            'Te avisa cuando el stock baja de este número',
                      ),
                      validator: (v) {
                        final n = int.tryParse((v ?? '').trim());
                        if (n == null || n < 0) {
                          return 'Ingresá un número válido (>= 0)';
                        }
                        return null;
                      },
                    ),
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
        OutlinedButton.icon(
          onPressed: _pickFile,
          icon: const Icon(Icons.upload_outlined),
          label: const Text('Subir imagen'),
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
        child: const Icon(Icons.add_a_photo_outlined,
            color: AppColors.inputBorder, size: 32),
      );
}

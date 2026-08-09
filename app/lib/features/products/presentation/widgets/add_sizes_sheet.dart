import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventy_app/features/products/presentation/widgets/bulk_create_sheet.dart'
    show BulkSizeDraft;
import 'package:inventy_app/shared/theme/app_colors.dart';

/// Sheet to add MORE sizes to an existing model. Same size-generator as the
/// bulk create, but prices/image are inherited from the model (not asked here).
/// Returns the chosen sizes (size + initial stock, default 0).
class AddSizesSheet extends StatefulWidget {
  const AddSizesSheet({required this.modelName, super.key});

  final String modelName;

  @override
  State<AddSizesSheet> createState() => _AddSizesSheetState();
}

class _AddSizesSheetState extends State<AddSizesSheet> {
  final _from = TextEditingController(text: '34');
  final _to = TextEditingController(text: '40');
  final _qtyEach = TextEditingController(text: '0');
  final _manualSize = TextEditingController();

  // size -> quantity, insertion-ordered.
  final _sizes = <String, int>{};

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    _qtyEach.dispose();
    _manualSize.dispose();
    super.dispose();
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

  void _submit() {
    if (_sizes.isEmpty) {
      _snack('Agregá al menos una talla');
      return;
    }
    Navigator.of(context).pop(<BulkSizeDraft>[
      for (final e in _sizes.entries) (size: e.key, quantity: e.value),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final muted = TextStyle(color: AppColors.onSurface.withValues(alpha: 0.6));
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Agregar tallas',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              '${widget.modelName} · las nuevas tallas heredan precios e imagen '
              'del modelo y arrancan en 0 stock.',
              style: muted,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                shrinkWrap: true,
                children: [
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
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _manualSize,
                          decoration: const InputDecoration(
                            labelText: 'Agregar talla suelta',
                            hintText: 'ej. 35',
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
                Text('${_sizes.length} tallas nuevas',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.qr_code_2),
                  label: const Text('Agregar e imprimir QR'),
                ),
              ],
            ),
          ],
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
            onPressed:
                qty <= 0 ? null : () => setState(() => _sizes[size] = qty - 1),
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

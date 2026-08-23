import 'package:flutter/material.dart';
import 'package:inventy_app/shared/format.dart';
import 'package:inventy_app/shared/theme/app_colors.dart';

/// The data the sheet returns when the user confirms a quick sale.
typedef QuickSaleInput = ({
  int quantity,
  double total,
  String description,
  String? sizeLabel,
  DateTime? date,
});

/// Bottom-sheet form for adding (or editing) a quick-sale line.
///
/// This is a pure presentational widget: it receives optional initial values and
/// calls [onConfirm] with the result. The caller is responsible for wiring the
/// notifier.
class QuickSaleSheet extends StatefulWidget {
  const QuickSaleSheet({
    this.initialQuantity = 1,
    this.initialTotal,
    this.initialDescription = '',
    this.initialSizeLabel = '',
    this.initialDate,
    this.isEditing = false,
    super.key,
  });

  final int initialQuantity;
  final double? initialTotal;
  final String initialDescription;
  final String initialSizeLabel;
  final DateTime? initialDate;
  final bool isEditing;

  @override
  State<QuickSaleSheet> createState() => _QuickSaleSheetState();
}

class _QuickSaleSheetState extends State<QuickSaleSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _quantity;
  late final TextEditingController _total;
  late final TextEditingController _description;
  late final TextEditingController _sizeLabel;
  late DateTime? _date;

  @override
  void initState() {
    super.initState();
    _quantity =
        TextEditingController(text: '${widget.initialQuantity}');
    _total = TextEditingController(
      text: widget.initialTotal != null
          ? widget.initialTotal!.toStringAsFixed(2)
          : '',
    );
    _description =
        TextEditingController(text: widget.initialDescription);
    _sizeLabel = TextEditingController(text: widget.initialSizeLabel);
    _date = widget.initialDate;
  }

  @override
  void dispose() {
    _quantity.dispose();
    _total.dispose();
    _description.dispose();
    _sizeLabel.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Fecha de la venta',
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _clearDate() => setState(() => _date = null);

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final qty = int.parse(_quantity.text.trim());
    final tot =
        double.parse(_total.text.trim().replaceAll(',', '.'));
    Navigator.of(context).pop<QuickSaleInput>((
      quantity: qty,
      total: tot,
      description: _description.text.trim(),
      sizeLabel: _sizeLabel.text.trim().isEmpty
          ? null
          : _sizeLabel.text.trim(),
      date: _date,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isToday = _date == null;
    final dateLabel = isToday
        ? 'Hoy'
        : '${_date!.day.toString().padLeft(2, '0')}/'
            '${_date!.month.toString().padLeft(2, '0')}/'
            '${_date!.year}';

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.shopping_bag_outlined,
                    color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  widget.isEditing
                      ? 'Editar venta rápida'
                      : 'Venta rápida',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- Description (required) ---
            TextFormField(
              controller: _description,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Descripción *',
                hintText: 'Ej: Botín de cuero negro',
                prefixIcon: Icon(Icons.label_outline),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'La descripción es obligatoria';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // --- Quantity + Total side by side ---
            Row(
              children: [
                SizedBox(
                  width: 110,
                  child: TextFormField(
                    controller: _quantity,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Cantidad *'),
                    validator: (v) {
                      final n = int.tryParse((v ?? '').trim());
                      if (n == null || n <= 0) return 'Inválida';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _total,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Total cobrado *',
                      prefixText: '\$ ',
                      hintText: '0.00',
                    ),
                    validator: (v) {
                      final n = double.tryParse(
                          (v ?? '').trim().replaceAll(',', '.'));
                      if (n == null || n < 0) return 'Total inválido';
                      return null;
                    },
                    onChanged: (_) {
                      // Refresh subtotal hint in real time.
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),

            // Live unit-price hint
            if (_total.text.isNotEmpty) ...[
              const SizedBox(height: 4),
              Builder(builder: (context) {
                final qty = int.tryParse(_quantity.text.trim()) ?? 0;
                final tot = double.tryParse(
                    _total.text.trim().replaceAll(',', '.'));
                if (tot == null || qty <= 0) return const SizedBox.shrink();
                return Text(
                  '${money(tot / qty)} por par',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurface.withValues(alpha: 0.55),
                  ),
                );
              }),
            ],
            const SizedBox(height: 12),

            // --- Size label (optional) ---
            TextFormField(
              controller: _sizeLabel,
              decoration: const InputDecoration(
                labelText: 'N° de par / talla (opcional)',
                hintText: 'Ej: 38',
                prefixIcon: Icon(Icons.straighten_outlined),
              ),
            ),
            const SizedBox(height: 12),

            // --- Date (optional, defaults to today) ---
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined, size: 18),
                    label: Text('Fecha: $dateLabel'),
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ),
                if (!isToday) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Usar hoy',
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: _clearDate,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            FilledButton.icon(
              onPressed: _submit,
              icon: Icon(widget.isEditing
                  ? Icons.check
                  : Icons.add_shopping_cart),
              label: Text(widget.isEditing
                  ? 'Actualizar en la venta'
                  : 'Agregar a la venta'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

typedef MovementInput = ({int quantity, String? note});

/// Presentational form to register a stock movement (entry or exit).
class MovementSheet extends StatefulWidget {
  const MovementSheet({required this.isEntry, required this.sku, super.key});

  final bool isEntry;
  final String sku;

  @override
  State<MovementSheet> createState() => _MovementSheetState();
}

class _MovementSheetState extends State<MovementSheet> {
  final _formKey = GlobalKey<FormState>();
  final _quantity = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() {
    _quantity.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final note = _note.text.trim();
    Navigator.of(context).pop((
      quantity: int.parse(_quantity.text.trim()),
      note: note.isEmpty ? null : note,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final title = widget.isEntry ? 'Registrar Stock' : 'Salida de Stock';
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              widget.sku,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantity,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Cantidad'),
              validator: (v) {
                final n = int.tryParse((v ?? '').trim());
                if (n == null || n <= 0) return 'Ingresá una cantidad positiva';
                return null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _note,
              decoration:
                  const InputDecoration(labelText: 'Descripción (opcional)'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _submit,
              child: Text(widget.isEntry ? 'Sumar stock' : 'Restar stock'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

typedef NewUser = ({
  String username,
  String password,
  String role,
  String displayName,
});

/// Form to create a system user (employee or owner).
class CreateUserSheet extends StatefulWidget {
  const CreateUserSheet({super.key});

  @override
  State<CreateUserSheet> createState() => _CreateUserSheetState();
}

class _CreateUserSheetState extends State<CreateUserSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  String _role = 'employee';

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop((
      username: _username.text.trim(),
      password: _password.text,
      role: _role,
      displayName: _name.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Nuevo usuario',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
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
              controller: _username,
              decoration: const InputDecoration(
                labelText: 'Usuario (para iniciar sesión)',
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'El usuario es obligatorio'
                  : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _password,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              validator: (v) => (v == null || v.length < 4)
                  ? 'Mínimo 4 caracteres'
                  : null,
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 'employee', label: Text('Empleado')),
                ButtonSegment(value: 'owner', label: Text('Dueño')),
              ],
              selected: {_role},
              onSelectionChanged: (s) => setState(() => _role = s.first),
            ),
            const SizedBox(height: 8),
            Text(
              _role == 'employee'
                  ? 'Puede vender y ver el stock.'
                  : 'Acceso total: reportes, productos y usuarios.',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _submit, child: const Text('Crear usuario')),
          ],
        ),
      ),
    );
  }
}

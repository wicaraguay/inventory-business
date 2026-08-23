import 'package:flutter/material.dart';
import 'package:inventy_app/features/auth/domain/auth_user.dart';
import 'package:inventy_app/shared/ui/atoms/password_field.dart';

typedef NewUser = ({
  String username,
  String password,
  String role,
  String displayName,
  bool canManageInventory,
});

/// Form to create OR edit a system user. In edit mode ([user] != null) the
/// password field is optional (empty = keep the current one).
class CreateUserSheet extends StatefulWidget {
  const CreateUserSheet({this.user, super.key});

  final AuthUser? user;

  @override
  State<CreateUserSheet> createState() => _CreateUserSheetState();
}

class _CreateUserSheetState extends State<CreateUserSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _username;
  final _password = TextEditingController();
  late String _role;
  late bool _canManageInventory;

  bool get _isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _name = TextEditingController(text: u?.displayName ?? '');
    _username = TextEditingController(text: u?.username ?? '');
    _role = u?.role ?? 'employee';
    _canManageInventory = u?.canManageInventory ?? false;
  }

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
      canManageInventory: _role == 'employee' && _canManageInventory,
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
            Text(_isEdit ? 'Editar usuario' : 'Nuevo usuario',
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
            PasswordField(
              controller: _password,
              label: _isEdit ? 'Nueva contraseña (opcional)' : 'Contraseña',
              validator: (v) {
                final value = v ?? '';
                // Edit: empty means "keep current". Create: required, min 4.
                if (_isEdit && value.isEmpty) return null;
                return value.length < 4 ? 'Mínimo 4 caracteres' : null;
              },
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 'employee', label: Text('Empleado')),
                ButtonSegment(value: 'owner', label: Text('Propietario')),
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
            // Inventory-management delegation only makes sense for employees.
            if (_role == 'employee') ...[
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Puede gestionar inventario'),
                subtitle: const Text(
                  'Además de vender, podrá crear/editar productos y '
                  'registrar entradas y salidas.',
                ),
                value: _canManageInventory,
                onChanged: (v) => setState(() => _canManageInventory = v),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _submit,
              child: Text(_isEdit ? 'Guardar cambios' : 'Crear usuario'),
            ),
          ],
        ),
      ),
    );
  }
}

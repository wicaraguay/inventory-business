import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventy_app/features/auth/presentation/auth_providers.dart';
import 'package:inventy_app/shared/ui/app_alert.dart';
import 'package:inventy_app/shared/ui/atoms/password_field.dart';

/// Bottom sheet: change your own password. Available to any logged-in user
/// (owner or employee) from the sidebar account menu.
class ChangePasswordSheet extends ConsumerStatefulWidget {
  const ChangePasswordSheet({super.key});

  @override
  ConsumerState<ChangePasswordSheet> createState() =>
      _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(authProvider.notifier)
          .changePassword(_current.text, _next.text);
      if (mounted) {
        Navigator.of(context).pop();
        await showAppAlert(context,
            message: 'Contraseña actualizada.', kind: AlertKind.success);
      }
    } on Exception catch (e) {
      if (mounted) {
        await showAppAlert(context,
            message: '$e'.replaceFirst('Exception: ', ''),
            kind: AlertKind.error);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
            Text('Cambiar mi contraseña',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            PasswordField(
              controller: _current,
              label: 'Contraseña actual',
              autofocus: true,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Ingresá tu contraseña actual' : null,
            ),
            const SizedBox(height: 8),
            PasswordField(
              controller: _next,
              label: 'Nueva contraseña',
              validator: (v) =>
                  (v == null || v.length < 4) ? 'Mínimo 4 caracteres' : null,
            ),
            const SizedBox(height: 8),
            PasswordField(
              controller: _confirm,
              label: 'Repetir nueva contraseña',
              validator: (v) =>
                  v != _next.text ? 'Las contraseñas no coinciden' : null,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}

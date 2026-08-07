import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventy_app/features/auth/presentation/auth_providers.dart';
import 'package:inventy_app/features/settings/presentation/settings_providers.dart';
import 'package:inventy_app/shared/api/api_client.dart';
import 'package:inventy_app/shared/theme/app_colors.dart';
import 'package:inventy_app/shared/ui/app_alert.dart';

/// Login screen: shows the business logo + name, and asks for user + password.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(authProvider.notifier)
          .login(_user.text.trim(), _pass.text);
      final name = ref.read(currentUserProvider)?.displayName ?? '';
      if (mounted) {
        await showAppAlert(
          context,
          title: '¡Hola!',
          message: 'Bienvenido, $name 👋',
          kind: AlertKind.success,
        );
      }
      // The router redirects to the app automatically once authenticated.
    } catch (e) {
      if (mounted) {
        await showAppAlert(
          context,
          message: '$e'.replaceFirst('Exception: ', ''),
          kind: AlertKind.error,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final base = ref.watch(apiBaseUrlProvider);
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(child: _logo(settings, base)),
                      const SizedBox(height: 16),
                      Text(
                        settings.businessName,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Iniciá sesión para continuar',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _user,
                        autofocus: true,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Usuario',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Ingresá tu usuario'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _pass,
                        obscureText: true,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: const InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Ingresá tu contraseña'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: _busy ? null : _submit,
                          child: _busy
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Iniciar sesión'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _logo(dynamic settings, String base) {
    const size = 96.0;
    if (settings.hasLogo as bool) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.network(
          '$base/settings/logo?v=${settings.logoVersion}',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(size),
        ),
      );
    }
    return _placeholder(size);
  }

  Widget _placeholder(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.inventory_2, color: Colors.white, size: 44),
      );
}

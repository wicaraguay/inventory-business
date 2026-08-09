import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inventy_app/features/alerts/presentation/alerts_providers.dart';
import 'package:inventy_app/features/settings/presentation/settings_providers.dart';
import 'package:inventy_app/shared/api/api_client.dart';
import 'package:inventy_app/shared/theme/theme_mode_provider.dart';
import 'package:inventy_app/shared/image/image_compressor.dart';
import 'package:inventy_app/shared/theme/app_colors.dart';

/// Container: Configuración — only what the app really has (honest settings).
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _name;
  late final TextEditingController _threshold;
  final _pin = TextEditingController();

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _name = TextEditingController(text: settings.businessName);
    _threshold = TextEditingController(text: '${settings.defaultThreshold}');
  }

  @override
  void dispose() {
    _name.dispose();
    _threshold.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _savePin() async {
    final pin = _pin.text.trim();
    if (pin.length < 4) {
      _snack('El PIN debe tener al menos 4 dígitos');
      return;
    }
    try {
      await ref.read(settingsProvider.notifier).setDiscountPin(pin);
      _pin.clear();
      if (mounted) _snack('PIN de descuento guardado');
    } on Object {
      if (mounted) _snack('No se pudo guardar (revisá la conexión)');
    }
  }

  Future<void> _saveName() async {
    try {
      await ref.read(settingsProvider.notifier).setBusinessName(_name.text);
      if (mounted) _snack('Nombre del negocio guardado');
    } on Object {
      if (mounted) {
        _snack('No se pudo guardar (revisá la conexión al servidor)');
      }
    }
  }

  Future<void> _saveThreshold() async {
    final n = int.tryParse(_threshold.text.trim());
    if (n == null || n < 0) {
      _snack('Ingresá un número válido (>= 0)');
      return;
    }
    try {
      await ref.read(settingsProvider.notifier).setDefaultThreshold(n);
      if (mounted) _snack('Umbral por defecto guardado');
    } on Object {
      if (mounted) {
        _snack('No se pudo guardar (revisá la conexión al servidor)');
      }
    }
  }

  bool _logoBusy = false;

  Future<void> _pickLogo() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (x == null) return;
    setState(() => _logoBusy = true);
    try {
      final bytes = await x.readAsBytes();
      final compressed = await compressImage(bytes);
      await ref.read(settingsProvider.notifier).setLogo(compressed);
      if (mounted) _snack('Logo actualizado');
    } on Object {
      if (mounted) _snack('No se pudo subir el logo (revisá la conexión)');
    } finally {
      if (mounted) setState(() => _logoBusy = false);
    }
  }

  Future<void> _removeLogo() async {
    setState(() => _logoBusy = true);
    try {
      await ref.read(settingsProvider.notifier).removeLogo();
      if (mounted) _snack('Logo eliminado');
    } on Object {
      if (mounted) _snack('No se pudo eliminar el logo (revisá la conexión)');
    } finally {
      if (mounted) setState(() => _logoBusy = false);
    }
  }

  Widget _logoPlaceholder() => Container(
        color: AppColors.primary,
        child: const Icon(Icons.storefront, color: Colors.white, size: 32),
      );

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final base = ref.watch(apiBaseUrlProvider);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ListView(
        children: [
          Text('Configuración',
              style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 4),
          Text(
            'Ajustes de tu negocio',
            style: TextStyle(color: AppColors.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 24),
          _SettingsCard(
            title: 'Datos del negocio',
            children: [
              TextField(
                controller: _name,
                decoration:
                    const InputDecoration(labelText: 'Nombre del negocio'),
              ),
              const SizedBox(height: 8),
              Text(
                'Aparece en la barra lateral.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                    onPressed: () {
                      _saveName();
                    },
                    child: const Text('Guardar')),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsCard(
            title: 'Logo del negocio',
            children: [
              Text(
                'Se muestra en la barra lateral y en la pantalla de acceso.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 72,
                      height: 72,
                      child: settings.hasLogo
                          ? Image.network(
                              '$base/settings/logo?v=${settings.logoVersion}',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _logoPlaceholder(),
                            )
                          : _logoPlaceholder(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: _logoBusy ? null : _pickLogo,
                          icon: _logoBusy
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Icon(Icons.upload),
                          label: Text(
                              settings.hasLogo ? 'Cambiar' : 'Subir logo'),
                        ),
                        if (settings.hasLogo)
                          OutlinedButton.icon(
                            onPressed: _logoBusy ? null : _removeLogo,
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.danger),
                            label: const Text('Quitar',
                                style: TextStyle(color: AppColors.danger)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsCard(
            title: 'Preferencias',
            children: [
              TextField(
                controller: _threshold,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Umbral de stock bajo (global)',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Se avisa cuando cualquier producto queda en o por debajo de '
                'este número. Aplica a todos los productos.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                    onPressed: () {
                      _saveThreshold();
                    },
                    child: const Text('Guardar')),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsCard(
            title: 'PIN de descuento',
            children: [
              Text(
                'Clave aparte (distinta de tu contraseña de ingreso) para '
                'autorizar descuentos en Ventas. Podés compartirla con un '
                'empleado de confianza y cambiarla cuando quieras.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pin,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nuevo PIN (mínimo 4 dígitos)',
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: _savePin,
                  child: const Text('Guardar PIN'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsCard(
            title: 'Apariencia',
            children: [
              SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: ThemeMode.light, label: Text('Claro')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Oscuro')),
                  ButtonSegment(
                      value: ThemeMode.system, label: Text('Sistema')),
                ],
                selected: {ref.watch(themeModeProvider)},
                onSelectionChanged: (s) =>
                    ref.read(themeModeProvider.notifier).set(s.first),
              ),
              const SizedBox(height: 8),
              Text(
                'Tema de la app en este dispositivo. "Sistema" sigue la '
                'configuración del teléfono o la computadora.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsCard(
            title: 'Notificaciones',
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Alertas de stock bajo'),
                subtitle: const Text(
                  'Muestra la campana de avisos en este dispositivo',
                ),
                value: ref.watch(alertsEnabledProvider),
                onChanged: (v) =>
                    ref.read(alertsEnabledProvider.notifier).set(v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Avisos por WhatsApp'),
                subtitle: const Text('Próximamente'),
                value: false,
                onChanged: null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

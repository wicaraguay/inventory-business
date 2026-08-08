import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:inventy_app/features/settings/presentation/settings_providers.dart';
import 'package:inventy_app/shared/router/app_router.dart';
import 'package:inventy_app/shared/theme/app_colors.dart';
import 'package:inventy_app/shared/theme/app_theme.dart';
import 'package:inventy_app/shared/theme/theme_mode_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Safety net: if a screen throws while building, show a readable message
  // instead of a black/blank screen (which is what release builds show by
  // default). Self-contained (literal colors, own Directionality) so it renders
  // even when the failing subtree lacks a theme.
  ErrorWidget.builder = (details) => Directionality(
        textDirection: TextDirection.ltr,
        child: Container(
          color: const Color(0xFFF8FAFC),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: Color(0xFFBA1A1A), size: 40),
              const SizedBox(height: 12),
              const Text(
                'Ocurrió un error al mostrar esta pantalla',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${details.exception}',
                textAlign: TextAlign.center,
                maxLines: 8,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      );
  // Clean URLs on web (/inventory/abc instead of /#/inventory/abc).
  if (kIsWeb) usePathUrlStrategy();
  // On mobile, use the full screen: hide the top status bar (clock/battery),
  // keep the bottom navigation. More room and a cleaner "app" feel.
  if (!kIsWeb) {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.bottom],
    );
  }
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const InventyApp(),
    ),
  );
}

class InventyApp extends ConsumerWidget {
  const InventyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Eco Shoes - Gestión de Inventario',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(routerProvider),
      // Sync the palette flag with the theme MaterialApp actually resolved, so
      // AppColors' structural getters return the right values everywhere.
      builder: (context, child) {
        AppColors.dark = Theme.of(context).brightness == Brightness.dark;
        return child ?? const SizedBox.shrink();
      },
    );
  }
}

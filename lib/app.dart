import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'theme/app_theme.dart';
import 'providers/settings_provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/library/library_screen.dart';
import 'screens/reader/reader_screen.dart';
import 'screens/scanner/scanner_screen.dart';
import 'screens/cafe/cafe_screen.dart';
import 'screens/fireplace/fireplace_screen.dart';
import 'screens/converter/converter_screen.dart';

/// Route names for the Nova Reader app.
class AppRoutes {
  static const home = '/';
  static const library = '/library';
  static const reader = '/reader/:bookId';
  static const settings = '/settings';
  static const search = '/search';
  static const bookDetails = '/book/:bookId';
  static const cameraImport = '/camera-import';
  static const butlerChat = '/butler-chat';
  static const scanner = '/scanner';
  static const converter = '/converter';
  static const fireplace = '/fireplace';
  static const cafe = '/cafe';

  // Helper methods to build paths with parameters
  static String readerPath(String bookId) => '/reader/$bookId';
  static String bookDetailsPath(String bookId) => '/book/$bookId';
}

/// The root widget for the Nova Reader application.
class NovaReaderApp extends ConsumerWidget {
  const NovaReaderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    // Determine the current day segment for theme adaptation
    final DaySegment segment;
    if (settings.themeAuto) {
      segment = DaySegment.fromTimeOfDay(TimeOfDay.now());
    } else {
      // When manual, use afternoon as the default neutral segment
      segment = DaySegment.afternoon;
    }

    final goRouter = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Nova Reader',
      debugShowCheckedModeBanner: false,
      theme: NovaTheme.buildTheme(segment: segment),
      routerConfig: goRouter,
    );
  }
}

/// Settings screen.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Reading section
          _SettingsSection(
            title: 'Reading',
            children: [
              ListTile(
                leading: const Icon(Icons.text_fields),
                title: const Text('Font Size'),
                subtitle: Text('${settings.fontSize.toInt()} pt'),
                trailing: SizedBox(
                  width: 120,
                  child: Slider(
                    value: settings.fontSize,
                    min: 12,
                    max: 32,
                    divisions: 20,
                    onChanged: (value) {
                      ref.read(settingsProvider.notifier).setFontSize(value);
                    },
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.font_download),
                title: const Text('Font Family'),
                subtitle: Text(settings.fontFamily),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Show font picker
                },
              ),
            ],
          ),

          const Divider(),

          // TTS section
          _SettingsSection(
            title: 'Text-to-Speech',
            children: [
              ListTile(
                leading: const Icon(Icons.record_voice_over),
                title: const Text('Speech Speed'),
                subtitle: Text('${settings.ttsSpeed.toStringAsFixed(1)}x'),
                trailing: SizedBox(
                  width: 120,
                  child: Slider(
                    value: settings.ttsSpeed,
                    min: 0.25,
                    max: 2.0,
                    divisions: 7,
                    onChanged: (value) {
                      ref.read(settingsProvider.notifier).setTtsSpeed(value);
                    },
                  ),
                ),
              ),
            ],
          ),

          const Divider(),

          // Ambient sound section
          _SettingsSection(
            title: 'Ambient Sound',
            children: [
              ListTile(
                leading: const Icon(Icons.volume_up),
                title: const Text('Sound'),
                subtitle: Text(_ambientSoundLabel(settings.ambientSound)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showAmbientSoundPicker(context, ref),
              ),
              ListTile(
                leading: const Icon(Icons.volume_down_alt),
                title: const Text('Volume'),
                trailing: SizedBox(
                  width: 120,
                  child: Slider(
                    value: settings.ambientVolume,
                    min: 0,
                    max: 1,
                    divisions: 10,
                    onChanged: (value) {
                      ref
                          .read(settingsProvider.notifier)
                          .setAmbientVolume(value);
                    },
                  ),
                ),
              ),
            ],
          ),

          const Divider(),

          // Theme section
          _SettingsSection(
            title: 'Theme',
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.brightness_auto),
                title: const Text('Auto Theme'),
                subtitle: Text(
                  settings.themeAuto ? 'Adapts to time of day' : 'Manual',
                ),
                value: settings.themeAuto,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).setThemeAuto(value);
                },
              ),
            ],
          ),

          const Divider(),

          // AI Butler section
          _SettingsSection(
            title: 'AI Butler',
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.smart_toy),
                title: const Text('AI Butler'),
                subtitle: Text(
                  settings.aiButlerEnabled ? 'Enabled' : 'Disabled',
                ),
                value: settings.aiButlerEnabled,
                onChanged: (value) {
                  ref
                      .read(settingsProvider.notifier)
                      .setAiButlerEnabled(value);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _ambientSoundLabel(AmbientSound sound) {
    switch (sound) {
      case AmbientSound.none:
        return 'None';
      case AmbientSound.fire:
        return 'Crackling Fire';
      case AmbientSound.rain:
        return 'Rainfall';
      case AmbientSound.wind:
        return 'Gentle Wind';
      case AmbientSound.birds:
        return 'Birdsong';
    }
  }

  void _showAmbientSoundPicker(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          title: const Text('Ambient Sound'),
          children: AmbientSound.values.map((sound) {
            return SimpleDialogOption(
              onPressed: () {
                ref.read(settingsProvider.notifier).setAmbientSound(sound);
                Navigator.pop(ctx);
              },
              child: Text(_ambientSoundLabel(sound)),
            );
          }).toList(),
        );
      },
    );
  }
}

/// Helper widget for grouping settings.
class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

/// GoRouter configuration for the app.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.library,
        name: 'library',
        builder: (context, state) => const LibraryScreen(),
      ),
      GoRoute(
        path: AppRoutes.reader,
        name: 'reader',
        builder: (context, state) {
          final bookId = state.pathParameters['bookId'] ?? '';
          return ReaderScreen(bookId: bookId);
        },
      ),
      GoRoute(
        path: AppRoutes.scanner,
        name: 'scanner',
        builder: (context, state) => const ScannerScreen(),
      ),
      GoRoute(
        path: AppRoutes.converter,
        name: 'converter',
        builder: (context, state) => const ConverterScreen(),
      ),
      GoRoute(
        path: AppRoutes.fireplace,
        name: 'fireplace',
        builder: (context, state) => const FireplaceScreen(),
      ),
      GoRoute(
        path: AppRoutes.cafe,
        name: 'cafe',
        builder: (context, state) => const CafeScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.search,
        name: 'search',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Search')),
          body: const Center(child: Text('Search screen - coming soon')),
        ),
      ),
      GoRoute(
        path: AppRoutes.bookDetails,
        name: 'bookDetails',
        builder: (context, state) {
          final bookId = state.pathParameters['bookId'] ?? '';
          return Scaffold(
            appBar: AppBar(title: Text('Book: $bookId')),
            body: Center(child: Text('Details for book $bookId - coming soon')),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.cameraImport,
        name: 'cameraImport',
        builder: (context, state) => const ScannerScreen(),
      ),
      GoRoute(
        path: AppRoutes.butlerChat,
        name: 'butlerChat',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Butler Chat')),
          body: const Center(child: Text('Butler chat - coming soon')),
        ),
      ),
    ],
  );
});

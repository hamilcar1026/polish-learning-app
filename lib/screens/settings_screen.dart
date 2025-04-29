import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import generated localizations
import '../providers/settings_provider.dart';
import 'contributors_screen.dart'; // Import the new screen

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  // Change to static const
  static const Map<String, String> _languageNames = {
    'en': 'English',
    'pl': 'Polski',
    'ko': '한국어',
    'ru': 'Русский',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final l10n = AppLocalizations.of(context)!; // Get localizations instance

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle), // Use localized title
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            l10n.languageSettingTitle, // Use localized title
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          // Language Selection Radio Buttons
          ..._languageNames.entries.map((entry) {
            return RadioListTile<String>(
              title: Text(entry.value), // Keep language names as they are
              value: entry.key,
              groupValue: settings.languageCode,
              onChanged: (String? value) {
                if (value != null) {
                  settingsNotifier.setLanguage(value);
                }
              },
            );
          }).toList(),

          const SizedBox(height: 24),
          // Apply M3 Divider style
          Divider(
            height: 1,
            thickness: 1,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
          ),
          const SizedBox(height: 24),

          Text(
            l10n.fontSizeSettingTitle, // Use localized title
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          // Font Size Slider with M3 Theme
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              // Apply M3 specific theme customizations here if needed
              // For example, track height, thumb shape, colors based on ColorScheme
              trackHeight: 4.0, // M3 default track height
              activeTrackColor: Theme.of(context).colorScheme.primary,
              inactiveTrackColor: Theme.of(context).colorScheme.surfaceVariant,
              thumbColor: Theme.of(context).colorScheme.primary,
              overlayColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0), // M3 thumb shape
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20.0), // M3 overlay shape
              valueIndicatorShape: const PaddleSliderValueIndicatorShape(), // M3 value indicator
              valueIndicatorColor: Theme.of(context).colorScheme.primary,
              valueIndicatorTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            child: Slider(
              value: settings.fontSizeFactor,
              min: 0.8,
              max: 1.5,
              divisions: 7, // Creates steps like 0.8, 0.9, 1.0, 1.1, 1.2, 1.3, 1.4, 1.5
              label: settings.fontSizeFactor.toStringAsFixed(1), // Show current factor
              onChanged: (double value) {
                 // Update continuously while sliding
                 // Consider adding a debounce if performance is an issue
                 settingsNotifier.setFontSizeFactor(value);
              },
              // onChangeEnd: (double value) {
              //   // Or only update when the user releases the slider
              //   settingsNotifier.setFontSizeFactor(value);
              // },
            ),
          ),
           // Display current factor value
          Center(
            child: Text(
              'Current Scale: ${settings.fontSizeFactor.toStringAsFixed(1)}x', // Replace with localized string later
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),

          const SizedBox(height: 24),
          // Apply M3 Divider style
          Divider(
            height: 1,
            thickness: 1,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
          ),
          const SizedBox(height: 24),

          // Contributors Link
          ListTile(
            title: Text(l10n.copyrightsTitle), // Use the correct key for Copyrights
            leading: const Icon(Icons.people_outline),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ContributorsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
} 
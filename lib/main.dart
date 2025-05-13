import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Import localization delegates
import 'package:polish_learning_app/l10n/app_localizations.dart'; // Import generated localizations
import 'screens/search_screen.dart'; // We will create this screen next
import 'providers/settings_provider.dart'; // Import the settings provider

Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for Flutter
  await Hive.initFlutter();
  // Open Hive boxes for recent searches and favorites
  await Hive.openBox<String>('recent_searches'); // Box to store list of search terms
  await Hive.openBox<String>('favorite_words'); // Box to store set of favorite lemmas

  runApp(
    // Wrap the entire app with ProviderScope for Riverpod
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

// Change MyApp to ConsumerWidget to access providers
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // Helper function to apply font size factor to TextTheme
  TextTheme _applyFontSizeFactor(TextTheme base, double factor) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(fontSize: (base.displayLarge?.fontSize ?? 57.0) * factor),
      displayMedium: base.displayMedium?.copyWith(fontSize: (base.displayMedium?.fontSize ?? 45.0) * factor),
      displaySmall: base.displaySmall?.copyWith(fontSize: (base.displaySmall?.fontSize ?? 36.0) * factor),
      headlineLarge: base.headlineLarge?.copyWith(fontSize: (base.headlineLarge?.fontSize ?? 32.0) * factor),
      headlineMedium: base.headlineMedium?.copyWith(fontSize: (base.headlineMedium?.fontSize ?? 28.0) * factor),
      headlineSmall: base.headlineSmall?.copyWith(fontSize: (base.headlineSmall?.fontSize ?? 24.0) * factor),
      titleLarge: base.titleLarge?.copyWith(fontSize: (base.titleLarge?.fontSize ?? 22.0) * factor),
      titleMedium: base.titleMedium?.copyWith(fontSize: (base.titleMedium?.fontSize ?? 16.0) * factor),
      titleSmall: base.titleSmall?.copyWith(fontSize: (base.titleSmall?.fontSize ?? 14.0) * factor),
      bodyLarge: base.bodyLarge?.copyWith(fontSize: (base.bodyLarge?.fontSize ?? 16.0) * factor),
      bodyMedium: base.bodyMedium?.copyWith(fontSize: (base.bodyMedium?.fontSize ?? 14.0) * factor),
      bodySmall: base.bodySmall?.copyWith(fontSize: (base.bodySmall?.fontSize ?? 12.0) * factor),
      labelLarge: base.labelLarge?.copyWith(fontSize: (base.labelLarge?.fontSize ?? 14.0) * factor),
      labelMedium: base.labelMedium?.copyWith(fontSize: (base.labelMedium?.fontSize ?? 12.0) * factor),
      labelSmall: base.labelSmall?.copyWith(fontSize: (base.labelSmall?.fontSize ?? 11.0) * factor),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the font size factor from the settings provider
    final double fontSizeFactor = ref.watch(fontSizeFactorProvider);
    final String languageCode = ref.watch(languageCodeProvider); // Watch language code
    
    // Define the base theme
    final baseTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
    );

    return MaterialApp(
      // title: 'Polish Learning App', // Title will be localized
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle, // Use localized title
      theme: baseTheme.copyWith(
        // Apply the adjusted text theme
        textTheme: _applyFontSizeFactor(baseTheme.textTheme, fontSizeFactor),
      ),
      locale: Locale(languageCode), // Set the app's locale
      localizationsDelegates: const [
        AppLocalizations.delegate, // Add our generated delegate
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('pl'), // Polish
        Locale('ko'), // Korean
        Locale('ru'), // Add Russian
        Locale('uk'), // Add Ukrainian
      ],
      home: const SearchScreen(), // Set SearchScreen as the home screen
      debugShowCheckedModeBanner: false,
    );
  }
}

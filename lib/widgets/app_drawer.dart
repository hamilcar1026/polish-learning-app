import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/recent_searches_provider.dart';
import '../providers/favorites_provider.dart';
// import '../providers/settings_provider.dart'; // Remove unused import
import '../screens/search_screen.dart'; // To access submittedWordProvider

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final recentSearches = ref.watch(recentSearchesProvider);
    final favorites = ref.watch(favoritesProvider);
    final recentSearchesNotifier = ref.read(recentSearchesProvider.notifier);
    // final favoritesNotifier = ref.read(favoritesProvider.notifier); // Needed for clear/remove

    // Function to trigger a new search from the drawer
    void searchFromDrawer(String term) {
      if (term.isNotEmpty) {
        // Update the controller in SearchScreen (optional but good UX)
        // This requires passing the controller or using a shared provider
        // For simplicity, just update submittedWordProvider and close drawer
        ref.read(submittedWordProvider.notifier).state = term;
        Navigator.pop(context); // Close the drawer
      }
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Text(
              l10n.appTitle, // Use localized app title
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontSize: 24,
              ),
            ),
          ),
          
          // --- Recent Searches Section ---
          ListTile(
            title: Text(l10n.drawerRecentSearches, style: Theme.of(context).textTheme.titleMedium),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.drawerClearRecentSearchesTooltip,
              onPressed: recentSearches.isEmpty 
                  ? null 
                  : () {
                      // Show confirmation dialog before clearing
                      showDialog(
                        context: context,
                        builder: (BuildContext dialogContext) {
                          return AlertDialog(
                            title: Text(l10n.drawerClearRecentSearchesDialogTitle),
                            content: Text(l10n.drawerClearDialogContent),
                            actions: <Widget>[
                              TextButton(
                                child: Text(l10n.drawerCancelButton),
                                onPressed: () => Navigator.of(dialogContext).pop(),
                              ),
                              TextButton(
                                child: Text(l10n.drawerClearButton),
                                onPressed: () {
                                  recentSearchesNotifier.clearSearches();
                                  Navigator.of(dialogContext).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
            ),
          ),
          if (recentSearches.isEmpty)
            ListTile(
              title: Text(l10n.drawerNoRecentSearches),
              dense: true,
            )
          else
            ...recentSearches.map((term) {
              return ListTile(
                title: Text(term),
                leading: const Icon(Icons.history, size: 20),
                dense: true,
                visualDensity: VisualDensity.compact,
                onTap: () => searchFromDrawer(term),
              );
            }).toList(),
            
          const Divider(),

          // --- Favorites Section ---
          ListTile(
            title: Text(l10n.drawerFavorites, style: Theme.of(context).textTheme.titleMedium),
          ),
          if (favorites.isEmpty)
            ListTile(
              title: Text(l10n.drawerNoFavorites),
              dense: true,
            )
          else
            ...favorites.map((lemma) {
              return ListTile(
                title: Text(lemma),
                leading: const Icon(Icons.star, size: 20, color: Colors.amber),
                dense: true,
                visualDensity: VisualDensity.compact,
                onTap: () => searchFromDrawer(lemma), // Search for the favorited lemma
              );
            }).toList(),

          // Optional: Add link to Settings screen
          // const Divider(),
          // ListTile(
          //   leading: const Icon(Icons.settings),
          //   title: const Text('Settings'),
          //   onTap: () {
          //     Navigator.pop(context); // Close drawer first
          //     Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
          //   },
          // ),
        ],
      ),
    );
  }
} 
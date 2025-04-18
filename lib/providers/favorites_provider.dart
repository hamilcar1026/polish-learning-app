import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

const String _favoritesBoxName = 'favorite_words';

class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier() : super({}) {
    _loadFavorites();
  }

  late Box<String> _favoritesBox;

  Future<void> _loadFavorites() async {
    _favoritesBox = Hive.box<String>(_favoritesBoxName);
    // Load all values from the box into the initial state set
    state = _favoritesBox.values.toSet(); 
    print("Favorites loaded: ${state.length} items");
  }

  Future<void> addFavorite(String lemma) async {
    if (lemma.isEmpty || state.contains(lemma)) return;
    // Add to the Hive box. We use the lemma itself as the key for easy lookup/deletion.
    await _favoritesBox.put(lemma, lemma);
    // Update state by adding the new lemma
    state = {...state, lemma};
    print("Favorite added: $lemma. Total: ${state.length}");
  }

  Future<void> removeFavorite(String lemma) async {
    if (lemma.isEmpty || !state.contains(lemma)) return;
    // Remove from the Hive box using the lemma as the key
    await _favoritesBox.delete(lemma);
    // Update state by removing the lemma
    state = state.where((fav) => fav != lemma).toSet();
    print("Favorite removed: $lemma. Total: ${state.length}");
  }

  Future<void> toggleFavorite(String lemma) async {
    if (state.contains(lemma)) {
      await removeFavorite(lemma);
    } else {
      await addFavorite(lemma);
    }
  }

  // Method to check if a lemma is favorite (already implicitly handled by state)
  // bool isFavorite(String lemma) {
  //   return state.contains(lemma);
  // }

  // Optional: Method to clear favorites
  Future<void> clearFavorites() async {
     await _favoritesBox.clear();
     state = {};
     print("Favorites cleared.");
  }
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  return FavoritesNotifier();
}); 
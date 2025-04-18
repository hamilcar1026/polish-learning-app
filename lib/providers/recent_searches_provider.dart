import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

const String _recentSearchesBoxName = 'recent_searches';
const int _maxRecentSearches = 20;

class RecentSearchesNotifier extends StateNotifier<List<String>> {
  RecentSearchesNotifier() : super([]) {
    _loadSearches();
  }

  late Box<String> _recentSearchesBox;

  Future<void> _loadSearches() async {
    _recentSearchesBox = Hive.box<String>(_recentSearchesBoxName);
    // Hive box stores values, keys are auto-incrementing. Get all values.
    final searches = _recentSearchesBox.values.toList();
    // Reverse to show most recent first (assuming they are added chronologically)
    state = searches.reversed.toList();
    print("Recent searches loaded: ${state.length} items");
  }

  Future<void> addSearch(String searchTerm) async {
    if (searchTerm.isEmpty) return;

    // Make a mutable copy of the current state
    List<String> updatedSearches = List.from(state);

    // Remove the term if it already exists to move it to the top
    updatedSearches.remove(searchTerm);

    // Add the new term to the beginning (most recent)
    updatedSearches.insert(0, searchTerm);

    // Limit the number of recent searches
    if (updatedSearches.length > _maxRecentSearches) {
      updatedSearches = updatedSearches.sublist(0, _maxRecentSearches);
    }

    // Update the Hive box (clear and re-add to maintain order easily)
    await _recentSearchesBox.clear();
    // Add items back in reverse order so newest has highest index
    await _recentSearchesBox.addAll(updatedSearches.reversed.toList());

    // Update the state
    state = updatedSearches;
    print("Recent search added/updated: $searchTerm. Total: ${state.length}");
  }

   // Optional: Method to clear searches
   Future<void> clearSearches() async {
      await _recentSearchesBox.clear();
      state = [];
      print("Recent searches cleared.");
   }
}

final recentSearchesProvider = StateNotifierProvider<RecentSearchesNotifier, List<String>>((ref) {
  return RecentSearchesNotifier();
}); 
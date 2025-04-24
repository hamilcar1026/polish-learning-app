import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart'; // Import flutter_tts
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import generated localizations
import '../providers/api_providers.dart';
import '../providers/recent_searches_provider.dart'; // Import recent searches provider
import '../providers/settings_provider.dart'; // Import settings provider
import '../models/analysis_result.dart'; // Import AnalysisResult model
import '../models/conjugation_result.dart'; // Import ConjugationResult model
import '../models/declension_result.dart'; // Import DeclensionResult model
import '../services/api_service.dart'; // Import ApiResponse
import 'settings_screen.dart'; // Import the settings screen
import '../providers/favorites_provider.dart'; // Import favorites provider (will be needed soon)
import '../widgets/app_drawer.dart'; // Import the AppDrawer widget

// StateProvider to hold the current search term entered by the user
final searchTermProvider = StateProvider<String>((ref) => '');

// StateProvider to hold the word submitted for search
// This triggers the API call via FutureProviders
final submittedWordProvider = StateProvider<String?>((ref) => null);

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  late FlutterTts flutterTts; // Declare FlutterTts instance
  bool _isTtsInitialized = false;

  // Map to manage the expansion state of conjugation categories
  final Map<String, bool> _expandedCategories = {};

  // Method to toggle the expansion state of a category
  void _toggleCategoryExpansion(String category) {
    setState(() {
      // Default to false (collapsed) if not present, then toggle
      _expandedCategories[category] = !(_expandedCategories[category] ?? false);
    });
  }

  // --- Helper functions to check POS based on analysis data ---
  // (These mimic the logic from the Python backend)
  bool _isVerbBasedOnAnalysis(List<AnalysisResult>? analysisData) {
    if (analysisData == null || analysisData.isEmpty) return false;
    // Check if any analysis result has a verb tag
    const verbTags = {'fin', 'bedzie', 'impt', 'imps', 'inf', 'pact', 'pant', 'pcon', 'ppas'};
    return analysisData.any((result) => verbTags.contains(result.tag));
  }

  bool _isDeclinableBasedOnAnalysis(List<AnalysisResult>? analysisData) {
    if (analysisData == null || analysisData.isEmpty) return false;
    // Check if any analysis result has a declinable tag
    const declinableTags = {'subst', 'depr', 'adj', 'adja', 'adjp'};
    return analysisData.any((result) => declinableTags.contains(result.tag));
  }

  @override
  void initState() {
    super.initState();
    _initializeTts(); // Initialize TTS
    // Listen to the searchTermProvider and update the text field controller
    // This is useful if the search term can be updated from elsewhere (e.g., history)
    ref.listenManual(searchTermProvider, (previous, next) {
       if (next != _controller.text) {
         // Use WidgetsBinding to schedule update after build
         WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) { // Ensure the widget is still in the tree
               _controller.text = next;
               _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
            }
         });
       }
    });
  }

  Future<void> _initializeTts() async {
    flutterTts = FlutterTts();
    try {
      // --- DEBUG: List available languages ---
      List<dynamic> languages = await flutterTts.getLanguages;
      print("Available TTS Languages: $languages");
      bool isPolishSupported = languages.any((lang) => lang.toString().toLowerCase().contains('pl'));
      print("Is Polish (pl) supported? $isPolishSupported");
      // --- END DEBUG ---

       // Set language to Polish
       var result = await flutterTts.setLanguage("pl-PL"); 
       print("Set language result: $result"); // Check if setting language was successful

       // Optional: Adjust speech rate (0.0 to 1.0)
       await flutterTts.setSpeechRate(0.5); 
       // Optional: Adjust pitch (0.5 to 2.0)
       await flutterTts.setPitch(1.0);

       print("TTS Initialized successfully (attempted)");
       setState(() {
          _isTtsInitialized = true;
       });
    } catch (e) {
       print("Error initializing TTS: $e");
       setState(() {
          _isTtsInitialized = false;
       });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    flutterTts.stop(); // Stop TTS when widget is disposed
    super.dispose();
  }

  Future<void> _speak(String text) async {
     if (!_isTtsInitialized) {
        print("TTS not initialized, cannot speak.");
        // Optionally show a message to the user
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Text-to-Speech engine is not ready.')),
        );
        return;
     }
    if (text.isNotEmpty) {
      print("Speaking: $text");
      try {
         await flutterTts.speak(text);
      } catch (e) {
         print("Error speaking: $e");
         // Optionally show an error message
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error speaking text: $e')),
         );
      }
    }
  }

  void _submitSearch(String word) {
    final trimmedWord = word.trim();
    print("[_submitSearch] Attempting to submit word: \"$trimmedWord\"");
    if (trimmedWord.isNotEmpty) {
      ref.read(submittedWordProvider.notifier).state = trimmedWord;
      // Add the searched word to recent searches
      ref.read(recentSearchesProvider.notifier).addSearch(trimmedWord);
      print("[_submitSearch] submittedWordProvider updated to: \"$trimmedWord\"");
    } else {
      print("[_submitSearch] Word is empty after trimming.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final submittedWord = ref.watch(submittedWordProvider);
    final l10n = AppLocalizations.of(context)!; // Get localizations instance
    print("[build] Current submittedWord: ${submittedWord == null ? "null" : "\"$submittedWord\""}");
    
    // Determine the number of tabs needed based on analysis (initial guess or based on state)
    // This needs refinement, maybe calculate dynamically after analysis
    int tabLength = 3; // Default to 3 (Declension, Conjugation, Grammar) - adjust later if needed

    return DefaultTabController(
      length: tabLength, // Adjust length dynamically based on analysis results if possible
      child: Scaffold(
        appBar: AppBar(
          leading: Builder( // Use Builder to get context for Scaffold
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip, // Standard tooltip
              onPressed: () => Scaffold.of(context).openDrawer(), // Open the drawer
            ),
          ),
          title: InkWell( // Wrap Title with InkWell
            onTap: () {
              // Clear the text field
              _controller.clear();
              // Reset the search term provider
              ref.read(searchTermProvider.notifier).state = '';
              // Reset the submitted word provider to clear results
              ref.read(submittedWordProvider.notifier).state = null;
              print("[AppBar Title Tap] Search state reset.");
            },
            child: Text(l10n.appTitle), // Use localized title
          ),
          actions: [ // Add actions for the AppBar
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: l10n.settingsTitle, // Use localized tooltip
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
          ],
        ),
        drawer: const AppDrawer(), // Add the drawer here
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search TextField
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: l10n.searchHint, // Use localized hint
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    tooltip: l10n.searchButtonTooltip, // Use localized tooltip
                    onPressed: () => _submitSearch(_controller.text),
                  ),
                ),
                onChanged: (value) {
                  ref.read(searchTermProvider.notifier).state = value;
                },
                onSubmitted: _submitSearch,
              ),
              const SizedBox(height: 20),
              
              // Results area with improved scrolling
              Expanded(
                child: submittedWord == null
                  ? Center(child: Text(l10n.searchHint))
                  : Consumer(
                      builder: (context, ref, child) {
                        print("[Consumer builder] Watching analysisProvider for: \"$submittedWord\"");
                        // Get the current language code from settings
                        final currentLang = ref.watch(languageCodeProvider); 
                        // Create params object
                        final analysisParams = AnalysisParams(word: submittedWord, targetLang: currentLang);
                        // Watch the provider with the params object
                        final analysisAsyncValue = ref.watch(analysisProvider(analysisParams));
                        
                        return analysisAsyncValue.when(
                          data: (analysisResponse) {
                            print("[Consumer builder - data] Analysis received with status: ${analysisResponse.status}");

                            // --- Handle Suggestion Status --- 
                            if (analysisResponse.status == 'suggestion') {
                              // Ensure suggested_word is not null before showing suggestion UI
                              if (analysisResponse.suggested_word != null) {
                                final suggested = analysisResponse.suggested_word!;
                                return Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Use localized string for the suggestion message
                                      Text(l10n.suggestionDidYouMean(suggested)), 
                                      TextButton(
                                        onPressed: () {
                                          print("Suggestion '$suggested' tapped. Submitting new search.");
                                          // Update the text field and providers for the new search
                                          _controller.text = suggested;
                                          _controller.selection = TextSelection.fromPosition(TextPosition(offset: suggested.length));
                                          ref.read(searchTermProvider.notifier).state = suggested;
                                          _submitSearch(suggested);
                                        },
                                        child: Text("'$suggested'"), // Show clickable suggestion word
                                      ),
                                    ],
                                  ),
                                );
                              } else {
                                // Fallback if suggestion status is received but suggested_word is null (shouldn't happen ideally)
                                // Use the new localized fallback message
                                return Center(child: Text(analysisResponse.message ?? l10n.suggestionErrorFallback)); 
                              }
                            }

                            // --- Handle Success Status (existing logic) --- 
                            final bool isAnalysisSuccess = analysisResponse.status == 'success' &&
                                                         analysisResponse.data != null &&
                                                         analysisResponse.data!.isNotEmpty;
                            final bool isVerb = isAnalysisSuccess && _isVerbBasedOnAnalysis(analysisResponse.data);
                            final bool isDeclinable = isAnalysisSuccess && _isDeclinableBasedOnAnalysis(analysisResponse.data);
                            
                            if (!isAnalysisSuccess) {
                              // --- Handle Analysis Failure --- 
                              // Even if analysis fails, we might have a translation or message from the backend.
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Show a simplified header with title, buttons, and potential translation
                                  Card(
                                    elevation: 2.0,
                                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  // Use submittedWord directly as analysisResponse.word doesn't exist
                                                  '"${submittedWord ?? ''}" - ${l10n.analysisTitle}', 
                                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                                  overflow: TextOverflow.ellipsis, 
                                                ),
                                              ),
                                              // Only show TTS button if submittedWord is available
                                              if (_isTtsInitialized && submittedWord != null)
                                                IconButton(
                                                  icon: const Icon(Icons.volume_up),
                                                  // Speak submittedWord
                                                  onPressed: () => _speak(submittedWord!), 
                                                  tooltip: l10n.pronounceWordTooltip, 
                                                  iconSize: 20, 
                                                  padding: const EdgeInsets.only(left: 8),
                                                  constraints: const BoxConstraints(),
                                                ),
                                              // Consider disabling favorite button here as there's no lemma
                                            ],
                                          ),
                                          // Display translation if available (even on failure)
                                          if (analysisResponse.translation_en != null && analysisResponse.translation_en!.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                                              child: Text(
                                                "${l10n.translationLabel}: ${analysisResponse.translation_en!}",
                                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic, color: Colors.deepPurple),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Display the specific failure message from the backend or the generic one
                                  Center(
                                    child: Text(
                                      analysisResponse.message ?? l10n.noAnalysisFound(submittedWord ?? ''),
                                      textAlign: TextAlign.center,
                                    )
                                  ),
                                ],
                              );
                            }

                            // Dynamically build tabs
                            List<Widget> tabs = [];
                            List<Widget> tabViews = [];

                            if (isDeclinable) {
                              tabs.add(Tab(text: l10n.declensionTitle));
                              tabViews.add(_buildDeclensionTab(submittedWord, l10n));
                            }
                             if (isVerb) {
                              tabs.add(Tab(text: l10n.conjugationTitle));
                              tabViews.add(_buildConjugationTab(submittedWord, l10n));
                            }
                             // REMOVE Grammar tab and view
                             // tabs.add(Tab(text: l10n.grammarTitle));
                             // tabViews.add(Center(child: Text('Grammar info for "$submittedWord" coming soon')));

                            // Need to rebuild TabController if length changes - this is complex with DefaultTabController
                            // For simplicity, let's assume 3 tabs if either verb or declinable, else 1 tab (Analysis only view?)
                            // A more robust solution might involve a custom TabController managed in the state.

                            if (tabs.isEmpty) {
                                return Column(
                                  children: [
                                     _buildAnalysisInfo(analysisResponse, submittedWord, l10n),
                                     Expanded(child: Center(child: Text(l10n.noAnalysisFound(submittedWord)))),
                                  ],
                                );
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Analysis section - always visible
                                _buildAnalysisInfo(analysisResponse, submittedWord, l10n),
                                const SizedBox(height: 16),
                                
                                // TabBar (only if there are specific tabs)
                                if (isVerb || isDeclinable)
                                  TabBar(
                                    controller: DefaultTabController.of(context), // Use context's controller
                                    tabs: tabs,
                                    labelColor: Theme.of(context).colorScheme.primary,
                                    unselectedLabelColor: Colors.grey,
                                    indicatorColor: Theme.of(context).colorScheme.primary,
                                    isScrollable: tabs.length > 3, // Allow scroll if many tabs
                                  ),
                                
                                // TabBarView for content
                                if (isVerb || isDeclinable)
                                  Expanded(
                                    child: TabBarView(
                                      controller: DefaultTabController.of(context), // Use context's controller
                                      children: tabViews,
                                    ),
                                  ),
                                  
                                // If neither verb nor declinable but analysis succeeded
                                if (!isVerb && !isDeclinable && isAnalysisSuccess)
                                  Expanded(
                                    child: Center(
                                      child: Text(
                                        // Use localized message
                                        l10n.noAnalysisFound(submittedWord),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                          loading: () {
                            return const Center(child: CircularProgressIndicator());
                          },
                          error: (error, stackTrace) {
                            // Use localized error message
                            return Center(child: Text(l10n.loadingError(error.toString())));
                          },
                        );
                      },
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Builder for the Analysis Info section ---
  Widget _buildAnalysisInfo(ApiResponse<List<AnalysisResult>> analysisResponse, String word, AppLocalizations l10n) {
    if (analysisResponse.status != 'success' || analysisResponse.data == null || analysisResponse.data!.isEmpty) {
       return Padding(
         padding: const EdgeInsets.symmetric(vertical: 8.0),
         child: Text(analysisResponse.message ?? l10n.noAnalysisFound(word), textAlign: TextAlign.center),
       );
    }
    
    // Assuming the first result represents the primary analysis
    final primaryAnalysis = analysisResponse.data!.first;
    final String lemma = primaryAnalysis.lemma;
    
    // Watch favorite status for the current lemma
    final isFavorite = ref.watch(favoritesProvider).contains(lemma);
    final favoritesNotifier = ref.read(favoritesProvider.notifier);
    
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, 
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible( 
                  child: Text(
                    '"$word" - ${l10n.analysisTitle}', 
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis, 
                  ),
                ),
                // Row for action buttons (TTS and Favorite)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isTtsInitialized)
                      IconButton(
                        icon: const Icon(Icons.volume_up),
                        onPressed: () => _speak(word), // Speak the original searched word
                        tooltip: l10n.pronounceWordTooltip, 
                        iconSize: 20, 
                        padding: const EdgeInsets.only(left: 8), // Add some padding
                        constraints: const BoxConstraints(), 
                      ),
                    // Favorite Button
                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.star : Icons.star_border,
                        color: isFavorite ? Colors.amber : null,
                      ),
                      tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites', // Localize later if needed
                      onPressed: () {
                        favoritesNotifier.toggleFavorite(lemma); // Toggle favorite for the lemma
                      },
                      iconSize: 22, // Slightly larger star
                      padding: const EdgeInsets.only(left: 8), // Add some padding
                      constraints: const BoxConstraints(), 
                    ),
                  ],
                )
              ],
            ),
            // Display the translation here if available
            if (analysisResponse.translation_en != null && analysisResponse.translation_en!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 4.0), // Add some spacing
                child: Text(
                  "${l10n.translationLabel}: ${analysisResponse.translation_en!}", // Display label + translation
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic, color: Colors.deepPurple), // Style the translation
                ),
              ),
            const SizedBox(height: 8),
            // Use the helper function to display localized analysis strings
            ...analysisResponse.data!.map((result) { 
              return Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  _getTranslatedAnalysisString(result, l10n),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // --- Builder for Declension Tab ---
  Widget _buildDeclensionTab(String word, AppLocalizations l10n) {
    return Consumer(
      builder: (context, ref, _) {
        final declensionAsyncValue = ref.watch(declensionProvider(word));
        
        return declensionAsyncValue.when(
          data: (d) => d.status == 'success' && d.data != null && d.data!.isNotEmpty
              ? SingleChildScrollView( // Ensure tab content is scrollable
                  padding: const EdgeInsets.symmetric(vertical: 8.0), // Add padding within scroll view
                  child: _buildDeclensionResults(d.data!.first, l10n),
                )
              : Center(
                  child: Text(d.message ?? l10n.noDeclensionData),
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text(l10n.loadingError(e.toString()))),
        );
      },
    );
  }

  // --- Builder for Conjugation Tab ---
  Widget _buildConjugationTab(String word, AppLocalizations l10n) {
    return Consumer(
      builder: (context, ref, _) {
        final conjugationAsyncValue = ref.watch(conjugationProvider(word));
        
        return conjugationAsyncValue.when(
          data: (c) {
            if (c.status == 'success' && c.data != null && c.data!.isNotEmpty) {
              final lemmaData = c.data!.first; // lemmaData is now ConjugationResult
              // final groupedForms = _prepareGroupedConjugationForms(lemmaData); // REMOVED: No longer need to prepare
              final groupedForms = lemmaData.grouped_forms; // NEW: Directly access the map
              
              if (groupedForms.isEmpty) {
                 return Center(child: Text(l10n.noConjugationData));
              }
              
              return SingleChildScrollView( 
                 padding: const EdgeInsets.symmetric(vertical: 8.0), 
                 child: Card(
                    elevation: 2.0,
                    margin: EdgeInsets.zero, 
                    child: Padding(
                       padding: const EdgeInsets.all(12.0),
                       child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min, 
                          children: [
                             Text(
                                l10n.conjugationTableTitle(lemmaData.lemma),
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                             ),
                             const SizedBox(height: 10),
                             const Divider(),
                             // Pass the already grouped forms directly
                             ..._buildConjugationSections(context, groupedForms, l10n),
                          ],
                       ),
                    ),
                 ),
              );
            } else {
              return Center(
                child: Text(c.message ?? l10n.noConjugationData),
              );
            }
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text(l10n.loadingError(e.toString()))),
        );
      },
    );
  }


  // --- Builder for Declension Results --- 
  Widget _buildDeclensionResults(DeclensionResult lemmaData, AppLocalizations l10n) {
    print("[_buildDeclensionResults] Building declension widget for: ${lemmaData.lemma}");
    
    Map<String, Map<String, String>> declensionTable = {}; // {caseCode: {sg: form, pl: form}}
    final casesOrder = ['nom', 'gen', 'dat', 'acc', 'inst', 'loc', 'voc']; 

    for (var formInfo in lemmaData.forms) {
      final tagMap = _parseTag(formInfo.tag);
      // Get potential combined cases (e.g., "gen.acc") or single case
      final casePart = tagMap['case'] ?? tagMap['case_person']; 
      final numberCode = tagMap['number'];

      if (casePart != null && numberCode != null) {
        // Split combined cases like "gen.acc" or "nom.acc.voc"
        final individualCases = casePart.split('.'); 

        for (var caseCode in individualCases) {
           // Ensure the case is one we want to display in the table
          if (casesOrder.contains(caseCode)) { 
            if (!declensionTable.containsKey(caseCode)) {
              declensionTable[caseCode] = {};
            }

            // Assign the form to the singular or plural slot for this case
            // Avoid overwriting if multiple forms map to the same slot (e.g., different gender variations not shown here)
            // For simplicity, we take the first one encountered.
            if (numberCode == 'sg') {
              declensionTable[caseCode]!['sg'] ??= formInfo.form; 
            } else if (numberCode == 'pl') {
              declensionTable[caseCode]!['pl'] ??= formInfo.form;
            }
          }
        }
      }
    }

    // Display as a card with a table
    // No Card needed here as the tab builder wraps it
    return Column(
      // Center the children horizontally
      crossAxisAlignment: CrossAxisAlignment.center, 
      mainAxisSize: MainAxisSize.min, 
      children: [
        Builder( // Use Builder to get context for theme/l10n access
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            // Get the first tag (assuming it's representative, handle potential emptiness)
            String firstTagString = lemmaData.forms.isNotEmpty ? lemmaData.forms.first.tag : '';
            String translatedTagString = '';

            if (firstTagString.isNotEmpty) {
              // Split the tag and translate each part using the existing helper
              translatedTagString = firstTagString
                  .split(':')
                  .map((part) => _translateGrammarTerm(part, l10n)) // Translate each part
                  .join(':'); // Join back with colons
            }
            
            return Text(
              // Append translated tag if available
              '${l10n.declensionTableTitle(lemmaData.lemma)}${translatedTagString.isNotEmpty ? ' ($translatedTagString)' : ''}', 
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            );
          }
        ),
        const SizedBox(height: 16),
        
        // Table display
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            // Center the Table widget horizontally
            child: Center( 
              child: Table(
                border: TableBorder.all(color: Colors.grey.shade300),
                columnWidths: const {
                  0: IntrinsicColumnWidth(), // Case column
                  1: IntrinsicColumnWidth(), // Singular column
                  2: IntrinsicColumnWidth(), // Plural column
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  // Header row
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey.shade100),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(l10n.tableHeaderCase, style: TextStyle(fontWeight: FontWeight.bold)), 
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(l10n.tableHeaderSingular, style: TextStyle(fontWeight: FontWeight.bold)), 
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(l10n.tableHeaderPlural, style: TextStyle(fontWeight: FontWeight.bold)), 
                      ),
                    ],
                  ),
                  // Data rows
                  ...casesOrder.map((caseCode) {
                    final forms = declensionTable[caseCode] ?? {};
                    return TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(_getCaseName(caseCode, l10n)), 
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(forms['sg'] ?? '-'), // Display '-' if null
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(forms['pl'] ?? '-'), // Display '-' if null
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Helper Widget to build the conjugation Table (replaced DataTable) ---
  Widget _buildConjugationTable(List<ConjugationForm> forms, AppLocalizations l10n) {
    // Group forms by person and number
    final Map<String, Map<String, String>> tableData = {}; // {personLabel: {numberLabel: form}}
    
    // --- Person order using l10n
    final personOrder = [
      _getPersonLabel('pri', l10n), // e.g., '1st (I/we)'
      _getPersonLabel('sec', l10n), // e.g., '2nd (you/you)'
      _getPersonLabel('ter', l10n), // e.g., '3rd (he/she/it/they)'
    ];

    // Debug the forms for this table
    print("[_buildConjugationTable] Building table with ${forms.length} forms");
    for (var formInfo in forms) {
      print("[_buildConjugationTable] Processing form: ${formInfo.form} with tag: ${formInfo.tag}");
      
      final tagMap = _parseTag(formInfo.tag); 
      print("[_buildConjugationTable] Parsed tag map: $tagMap");
      
      final form = formInfo.form;
      final person = tagMap['person']; 
      final number = tagMap['number']; 
      
      if (person == null || number == null) {
        print("[_buildConjugationTable] Missing person or number for form: $form, tag: ${formInfo.tag}");
        continue;
      }
      
      final String personKey = _getPersonLabel(person, l10n); 
      final String numberKey = (number == 'sg') ? 'Singular' : (number == 'pl') ? 'Plural' : '-';
      
      if (personKey != '-' && numberKey != '-') { 
        if (!tableData.containsKey(personKey)) tableData[personKey] = {};

        tableData[personKey]![numberKey] = form;
        print("[_buildConjugationTable] Added form $form to tableData[$personKey][$numberKey]");
      } else {
        print("[_buildConjugationTable] Skipping form $form because personKey=$personKey or numberKey=$numberKey");
      }
    }

    // Debug the final tableData
    print("[_buildConjugationTable] Final tableData: $tableData");

    // Build Table
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      columnWidths: const {
        0: IntrinsicColumnWidth(), // Person column
        1: IntrinsicColumnWidth(), // Singular column
        2: IntrinsicColumnWidth(), // Plural column
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        // Header row
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade100),
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(l10n.tableHeaderPerson, style: TextStyle(fontWeight: FontWeight.bold)), 
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(l10n.tableHeaderSingular, style: TextStyle(fontWeight: FontWeight.bold)), 
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(l10n.tableHeaderPlural, style: TextStyle(fontWeight: FontWeight.bold)), 
            ),
          ],
        ),
        // Data rows
        ...personOrder.map((personKey) {
          final personForms = tableData[personKey] ?? {};
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(personKey), 
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(personForms['Singular'] ?? '-'), 
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(personForms['Plural'] ?? '-'), 
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  // --- Helper Function to prepare Conjugation Data ---
    
  String _translateGrammarTerm(String term, AppLocalizations l10n) {
    // Handle combined cases like nom.acc
    if (term.contains('.')) {
      return term.split('.').map((part) => _translateGrammarTerm(part, l10n)).join('.');
    }

    // Try direct lookup using key format 'tag_...' or 'qualifier_...'
    switch (term) {
      // --- Tags ---
      case 'subst': return l10n.tag_subst;
      case 'fin': return l10n.tag_fin;
      case 'adj': return l10n.tag_adj;
      case 'adv': return l10n.tag_adv;
      case 'num': return l10n.tag_num;
      case 'ppron12': return l10n.tag_ppron12;
      case 'ppron3': return l10n.tag_ppron3;
      case 'siebie': return l10n.tag_siebie;
      case 'inf': return l10n.tag_inf;
      case 'praet': return l10n.tag_praet;
      case 'impt': return l10n.tag_impt;
      case 'pred': return l10n.tag_pred;
      case 'prep': return l10n.tag_prep;
      case 'conj': return l10n.tag_conj;
      case 'comp': return l10n.tag_comp;
      case 'interj': return l10n.tag_interj;
      case 'pact': return l10n.tag_pact;
      case 'ppas': return l10n.tag_ppas;
      case 'pcon': return l10n.tag_pcon;
      case 'pant': return l10n.tag_pant;
      case 'ger': return l10n.tag_ger;
      case 'bedzie': return l10n.tag_bedzie;
      case 'aglt': return l10n.tag_aglt;
      case 'qub': return l10n.tag_qub;
      case 'depr': return l10n.tag_depr;
      case 'adja': return l10n.tag_adja;
      case 'adjp': return l10n.tag_adjp;
      case 'cond': return l10n.tag_cond;
      // --- Qualifiers ---
      case 'sg': return l10n.qualifier_sg;
      case 'pl': return l10n.qualifier_pl;
      case 'nom': return l10n.qualifier_nom;
      case 'gen': return l10n.qualifier_gen;
      case 'dat': return l10n.qualifier_dat;
      case 'acc': return l10n.qualifier_acc;
      case 'inst': return l10n.qualifier_inst;
      case 'loc': return l10n.qualifier_loc;
      case 'voc': return l10n.qualifier_voc;
      case 'm1': return l10n.qualifier_m1;
      case 'm2': return l10n.qualifier_m2;
      case 'm3': return l10n.qualifier_m3;
      case 'f': return l10n.qualifier_f;
      case 'n': return l10n.qualifier_n;
      case 'n1': return l10n.qualifier_n1;
      case 'n2': return l10n.qualifier_n2;
      case 'p1': return l10n.qualifier_p1;
      case 'p2': return l10n.qualifier_p2;
      case 'p3': return l10n.qualifier_p3;
      case 'pri': return l10n.qualifier_pri;
      case 'sec': return l10n.qualifier_sec;
      case 'ter': return l10n.qualifier_ter;
      case 'imperf': return l10n.qualifier_imperf;
      case 'perf': return l10n.qualifier_perf;
      case 'nazwa_pospolita': return l10n.qualifier_nazwa_pospolita;
      case 'imie': return l10n.qualifier_imie;
      case 'nazwisko': return l10n.qualifier_nazwisko;
      case 'nazwa_geograficzna': return l10n.qualifier_nazwa_geograficzna;
      case 'skrot': return l10n.qualifier_skrot;
      case 'pos': return l10n.qualifier_pos;
      case 'com': return l10n.qualifier_com;
      case 'sup': return l10n.qualifier_sup;
      default: return term; // Return original term if no translation found
    }
  }

  // --- Helper methods for building conjugation sections ---
  List<Widget> _buildConjugationSections(BuildContext context, Map<String, List<ConjugationForm>> groupedForms, AppLocalizations l10n) {
    // Define the desired order of sections
    final displayOrder = [
      'conjugationCategoryPresentIndicative',
      'conjugationCategoryFuturePerfectiveIndicative',
      'conjugationCategoryFutureImperfectiveIndicative',
      'conjugationCategoryPastTense',
      'conjugationCategoryConditional',
      'conjugationCategoryImperative',
      'conjugationCategoryInfinitive',
      'conjugationCategoryPresentAdverbialParticiple',
      'conjugationCategoryAnteriorAdverbialParticiple',
      'conjugationCategoryPresentActiveParticiple',
      'conjugationCategoryPastPassiveParticiple',
      'conjugationCategoryVerbalNoun',
      'conjugationCategoryPresentImpersonal',
      'conjugationCategoryPastImpersonal',
      'conjugationCategoryFutureImpersonal',
      'conjugationCategoryConditionalImpersonal',
      'conjugationCategoryImperativeImpersonal',
      'conjugationCategoryOtherForms',
    ];

    List<Widget> sections = [];

    for (var key in displayOrder) {
      if (groupedForms.containsKey(key)) {
        final forms = groupedForms[key]!;
        if (forms.isNotEmpty) {
          final title = _getLocalizedConjugationCategoryTitle(key, l10n);
          bool isExpanded = _expandedCategories[key] ?? true; // Default to expanded

          // Determine which builder to use based on the key
          bool useConjugationTable = [
            'conjugationCategoryPresentIndicative',
            'conjugationCategoryFuturePerfectiveIndicative',
            'conjugationCategoryFutureImperfectiveIndicative',
          ].contains(key);

          bool useGerundTable = key == 'conjugationCategoryVerbalNoun';
          bool useConditionalTable = key == 'conjugationCategoryConditional';

          bool useParticipleTable = [
            'conjugationCategoryPresentActiveParticiple',
            'conjugationCategoryPastPassiveParticiple',
          ].contains(key);

          bool usePastTenseTable = key == 'conjugationCategoryPastTense';
          
          bool useSimpleList = [
            'conjugationCategoryImperative',
            'conjugationCategoryInfinitive',
            'conjugationCategoryPresentAdverbialParticiple',
            'conjugationCategoryAnteriorAdverbialParticiple',
            'conjugationCategoryPresentImpersonal',
            'conjugationCategoryPastImpersonal',
            'conjugationCategoryFutureImpersonal',
            'conjugationCategoryConditionalImpersonal',
            'conjugationCategoryImperativeImpersonal',
          ].contains(key);

          bool isImpersonalCategory = [
            'conjugationCategoryPresentImpersonal',
            'conjugationCategoryPastImpersonal',
            'conjugationCategoryFutureImpersonal',
            'conjugationCategoryConditionalImpersonal',
            'conjugationCategoryImperativeImpersonal',
          ].contains(key);

          Widget content;
          if (useConjugationTable) {
            content = _buildConjugationTable(forms, l10n);
          } else if (useGerundTable) {
            content = _buildVerbalNounTable(forms, l10n);
          } else if (useConditionalTable) {
            content = _buildConditionalTable(forms, l10n);
          } else if (useParticipleTable) {
             content = _buildParticipleDeclensionTable(forms, l10n, key == 'conjugationCategoryPresentActiveParticiple');
          } else if (usePastTenseTable) {
             content = _buildPastTenseTable(forms, l10n);
          } else if (useSimpleList) {
            if (isImpersonalCategory) {
              content = _buildImpersonalSection(title, forms, l10n);
            } else {
              content = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: forms.map((form) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: _buildFormWithDescription(form, l10n),
                )).toList(),
              );
            }
          } else {
            // Default simple list view for other categories
            content = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: forms.map((form) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _buildFormWithDescription(form, l10n),
              )).toList(),
            );
          }

          sections.add(
            ExpansionTile(
              key: PageStorageKey<String>(key),
              title: isImpersonalCategory ? 
                Row(
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: Theme.of(context).textTheme.titleMedium!.fontSize! * ref.watch(fontSizeFactorProvider))),
                    const SizedBox(width: 8),
                    Text(
                      "(${l10n.impersonalAccuracyWarning})",
                      style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ) : 
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: Theme.of(context).textTheme.titleMedium!.fontSize! * ref.watch(fontSizeFactorProvider))),
              initiallyExpanded: isExpanded,
              onExpansionChanged: (expanding) => setState(() {
                _expandedCategories[key] = expanding;
              }),
              children: [Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0), child: content)],
            )
          );
          sections.add(const SizedBox(height: 8));
        }
      }
    }
    
    // Add any remaining categories not in displayOrder
    groupedForms.forEach((key, forms) {
       if (!displayOrder.contains(key) && forms.isNotEmpty) {
          final title = _getLocalizedConjugationCategoryTitle(key, l10n);
           sections.add(
             ExpansionTile(
               key: PageStorageKey<String>(key),
               title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: Theme.of(context).textTheme.titleMedium!.fontSize! * ref.watch(fontSizeFactorProvider))),
               initiallyExpanded: true,
               children: [
                 Padding(
                   padding: const EdgeInsets.all(8.0),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: forms.map((form) => Padding(
                       padding: const EdgeInsets.only(bottom: 8.0),
                       child: _buildFormWithDescription(form, l10n),
                     )).toList(),
                   ),
                 ),
               ],
             ),
           );
           sections.add(const SizedBox(height: 8));
       }
    });

    if (sections.isEmpty) {
      return [Center(child: Text(l10n.noConjugationData))];
    } else {
      return sections;
    }
  }

  String _getConjugationCategoryTitle(String key, AppLocalizations l10n) {
    switch (key) {
      case 'conjugationCategoryPresentIndicative': return l10n.conjugationCategoryPresentIndicative;
      case 'conjugationCategoryFuturePerfectiveIndicative': return l10n.conjugationCategoryFuturePerfectiveIndicative;
      case 'conjugationCategoryFutureImperfectiveIndicative': return l10n.conjugationCategoryFutureImperfectiveIndicative;
      case 'conjugationCategoryPastTense': return l10n.conjugationCategoryPastTense;
      case 'conjugationCategoryConditional': return l10n.conjugationCategoryConditional;
      case 'conjugationCategoryImperative': return l10n.conjugationCategoryImperative;
      case 'conjugationCategoryInfinitive': return l10n.conjugationCategoryInfinitive;
      case 'conjugationCategoryPresentAdverbialParticiple': return l10n.conjugationCategoryPresentAdverbialParticiple;
      case 'conjugationCategoryAnteriorAdverbialParticiple': return l10n.conjugationCategoryAnteriorAdverbialParticiple;
      case 'conjugationCategoryPresentActiveParticiple': return l10n.conjugationCategoryPresentActiveParticiple;
      case 'conjugationCategoryPastPassiveParticiple': return l10n.conjugationCategoryPastPassiveParticiple;
      case 'conjugationCategoryVerbalNoun': return l10n.conjugationCategoryVerbalNoun;
      case 'conjugationCategoryPresentImpersonal': return l10n.conjugationCategoryPresentImpersonal;
      case 'conjugationCategoryPastImpersonal': return l10n.conjugationCategoryPastImpersonal;
      case 'conjugationCategoryFutureImpersonal': return l10n.conjugationCategoryFutureImpersonal;
      case 'conjugationCategoryConditionalImpersonal': return l10n.conjugationCategoryConditionalImpersonal;
      case 'conjugationCategoryImperativeImpersonal': return l10n.conjugationCategoryImperativeImpersonal;
      case 'conjugationCategoryOtherForms': return l10n.conjugationCategoryOtherForms;
      default: return key; // Fallback to the key itself
    }
  }

  // --- Helper function to build Participle Declension Table ---
  // (Similar structure to _buildDeclensionResults, but parses pact/ppas tags)
  Widget _buildParticipleDeclensionTable(List<ConjugationForm> forms, AppLocalizations l10n, bool isActive) {
    Map<String, Map<String, String>> declensionTable = {}; // {caseCode: {sg: form, pl: form}}
    final casesOrder = ['nom', 'gen', 'dat', 'acc', 'inst', 'loc', 'voc']; 

    // Find the lemma from the first form (assuming all forms share the same lemma)
    final String lemma = forms.isNotEmpty ? _parseTag(forms.first.tag)['lemma'] ?? 'Participle' : 'Participle'; 
    print("[_buildParticipleDeclensionTable] Building table for: $lemma");

    for (var formInfo in forms) {
      final tagMap = _parseTag(formInfo.tag); 
      // Get case and number from the parsed map (using keys defined in _parseTag for pact/ppas)
      final casePart = tagMap['case']; 
      final numberCode = tagMap['number'];
      // We will ignore gender for simplicity in this table structure

      if (casePart != null && numberCode != null) {
        // Split combined cases like "gen.acc" or "nom.acc.voc"
        final individualCases = casePart.split('.'); 

        for (var caseCode in individualCases) {
           // Ensure the case is one we want to display in the table
          if (casesOrder.contains(caseCode)) { 
            if (!declensionTable.containsKey(caseCode)) {
              declensionTable[caseCode] = {};
            }

            // Assign the form to the singular or plural slot for this case
            // Take the first form encountered for a given slot
            if (numberCode == 'sg') {
              declensionTable[caseCode]!['sg'] ??= formInfo.form; 
            } else if (numberCode == 'pl') {
              declensionTable[caseCode]!['pl'] ??= formInfo.form;
            }
          }
        }
      }
    }

    // Build the Table widget (copied styling from conjugation table)
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      columnWidths: const {
        0: IntrinsicColumnWidth(), // Case column
        1: IntrinsicColumnWidth(), // Singular column
        2: IntrinsicColumnWidth(), // Plural column
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        // Header row
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade100),
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(l10n.tableHeaderCase, style: TextStyle(fontWeight: FontWeight.bold)), 
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(l10n.tableHeaderSingular, style: TextStyle(fontWeight: FontWeight.bold)), 
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(l10n.tableHeaderPlural, style: TextStyle(fontWeight: FontWeight.bold)), 
            ),
          ],
        ),
        // Data rows
        ...casesOrder.map((caseCode) {
          final forms = declensionTable[caseCode] ?? {};
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_getCaseName(caseCode, l10n)), // Pass l10n
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(forms['sg'] ?? '-'), 
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(forms['pl'] ?? '-'), 
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  // --- NEW: Helper function to build Verbal Noun Table ---
  Widget _buildVerbalNounTable(List<ConjugationForm> forms, AppLocalizations l10n) {
    Map<String, Map<String, String>> declensionTable = {}; // {caseCode: {sg: form, pl: form}}
    final casesOrder = ['nom', 'gen', 'dat', 'acc', 'inst', 'loc', 'voc']; 

    for (var formInfo in forms) {
      final tagMap = _parseTag(formInfo.tag); 
      
      // Get case and number from the parsed map
      final casePart = tagMap['case']; // Should now be correctly extracted
      final numberCode = tagMap['number'];

      if (casePart != null && numberCode != null) {
        // Split combined cases like "nom.acc"
        final individualCases = casePart.split('.'); 

        for (var caseCode in individualCases) {
          if (casesOrder.contains(caseCode)) { 
            if (!declensionTable.containsKey(caseCode)) {
              declensionTable[caseCode] = {};
            }
            // Assign the form to the singular or plural slot
            if (numberCode == 'sg') {
              declensionTable[caseCode]!['sg'] ??= formInfo.form; 
            } else if (numberCode == 'pl') {
              declensionTable[caseCode]!['pl'] ??= formInfo.form;
            }
          }
        }
      }
    }

    // Build the Table widget
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      columnWidths: const {
        0: IntrinsicColumnWidth(), // Case column
        1: IntrinsicColumnWidth(), // Singular column
        2: IntrinsicColumnWidth(), // Plural column
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        // Header row
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade100),
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(l10n.tableHeaderCase, style: TextStyle(fontWeight: FontWeight.bold)), 
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(l10n.tableHeaderSingular, style: TextStyle(fontWeight: FontWeight.bold)), 
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(l10n.tableHeaderPlural, style: TextStyle(fontWeight: FontWeight.bold)), 
            ),
          ],
        ),
        // Data rows
        ...casesOrder.map((caseCode) {
          final forms = declensionTable[caseCode] ?? {};
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_getCaseName(caseCode, l10n)), 
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(forms['sg'] ?? '-'), 
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(forms['pl'] ?? '-'), 
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  // --- 과거 시제 테이블 구성 함수 ---
  Widget _buildPastTenseTable(List<ConjugationForm> forms, AppLocalizations l10n) {
    // Table data structure: {person: {number: {genderKey: form}}}
    // person keys: 'pri', 'sec', 'ter'
    // number keys: 'sg', 'pl'
    // gender keys (simplified): 'm', 'f', 'n' (for sg), 'm1', 'f', 'n' (for pl)
    final Map<String, Map<String, Map<String, String>>> tableData = {
      'pri': {'sg': {}, 'pl': {}},
      'sec': {'sg': {}, 'pl': {}},
      'ter': {'sg': {}, 'pl': {}},
    };

    // Person order for rows
    const personOrder = ['pri', 'sec', 'ter'];

    // 1단계: 기본 형태 수집 (명시적으로 레이블이 지정된 3인칭 형태)
    for (var formInfo in forms) {
      if (formInfo.tag.startsWith('praet')) { // 과거 시제 형태만 처리
        final tagMap = _parseTag(formInfo.tag);
        final person = tagMap['person'];
        final number = tagMap['number'];
        final gender = tagMap['gender'];
        final form = formInfo.form;

        // 필수 필드가 존재하는지 확인
        if (person == null || number == null || gender == null) {
          continue;
        }

        // 테이블 구성을 위한 성별 키 결정
        String displayGenderKey = '';
        if (number == 'sg') {
          if (gender.contains('m1') || gender.contains('m2') || gender.contains('m3') || gender == 'm') {
            displayGenderKey = 'm'; // 단수에서 모든 남성 형태를 'm'으로 그룹화
          } else if (gender == 'f') {
            displayGenderKey = 'f';
          } else if (gender.contains('n')) {
            displayGenderKey = 'n'; // 단수에서 n1, n2를 'n'으로 그룹화
          }
        } else if (number == 'pl') {
          if (gender == 'm1' || gender.contains('m1')) {
            displayGenderKey = 'm1'; // 복수 인격 남성
          } else if (gender == 'f' || gender.contains('f')) {
            displayGenderKey = 'f'; // 복수 여성형
          } else if (gender.contains('n')) {
            displayGenderKey = 'n'; // 복수 중성형
          } else {
            displayGenderKey = 'non-m1'; // 분류할 수 없는 비남성
          }
        }

        // tableData 채우기, 각 슬롯에 대해 찾은 첫 번째 형태를 취함
        if (tableData.containsKey(person) && tableData[person]!.containsKey(number) && displayGenderKey.isNotEmpty) {
          tableData[person]![number]![displayGenderKey] ??= form;
        }
      }
    }

    // 2단계: 누락된 1인칭 및 2인칭 형태 채우기
    attemptToAddMissingPersonForms(tableData, forms);

    // 테이블 위젯 구성: 인칭별 행, 수(단수/복수)별 열
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      columnWidths: const {
        0: IntrinsicColumnWidth(), // Person column
        1: IntrinsicColumnWidth(), // Singular column
        2: IntrinsicColumnWidth(), // Plural column
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.top, // 다중 행 셀에 대해 상단 정렬
      children: [
        // 헤더 행
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade100),
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(l10n.tableHeaderPerson, style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(l10n.tableHeaderSingular, style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(l10n.tableHeaderPlural, style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        // 데이터 행 (인칭 순서대로 반복)
        ...personOrder.map((personCode) {
          final sgForms = tableData[personCode]?['sg'] ?? {};
          final plForms = tableData[personCode]?['pl'] ?? {};

          // 성별 레이블로 셀 내용 형식 지정 - 적절한 줄 바꿈을 위해 Column 위젯 사용
          Widget buildSingularCell() {
            List<Widget> contentWidgets = [];
            
            if (sgForms['m'] != null) {
              contentWidgets.add(Text("${sgForms['m']} (${l10n.genderLabelM1}/${l10n.genderLabelM2}/${l10n.genderLabelM3})"));
            }
            if (sgForms['f'] != null) {
              contentWidgets.add(Text("${sgForms['f']} (${l10n.genderLabelF})"));
            }
            if (sgForms['n'] != null) {
              contentWidgets.add(Text("${sgForms['n']} (${l10n.genderLabelN1}/${l10n.genderLabelN2})"));
            }
            
            if (contentWidgets.isEmpty) {
              return Text('-');
            }
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: contentWidgets,
            );
          }
          
          Widget buildPluralCell() {
            List<Widget> contentWidgets = [];
            
            if (plForms['m1'] != null) {
              contentWidgets.add(Text("${plForms['m1']} (${l10n.genderLabelM1})"));
            }
            if (plForms['f'] != null) {
              contentWidgets.add(Text("${plForms['f']} (${l10n.genderLabelF})"));
            }
            if (plForms['n'] != null) {
              contentWidgets.add(Text("${plForms['n']} (${l10n.genderLabelN1}/${l10n.genderLabelN2})"));
            }
            if (plForms['non-m1'] != null && plForms['f'] == null && plForms['n'] == null) {
              contentWidgets.add(Text("${plForms['non-m1']} (non-${l10n.genderLabelM1})"));
            }
            
            if (contentWidgets.isEmpty) {
              return Text('-');
            }
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: contentWidgets,
            );
          }

          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_getPersonLabel(personCode, l10n)), // 인칭 레이블 열
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: buildSingularCell(),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: buildPluralCell(),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  // 과거 시제 테이블에 누락된 1인칭 및 2인칭 형태를 추가하는 보조 함수
  void attemptToAddMissingPersonForms(Map<String, Map<String, Map<String, String>>> tableData, List<ConjugationForm> forms) {
    // 기본 형태로 3인칭 형태를 사용할 수 없는 경우 건너뜁니다
    if (tableData['ter']?['sg']?['m'] == null) {
      return;
    }

    // 필요한 경우 생성에 사용할 기본 형태 가져오기
    String mascSgBase = tableData['ter']!['sg']!['m']!;
    
    // 사용 가능한 경우 복수 기본 형태 가져오기
    String? mascPlBaseM1 = tableData['ter']?['pl']?['m1'];
    String? mascPlBaseNonM1 = tableData['ter']?['pl']?['non-m1'];
    String? femPlBase = tableData['ter']?['pl']?['f'];
    String? neutPlBase = tableData['ter']?['pl']?['n'];
    
    // 1인칭/2인칭을 나타내는 끝이나 Aglt(보조)가 있는 특정 형태 찾기
    for (var form in forms) {
      if (!form.tag.startsWith('praet')) continue;
      
      final String formText = form.form;
      final tagMap = _parseTag(form.tag);
      final gender = tagMap['gender'];
      
      // 공통적인 1인칭/2인칭 어미 및 접미사 확인
      if (formText.endsWith('łem') || formText.endsWith('łam')) {
        // 1인칭 단수일 가능성이 높음
        if (formText.endsWith('łem')) tableData['pri']!['sg']!['m'] ??= formText;
        if (formText.endsWith('łam')) tableData['pri']!['sg']!['f'] ??= formText;
      } else if (formText.endsWith('łeś') || formText.endsWith('łaś')) {
        // 2인칭 단수일 가능성이 높음
        if (formText.endsWith('łeś')) tableData['sec']!['sg']!['m'] ??= formText;
        if (formText.endsWith('łaś')) tableData['sec']!['sg']!['f'] ??= formText;
      } else if (formText.endsWith('liśmy') || formText.endsWith('łiśmy')) {
        // 1인칭 복수 남성일 가능성이 높음
        tableData['pri']!['pl']!['m1'] ??= formText;
      } else if (formText.endsWith('łyśmy')) {
        // 1인칭 복수 비남성일 가능성이 높음
        if (gender == 'f' || gender?.contains('f') == true) {
          tableData['pri']!['pl']!['f'] ??= formText;
        } else if (gender == 'n' || gender?.contains('n') == true) {
          tableData['pri']!['pl']!['n'] ??= formText;
        } else {
          tableData['pri']!['pl']!['non-m1'] ??= formText;
        }
      } else if (formText.endsWith('liście') || formText.endsWith('łiście')) {
        // 2인칭 복수 남성일 가능성이 높음
        tableData['sec']!['pl']!['m1'] ??= formText;
      } else if (formText.endsWith('łyście')) {
        // 2인칭 복수 비남성일 가능성이 높음
        if (gender == 'f' || gender?.contains('f') == true) {
          tableData['sec']!['pl']!['f'] ??= formText;
        } else if (gender == 'n' || gender?.contains('n') == true) {
          tableData['sec']!['pl']!['n'] ??= formText;
        } else {
          tableData['sec']!['pl']!['non-m1'] ??= formText;
        }
      }
    }
    
    // 여전히 형태가 누락된 경우 표준 패턴을 기반으로 생성 시도
    
    // 1인칭 단수 형태
    if (tableData['pri']!['sg']!['m'] == null && mascSgBase.isNotEmpty) {
      // 적절한 접미사를 결정하기 위해 일반적인 mascSgBase 어미 확인
      String suggestedForm;
      if (mascSgBase.endsWith('ł')) {
        suggestedForm = mascSgBase + "em";
      } else {
        suggestedForm = mascSgBase + "em";
      }
      tableData['pri']!['sg']!['m'] = suggestedForm;
    }
    
    // 2인칭 단수 형태
    if (tableData['sec']!['sg']!['m'] == null && mascSgBase.isNotEmpty) {
      // 적절한 접미사를 결정하기 위해 일반적인 mascSgBase 어미 확인
      String suggestedForm;
      if (mascSgBase.endsWith('ł')) {
        suggestedForm = mascSgBase + "eś";
      } else {
        suggestedForm = mascSgBase + "eś";
      }
      tableData['sec']!['sg']!['m'] = suggestedForm;
    }
    
    // 누락된 복수 형태 생성
    
    // 1인칭 복수 남성 형태
    if (tableData['pri']!['pl']!['m1'] == null && mascPlBaseM1 != null && mascPlBaseM1.isNotEmpty) {
      // 일반적으로 'li' 어미를 'liśmy'로 대체하는 패턴
      String suggestedForm;
      if (mascPlBaseM1.endsWith('li')) {
        suggestedForm = mascPlBaseM1.substring(0, mascPlBaseM1.length - 2) + "liśmy";
      } else {
        // 예상된 패턴이 발견되지 않은 경우 대체
        suggestedForm = mascPlBaseM1 + "śmy";
      }
      tableData['pri']!['pl']!['m1'] = suggestedForm;
    }
    
    // 1인칭 복수 여성 형태
    if (tableData['pri']!['pl']!['f'] == null) {
      if (femPlBase != null && femPlBase.isNotEmpty) {
        // 여성 기본형으로부터 생성
        String suggestedForm;
        if (femPlBase.endsWith('ły')) {
          suggestedForm = femPlBase.substring(0, femPlBase.length - 2) + "łyśmy";
        } else {
          suggestedForm = femPlBase + "śmy";
        }
        tableData['pri']!['pl']!['f'] = suggestedForm;
      } else if (mascPlBaseNonM1 != null && mascPlBaseNonM1.isNotEmpty) {
        // non-m1 형태로부터 생성
        String suggestedForm;
        if (mascPlBaseNonM1.endsWith('ły')) {
          suggestedForm = mascPlBaseNonM1.substring(0, mascPlBaseNonM1.length - 2) + "łyśmy";
        } else {
          suggestedForm = mascPlBaseNonM1 + "śmy";
        }
        tableData['pri']!['pl']!['f'] = suggestedForm;
      }
    }
    
    // 1인칭 복수 중성 형태
    if (tableData['pri']!['pl']!['n'] == null) {
      if (neutPlBase != null && neutPlBase.isNotEmpty) {
        // 중성 기본형으로부터 생성
        String suggestedForm;
        if (neutPlBase.endsWith('ły')) {
          suggestedForm = neutPlBase.substring(0, neutPlBase.length - 2) + "łyśmy";
        } else {
          suggestedForm = neutPlBase + "śmy";
        }
        tableData['pri']!['pl']!['n'] = suggestedForm;
      } else if (mascPlBaseNonM1 != null && mascPlBaseNonM1.isNotEmpty) {
        // non-m1 형태로부터 생성
        String suggestedForm;
        if (mascPlBaseNonM1.endsWith('ły')) {
          suggestedForm = mascPlBaseNonM1.substring(0, mascPlBaseNonM1.length - 2) + "łyśmy";
        } else {
          suggestedForm = mascPlBaseNonM1 + "śmy";
        }
        tableData['pri']!['pl']!['n'] = suggestedForm;
      }
    }
    
    // 2인칭 복수 남성 형태
    if (tableData['sec']!['pl']!['m1'] == null && mascPlBaseM1 != null && mascPlBaseM1.isNotEmpty) {
      // 일반적으로 'li' 어미를 'liście'로 대체하는 패턴
      String suggestedForm;
      if (mascPlBaseM1.endsWith('li')) {
        suggestedForm = mascPlBaseM1.substring(0, mascPlBaseM1.length - 2) + "liście";
      } else {
        // 예상된 패턴이 발견되지 않은 경우 대체
        suggestedForm = mascPlBaseM1 + "ście";
      }
      tableData['sec']!['pl']!['m1'] = suggestedForm;
    }
    
    // 2인칭 복수 여성 형태
    if (tableData['sec']!['pl']!['f'] == null) {
      if (femPlBase != null && femPlBase.isNotEmpty) {
        // 여성 기본형으로부터 생성
        String suggestedForm;
        if (femPlBase.endsWith('ły')) {
          suggestedForm = femPlBase.substring(0, femPlBase.length - 2) + "łyście";
        } else {
          suggestedForm = femPlBase + "ście";
        }
        tableData['sec']!['pl']!['f'] = suggestedForm;
      } else if (mascPlBaseNonM1 != null && mascPlBaseNonM1.isNotEmpty) {
        // non-m1 형태로부터 생성
        String suggestedForm;
        if (mascPlBaseNonM1.endsWith('ły')) {
          suggestedForm = mascPlBaseNonM1.substring(0, mascPlBaseNonM1.length - 2) + "łyście";
        } else {
          suggestedForm = mascPlBaseNonM1 + "ście";
        }
        tableData['sec']!['pl']!['f'] = suggestedForm;
      }
    }
    
    // 2인칭 복수 중성 형태
    if (tableData['sec']!['pl']!['n'] == null) {
      if (neutPlBase != null && neutPlBase.isNotEmpty) {
        // 중성 기본형으로부터 생성
        String suggestedForm;
        if (neutPlBase.endsWith('ły')) {
          suggestedForm = neutPlBase.substring(0, neutPlBase.length - 2) + "łyście";
        } else {
          suggestedForm = neutPlBase + "ście";
        }
        tableData['sec']!['pl']!['n'] = suggestedForm;
      } else if (mascPlBaseNonM1 != null && mascPlBaseNonM1.isNotEmpty) {
        // non-m1 형태로부터 생성
        String suggestedForm;
        if (mascPlBaseNonM1.endsWith('ły')) {
          suggestedForm = mascPlBaseNonM1.substring(0, mascPlBaseNonM1.length - 2) + "łyście";
        } else {
          suggestedForm = mascPlBaseNonM1 + "ście";
        }
        tableData['sec']!['pl']!['n'] = suggestedForm;
      }
    }
  }

  // 명령법 및 다른 동사 형태에서 태그 표시를 한글로 변환하는 함수
  String _getFormattedTagDescription(String tag, AppLocalizations l10n) {
    final tagParts = tag.split(':');
    final translatedParts = tagParts.map((part) => _translateGrammarTerm(part, l10n)).toList();
    
    // 언어 설정과 관계없이 태그를 적절한 순서로 정렬하여 표시
    if (translatedParts.isNotEmpty) {
      // 기본 형태 (품사)
      String result = translatedParts[0];
      
      // 단/복수 추가
      if (tagParts.contains('sg')) {
        result += ' ${l10n.qualifier_sg}';
      } else if (tagParts.contains('pl')) {
        result += ' ${l10n.qualifier_pl}';
      }
      
      // 인칭 추가
      if (tagParts.contains('pri')) {
        result += ' ${l10n.qualifier_pri}';
      } else if (tagParts.contains('sec')) {
        result += ' ${l10n.qualifier_sec}';
      } else if (tagParts.contains('ter')) {
        result += ' ${l10n.qualifier_ter}';
      }
      
      // 상 추가 (미완료/완료)
      if (tagParts.contains('imperf')) {
        result += ' ${l10n.qualifier_imperf}';
      } else if (tagParts.contains('perf')) {
        result += ' ${l10n.qualifier_perf}';
      }
      
      return result;
    }
    
    // 변환할 수 없는 경우 원래 태그 반환
    return tagParts.join(':');
  }

  // 시제 정보를 포함한 형태소 태그 설명
  String _getFormMorphDescription(ConjugationForm form, AppLocalizations l10n) {
    // 동사 형태에 대한 한글 설명 생성
    return _getFormattedTagDescription(form.tag, l10n);
  }

  // 기본 형태소를 표시하는 위젯
  Widget _buildFormWithDescription(ConjugationForm form, AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(form.form, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          _getFormMorphDescription(form, l10n),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  // --- Helper function to build Conditional Table ---
  Widget _buildConditionalTable(List<ConjugationForm> forms, AppLocalizations l10n) {
    // Person order for table rows
    const personOrder = ['pri', 'sec', 'ter'];
    
    // Map<Person, Map<Number, Map<Gender, Form>>>
    Map<String, Map<String, Map<String, String>>> conditionalForms = {
      'pri': {'sg': {}, 'pl': {}},
      'sec': {'sg': {}, 'pl': {}},
      'ter': {'sg': {}, 'pl': {}},
    };

    // 디버깅: 받은 조건법 데이터 전체를 로깅
    print("===== 조건법 데이터 디버깅 시작 =====");
    print("조건법 폼 총 ${forms.length}개:");
    for (var form in forms) {
      print("태그: ${form.tag}, 폼: ${form.form}");
    }
    print("===== 조건법 데이터 디버깅 종료 =====");

    // Genders to look for
    const sgGenders = ['m1', 'm2', 'm3', 'f', 'n']; // Check for all possible singular genders
    const plGenders = ['m1', 'm2.m3.f.n']; // Typical plural gender tags

    for (var form in forms) {
      // Parse the tag (e.g., "cond:sg:f:pri:imperf", "cond:pl:m1:ter:imperf")
      List<String> parts = form.tag.split(':');
      if (parts[0] != 'cond') continue; // Ensure it's a conditional form

      String? number;
      String? person;
      String? gender;

      // Extract relevant parts from the tag
      for (String part in parts) {
        if (part == 'sg' || part == 'pl') number = part;
        if (part == 'pri' || part == 'sec' || part == 'ter') person = part;
        // Find the specific gender tag
        if (sgGenders.contains(part) || plGenders.contains(part)) gender = part;
      }

      if (number != null && person != null && gender != null) {
        // 디버깅: 파싱된 요소들 로깅
        print("파싱 결과: number=$number, person=$person, gender=$gender, form=${form.form}");
        
        // Normalize singular masculine genders for display grouping if desired
        String displayGenderKey = gender;
        if (number == 'pl' && gender == 'm2.m3.f.n') {
             displayGenderKey = 'non-m1'; // Use a consistent key for non-personal plural
        }
        // Group m1/m2/m3 under 'm' for singular for simpler table display
        if (number == 'sg' && ['m1', 'm2', 'm3'].contains(gender)) {
            displayGenderKey = 'm';
            // 디버깅: 남성 단수 형태가 변환되는 과정 로깅
            print("남성 단수 변환: 원래 gender=$gender -> displayGenderKey=$displayGenderKey");
        }

         if (conditionalForms.containsKey(person) && conditionalForms[person]!.containsKey(number)) {
           // Store the form using the possibly simplified gender key
           // Use ??= to only assign if the key doesn't exist yet
           conditionalForms[person]![number]![displayGenderKey] ??= form.form;
           // 디버깅: 테이블에 추가된 항목 로깅
           print("테이블에 추가: conditionalForms[$person][$number][$displayGenderKey] = ${form.form}");
         }
      }
    }

    // 디버깅: 최종 조건법 데이터 상태 확인
    print("===== 최종 조건법 테이블 데이터 =====");
    personOrder.forEach((person) {
      print("인칭: $person");
      print("  단수: ${conditionalForms[person]?['sg']}");
      print("  복수: ${conditionalForms[person]?['pl']}");
    });
    print("=====================================");

    // Build the Table widget
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      columnWidths: const {
        0: IntrinsicColumnWidth(), // Person column
        1: IntrinsicColumnWidth(), // Singular column
        2: IntrinsicColumnWidth(), // Plural column
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.top, // Align content top
      children: [
        // Header row
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade100),
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(l10n.tableHeaderPerson, style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(l10n.tableHeaderSingular, style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(l10n.tableHeaderPlural, style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        // Data rows (Iterate through person order)
        ...personOrder.map((personCode) {
          final sgForms = conditionalForms[personCode]?['sg'] ?? {};
          final plForms = conditionalForms[personCode]?['pl'] ?? {};

          // Format cell content with gender labels - using Column widget for proper line breaks
          Widget buildSingularCell() {
            List<Widget> contentWidgets = [];
            
            if (sgForms['m'] != null) {
              contentWidgets.add(Text("${sgForms['m']} (${l10n.genderLabelM1}/${l10n.genderLabelM2}/${l10n.genderLabelM3})"));
            }
            if (sgForms['f'] != null) {
              contentWidgets.add(Text("${sgForms['f']} (${l10n.genderLabelF})"));
            }
            if (sgForms['n'] != null) {
              contentWidgets.add(Text("${sgForms['n']} (${l10n.genderLabelN1}/${l10n.genderLabelN2})"));
            }
            
            if (contentWidgets.isEmpty) {
              return Text('-');
            }
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: contentWidgets,
            );
          }
          
          Widget buildPluralCell() {
            List<Widget> contentWidgets = [];
            
            if (plForms['m1'] != null) {
              contentWidgets.add(Text("${plForms['m1']} (${l10n.genderLabelM1})"));
            }
            if (plForms['f'] != null) {
              contentWidgets.add(Text("${plForms['f']} (${l10n.genderLabelF})"));
            }
            if (plForms['n'] != null) {
              contentWidgets.add(Text("${plForms['n']} (${l10n.genderLabelN1}/${l10n.genderLabelN2})"));
            }
            
            if (contentWidgets.isEmpty) {
              return Text('-');
            }
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: contentWidgets,
            );
          }

          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_getPersonLabel(personCode, l10n)), // Person label column
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: buildSingularCell(),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: buildPluralCell(),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  // --- Helper functions for tag parsing ---

  Map<String, String> _parseTag(String tagString) {
    final parts = tagString.split(':');
    final Map<String, String> tagMap = {'base': parts.isNotEmpty ? parts[0] : ''}; // Ensure base always exists

    // --- Default positions (may be overwritten) ---
    if (parts.length > 1) tagMap['number'] = parts[1];
    if (parts.length > 2) tagMap['case_person_gender'] = parts[2]; // Combined field initially
    if (parts.length > 3) tagMap['gender_aspect_etc'] = parts[3]; // Further combined
    // ... add more generic positions if needed ...
    tagMap['full_tag'] = tagString;

    // --- Specific overrides based on base tag ---
    switch (tagMap['base']) {
      case 'fin': // Finite verb
        if (parts.length > 1) tagMap['number'] = parts[1];
        if (parts.length > 2) tagMap['person'] = parts[2];
        if (parts.length > 3) tagMap['tense_aspect'] = parts[3]; // Includes aspect
        break;
      case 'fut': // Future tense - Add this case to handle future forms properly
        if (parts.length > 1) tagMap['number'] = parts[1];
        if (parts.length > 2) tagMap['person'] = parts[2];
        if (parts.length > 3) tagMap['aspect'] = parts[3];
        break;
      case 'bedzie': // Future auxiliary
        if (parts.length > 1) tagMap['number'] = parts[1];
        if (parts.length > 2) tagMap['person'] = parts[2];
        if (parts.length > 3) tagMap['tense_aspect'] = parts[3]; // Includes aspect
        break;
      case 'impt': // Imperative
      case 'impt_periph': // Periphrastic imperative
        if (parts.length > 1) tagMap['number'] = parts[1];
        if (parts.length > 2) tagMap['person'] = parts[2];
        // No standard aspect/tense here
        break;
      case 'inf': // Infinitive
        if (parts.length > 1) tagMap['aspect'] = parts[1];
        break;
      case 'praet': // Past tense (CRITICAL FIX: Extract person correctly)
        if (parts.length > 1) tagMap['number'] = parts[1];
        // In praet tags, gender is in position 2, person is typically at the end
        if (parts.length > 2) tagMap['gender'] = parts[2];
        if (parts.length > 3) tagMap['aspect'] = parts[3];
        // Look for 'person' in the remaining positions
        for (int i = 4; i < parts.length; i++) {
          if (['pri', 'sec', 'ter'].contains(parts[i])) {
            tagMap['person'] = parts[i];
            break;
          }
        }
        // If person wasn't found, default to 'ter' for 3rd person (most common default)
        tagMap['person'] ??= 'ter';
        break;
      case 'cond': // Conditional (added base tag)
         if (parts.length > 1) tagMap['number'] = parts[1];
         if (parts.length > 2) tagMap['gender'] = parts[2];
         if (parts.length > 3) tagMap['person'] = parts[3]; // Person is in position 3 for conditional
         if (parts.length > 4) tagMap['aspect'] = parts[4]; // Aspect might be present
         break;
      case 'pcon': // Present Adverbial Participle
      case 'pant': // Anterior Adverbial Participle
        // These usually don't have number/case/gender variations shown in simple tables
        if (parts.length > 1) tagMap['aspect'] = parts[1]; // Aspect might be relevant
        break;
      case 'pact': // Present Active Participle
      case 'ppas': // Past Passive Participle
      case 'adja': // Adjectival Active Participle
      case 'adjp': // Adjectival Passive Participle
        if (parts.length > 1) tagMap['number'] = parts[1];
        if (parts.length > 2) tagMap['case'] = parts[2];
        if (parts.length > 3) tagMap['gender'] = parts[3];
        if (parts.length > 4) tagMap['aspect'] = parts[4]; // Aspect
        // Degree might be in pos 5 for adjp/adja
        if (parts.length > 5 && (tagMap['base']=='adja' || tagMap['base']=='adjp')) tagMap['degree'] = parts[5];
        break;
      case 'ger': // Gerund - Improved handling for verbal nouns
        if (parts.length > 1) tagMap['number'] = parts[1];
        if (parts.length > 2) tagMap['case'] = parts[2]; // Case is relevant
        if (parts.length > 3) tagMap['gender'] = parts[3]; // Gender might be relevant technically
        if (parts.length > 4) tagMap['aspect'] = parts[4]; // Aspect
        break;
      case 'imps': // Impersonal
        // No standard number/person/gender. Aspect might be present.
        if (parts.length > 1) tagMap['aspect'] = parts[1]; // Aspect might be relevant
        break;
      case 'subst': // Noun
      case 'depr': // Depreciative Noun
        if (parts.length > 1) tagMap['number'] = parts[1];
        if (parts.length > 2) tagMap['case'] = parts[2];
        if (parts.length > 3) tagMap['gender'] = parts[3];
        // Animacy might be in pos 4 for subst
        if (parts.length > 4 && tagMap['base']=='subst') tagMap['animacy'] = parts[4];
        break;
      case 'adj': // Adjective
        if (parts.length > 1) tagMap['number'] = parts[1];
        if (parts.length > 2) tagMap['case'] = parts[2];
        if (parts.length > 3) tagMap['gender'] = parts[3];
        if (parts.length > 4) tagMap['degree'] = parts[4]; // Degree
        break;
       // Add other base tags as needed (num, pron, adv, prep, conj etc.)
       // ...
    }

    // --- Refined extraction based on identified fields ---
    // Example: If 'case_person_gender' likely holds case based on base tag
    if (['subst', 'depr', 'adj', 'pact', 'ppas', 'adja', 'adjp', 'ger'].contains(tagMap['base']) && parts.length > 2) {
        tagMap['case'] = parts[2];
    }
    // Example: If 'case_person_gender' likely holds person
    if (['fin', 'fut', 'bedzie', 'impt', 'impt_periph'].contains(tagMap['base']) && parts.length > 2) {
        tagMap['person'] = parts[2];
    }
     // Example: If 'gender_aspect_etc' likely holds gender
    if (['subst', 'depr', 'adj', 'pact', 'ppas', 'adja', 'adjp', 'ger', 'praet', 'cond'].contains(tagMap['base']) && parts.length > 3) {
         // Avoid overwriting if already parsed specifically
         tagMap['gender'] ??= parts[3];
    }
     // Example: If 'gender_aspect_etc' likely holds aspect/tense
    if (['fin', 'fut', 'bedzie', 'inf', 'praet', 'cond', 'pcon', 'pant', 'pact', 'ppas', 'adja', 'adjp', 'ger', 'imps'].contains(tagMap['base']) && parts.length > 3) {
         // Use specific field if available, otherwise try general position
         if (tagMap['base'] == 'fin' || tagMap['base'] == 'bedzie' || tagMap['base'] == 'fut') {
            tagMap['tense_aspect'] ??= parts[3];
         } else {
            tagMap['aspect'] ??= parts[3];
         }
    }
    // Add more refinements as needed

    print("[_parseTag] Input: '${tagString}', Output: ${tagMap}"); // Debugging output
    return tagMap;
  }

  // --- Helper functions for displaying human-readable labels ---

  // Returns the localization KEY for the conjugation category
  String _getConjugationCategoryKey(Map<String, String> tagMap) {
    String base = tagMap['base'] ?? '';
    // Try to get aspect from various possible fields in the tagMap
    String aspect = tagMap['aspect'] ?? tagMap['tense_aspect'] ?? tagMap['aspect_voice'] ?? tagMap['mood_gender2'] ?? '';
    String tenseAspect = tagMap['tense_aspect'] ?? tagMap['aspect'] ?? tagMap['gender_tense_aspect'] ?? '';
    String mood = tagMap['mood'] ?? '';

    switch (base) {
      case 'fin':
        if (tenseAspect.contains('imperf')) return 'conjugationCategoryPresentIndicative';
        if (tenseAspect.contains('perf')) return 'conjugationCategoryFuturePerfectiveIndicative';
        return 'conjugationCategoryFiniteVerb'; // Fallback for other finite forms
      case 'bedzie': return 'conjugationCategoryFutureImperfectiveIndicative';
      case 'praet': return 'conjugationCategoryPastTense';
      case 'impt': return 'conjugationCategoryImperative';
      case 'impt_periph': return 'conjugationCategoryImperative';
      case 'inf': return 'conjugationCategoryInfinitive';
      case 'pcon': return 'conjugationCategoryPresentAdverbialParticiple';
      case 'pant': return 'conjugationCategoryAnteriorAdverbialParticiple';
      case 'pact': return 'conjugationCategoryPresentActiveParticiple';
      case 'ppas': return 'conjugationCategoryPastPassiveParticiple';
      case 'ger': return 'conjugationCategoryVerbalNoun';
      // --- MODIFICATION START: Differentiate Impersonal based on aspect --- 
      case 'imps': 
        if (aspect.contains('perf')) {
          return 'conjugationCategoryPastImpersonal'; // Assume perf = past impersonal
        } else { 
          return 'conjugationCategoryPresentImpersonal'; // Assume imperf or no aspect = present impersonal
        }
      // --- MODIFICATION END ---
      case 'cond': return 'conjugationCategoryConditional'; // 조건법
      case 'conjugationCategoryImperativeImpersonal': return 'conjugationCategoryImperativeImpersonal'; // Added for impersonal imperative
      default: return 'conjugationCategoryOtherForms'; // Group others
    }
  }

  String _getPersonLabel(String? personCode, AppLocalizations l10n) {
    switch (personCode) {
      case 'pri': return l10n.personLabelFirst;
      case 'sec': return l10n.personLabelSecond;
      case 'ter': return l10n.personLabelThird;
      default: return personCode ?? '-';
    }
  }

  String _getNumberLabel(String? numberCode) {
    // This function doesn't seem to be used anymore for table headers,
    // but keep it for potential future use or other contexts.
    // If it needs localization, add keys similar to person/gender.
    const map = {'sg': 'Singular', 'pl': 'Plural'};
    return map[numberCode] ?? numberCode ?? '-';
  }

  String _getGenderLabel(String? genderCode, AppLocalizations l10n) {
    switch (genderCode) {
      case 'm1': return l10n.genderLabelM1;
      case 'm2': return l10n.genderLabelM2;
      case 'm3': return l10n.genderLabelM3;
      case 'f': return l10n.genderLabelF;
      case 'n1': return l10n.genderLabelN1;
      case 'n2': return l10n.genderLabelN2;
      default: return genderCode ?? '-';
    }
  }

  String _getCaseName(String? caseCode, AppLocalizations l10n) {
    // Get the AppLocalizations instance from the context
    // Note: This assumes the function is called within a context where l10n is available.
    // If called from a place without context, this needs adjustment.
    switch (caseCode) {
      case 'nom': return l10n.caseNominative;
      case 'gen': return l10n.caseGenitive;
      case 'dat': return l10n.caseDative;
      case 'acc': return l10n.caseAccusative;
      case 'inst': return l10n.caseInstrumental;
      case 'loc': return l10n.caseLocative;
      case 'voc': return l10n.caseVocative;
      default: return caseCode ?? '-'; // Fallback to the code itself or '-'
    }
  }

  // Helper to get a short tag description for list items
  String _getShortTagDescription(String tag, AppLocalizations l10n) {
    final tagMap = _parseTag(tag);
    final base = tagMap['base'] ?? '';
    final aspect = tagMap['aspect'] ?? '';
    
    // 먼저 한글 변환된 전체 태그 설명을 시도
    final formattedDescription = _getFormattedTagDescription(tag, l10n);
    if (formattedDescription != tag) {
      return formattedDescription;
    }
    
    // 기본 설명
    if (aspect.isNotEmpty) {
      if (aspect == 'imperf') return l10n.qualifier_imperf;
      if (aspect == 'perf') return l10n.qualifier_perf;
    }
    
    // 다른 일반적인 필드 시도
    if (tagMap.containsKey('mood')) return _translateGrammarTerm(tagMap['mood']!, l10n);
    if (tagMap.containsKey('case')) return _getCaseName(tagMap['case'], l10n);

    return tagMap['full_tag'] ?? tag; // 원래 태그로 폴백
  }

  // Helper function to format the analysis result with translated terms
  String _getTranslatedAnalysisString(AnalysisResult result, AppLocalizations l10n) {
    List<String> tagParts = result.tag.split(':');
    String baseTag = tagParts.isNotEmpty ? _translateGrammarTerm(tagParts[0], l10n) : result.tag;
    String tagDetails = tagParts.length > 1
        ? tagParts.sublist(1).map((part) => _translateGrammarTerm(part, l10n)).join(':')
        : '';

    String translatedQualifiers = result.qualifiers
        .map((q) => _translateGrammarTerm(q, l10n))
        .join(', ');

    String displayText = '• ${result.lemma} ($baseTag';
    if (tagDetails.isNotEmpty) {
       displayText += ':$tagDetails';
    }
    displayText += ')';
    if (translatedQualifiers.isNotEmpty) {
       displayText += ': $translatedQualifiers';
    }
    return displayText;
  }

  // Helper to get the localized title for a conjugation category key
  String _getLocalizedConjugationCategoryTitle(String categoryKey, AppLocalizations l10n) {
    switch (categoryKey) {
      case 'conjugationCategoryPresentIndicative': return l10n.conjugationCategoryPresentIndicative;
      case 'conjugationCategoryFuturePerfectiveIndicative': return l10n.conjugationCategoryFuturePerfectiveIndicative;
      case 'conjugationCategoryFutureImperfectiveIndicative': return l10n.conjugationCategoryFutureImperfectiveIndicative;
      case 'conjugationCategoryPastTense': return l10n.conjugationCategoryPastTense;
      case 'conjugationCategoryConditional': return l10n.conjugationCategoryConditional;
      case 'conjugationCategoryImperative': return l10n.conjugationCategoryImperative;
      case 'conjugationCategoryInfinitive': return l10n.conjugationCategoryInfinitive;
      case 'conjugationCategoryPresentAdverbialParticiple': return l10n.conjugationCategoryPresentAdverbialParticiple;
      case 'conjugationCategoryAnteriorAdverbialParticiple': return l10n.conjugationCategoryAnteriorAdverbialParticiple;
      case 'conjugationCategoryPresentActiveParticiple': return l10n.conjugationCategoryPresentActiveParticiple;
      case 'conjugationCategoryPastPassiveParticiple': return l10n.conjugationCategoryPastPassiveParticiple;
      case 'conjugationCategoryFiniteVerb': return l10n.conjugationCategoryFiniteVerb;
      case 'conjugationCategoryVerbalNoun': return l10n.conjugationCategoryVerbalNoun;
      case 'conjugationCategoryOtherForms': return l10n.conjugationCategoryOtherForms;
      // --- ADDITIONS for Impersonal separation ---
      case 'conjugationCategoryPresentImpersonal': return l10n.conjugationCategoryPresentImpersonal;
      case 'conjugationCategoryPastImpersonal': return l10n.conjugationCategoryPastImpersonal;
      case 'conjugationCategoryFutureImpersonal': return l10n.conjugationCategoryFutureImpersonal;
      case 'conjugationCategoryConditionalImpersonal': return l10n.conjugationCategoryConditionalImpersonal;
      case 'conjugationCategoryImperativeImpersonal': return l10n.conjugationCategoryImperativeImpersonal;
      // --- END ADDITIONS ---
      default: return categoryKey; // Fallback to the key itself if unknown
    }
  }

  // --- 비인칭 형태 섹션 빌더 함수 수정 ---
  Widget _buildImpersonalSection(String title, List<ConjugationForm> forms, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Text(
              "(${l10n.impersonalAccuracyWarning})",
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: forms.map((form) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: _buildFormWithDescription(form, l10n),
          )).toList(),
        ),
      ],
    );
  }
} 
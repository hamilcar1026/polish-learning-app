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
              final lemmaData = c.data!.first;
              final groupedForms = _prepareGroupedConjugationForms(lemmaData);
              
              if (groupedForms.isEmpty) {
                return Center(child: Text(l10n.noConjugationData));
              }
              
              // Improved layout with scrolling
              return SingleChildScrollView( // Ensure tab content is scrollable
                 padding: const EdgeInsets.symmetric(vertical: 8.0), // Add padding within scroll view
                 child: Card(
                    elevation: 2.0,
                    margin: EdgeInsets.zero, // No margin needed as padding is outside
                    child: Padding(
                       padding: const EdgeInsets.all(12.0),
                       child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min, // Important for proper sizing
                          children: [
                             Text(
                                l10n.conjugationTableTitle(lemmaData.lemma),
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                             ),
                             const SizedBox(height: 10),
                             const Divider(),
                             // Pass l10n to the helper method
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
  Widget _buildConjugationTable(List<ConjugationForm> forms, bool isPastTense, AppLocalizations l10n) {
    // Group forms by person and number
    final Map<String, Map<String, String>> tableData = {}; // {personLabel: {numberLabel: form}}
    final personOrder = ['1st (ja/my)', '2nd (ty/wy)', '3rd (on/ona/ono/oni/one)'];
    // final numberOrder = ['Singular', 'Plural']; // Not needed for Table structure

    for (var formInfo in forms) {
      final tagMap = _parseTag(formInfo.tag); 
      print(">>> _parseTag result: $tagMap"); // <--- 추가 1
      final form = formInfo.form;
      final person = tagMap['person']; 
      final number = tagMap['number']; 
      final gender = tagMap['gender']; 
      
      print(">>> Extracted: person=$person, number=$number"); // <--- 추가 2

      final String personKey = _getPersonLabel(person, l10n); 
      final String numberKey = (number == 'sg') ? 'Singular' : (number == 'pl') ? 'Plural' : '-';
      
      print(">>> Keys: personKey=$personKey, numberKey=$numberKey"); // <--- 추가 3

      if (personKey != '-' && numberKey != '-') { 
        print(">>> Condition met, adding to tableData..."); // <--- 추가 4
        if (!tableData.containsKey(personKey)) tableData[personKey] = {};

        if (isPastTense && gender != null) {
          // Past tense: Append gender info using localized label
          String displayForm = "$form (${_getGenderLabel(gender, l10n)})"; 
          if (tableData[personKey]![numberKey] != null && tableData[personKey]![numberKey] != '-') {
            // Append if multiple genders exist
            tableData[personKey]![numberKey] = "${tableData[personKey]![numberKey]}, $displayForm";
          } else {
            tableData[personKey]![numberKey] = displayForm;
          }
        } else if (!isPastTense) {
          // Other tenses: Directly assign form (Handles potential overwrites from impt/impt_periph)
          tableData[personKey]![numberKey] = form;
        }
      } else {
        print(">>> Condition NOT met, skipping."); // <--- 추가 5
      }
    }

    // Build Table (similar to _buildDeclensionResults)
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
                // Allow slightly more height for past tense genders by using Flexible
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
  Map<String, List<ConjugationForm>> _prepareGroupedConjugationForms(ConjugationResult? conjugationData) {
    // The keys of this map will now be localization keys (e.g., 'conjugationCategoryPresentIndicative')
    final Map<String, List<ConjugationForm>> groupedFormsByKey = {}; 
    if (conjugationData == null || conjugationData.forms.isEmpty) {
      return groupedFormsByKey;
    }

    for (var formInfo in conjugationData.forms) {
      final tagMap = _parseTag(formInfo.tag);
      String categoryKey = _getConjugationCategoryKey(tagMap); // Get the localization key

      if (!groupedFormsByKey.containsKey(categoryKey)) {
        groupedFormsByKey[categoryKey] = [];
      }
      groupedFormsByKey[categoryKey]!.add(formInfo);
    }
    return groupedFormsByKey;
  }

  // Helper function to get localized string for a Morfeusz tag or qualifier
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
     // Define the desired display order using the localization KEYS
     final displayOrder = [
        'conjugationCategoryPresentIndicative',
        'conjugationCategoryFuturePerfectiveIndicative',
        'conjugationCategoryFutureImperfectiveIndicative',
        'conjugationCategoryPastTense',
        'conjugationCategoryImperative',
        'conjugationCategoryInfinitive',
        'conjugationCategoryPresentActiveParticiple',
        'conjugationCategoryPastPassiveParticiple',
        'conjugationCategoryPresentAdverbialParticiple',
        'conjugationCategoryAnteriorAdverbialParticiple',
        'conjugationCategoryOtherForms'
     ];
     final List<String> sortedGroupKeys = groupedForms.keys.where((key) => displayOrder.contains(key)).toList();
     sortedGroupKeys.sort((a, b) => displayOrder.indexOf(a).compareTo(displayOrder.indexOf(b)));
     sortedGroupKeys.addAll(groupedForms.keys.where((key) => !displayOrder.contains(key)).toList()..sort());

     List<Widget> sections = [];
     for (String categoryKey in sortedGroupKeys) {
       final formsInCategory = groupedForms[categoryKey]!;
       final bool isExpanded = _expandedCategories[categoryKey] ?? false; 
       
       // Determine if standard conjugation table should be used
       final bool useConjugationTable = [
            'conjugationCategoryPresentIndicative', 
            'conjugationCategoryFuturePerfectiveIndicative',
            'conjugationCategoryFutureImperfectiveIndicative',
            'conjugationCategoryPastTense',
            'conjugationCategoryImperative' 
       ].contains(categoryKey);

       // Determine if participle declension table should be used
       final bool useParticipleTable = [
           'conjugationCategoryPresentActiveParticiple', 
           'conjugationCategoryPastPassiveParticiple'
       ].contains(categoryKey);

       sections.add(
         InkWell(
           onTap: () => _toggleCategoryExpansion(categoryKey),
           child: Padding(
             padding: const EdgeInsets.symmetric(vertical: 12.0),
             child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Flexible( 
                  // Get the localized title using the helper function
                  child: Text(_getLocalizedConjugationCategoryTitle(categoryKey, l10n), style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold))
                 ),
                 Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
               ],
             ),
           ),
         )
       );

       if (isExpanded) {
         sections.add(
           Padding(
             padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
             child: useConjugationTable
               ? SingleChildScrollView( // Horizontal scroll for conjugation table
                   scrollDirection: Axis.horizontal,
                   child: _buildConjugationTable(formsInCategory, categoryKey == 'conjugationCategoryPastTense', l10n),
                 )
               : useParticipleTable 
                   ? SingleChildScrollView( // Horizontal scroll for participle table
                       scrollDirection: Axis.horizontal,
                       child: _buildParticipleDeclensionTable(formsInCategory, l10n), // Call the new function
                     )
                   : Column( // Vertical list for other non-table items (inf, pcon, pant, ger, etc.)
                       crossAxisAlignment: CrossAxisAlignment.start,
                       mainAxisSize: MainAxisSize.min,
                       children: formsInCategory.map((formInfo) => ListTile(
                         dense: true,
                         title: Text(formInfo.form),
                         subtitle: Text(
                           // Translate the full tag string part by part
                           formInfo.tag.split(':').map((part) => _translateGrammarTerm(part, l10n)).join(':'),
                           style: const TextStyle(fontSize: 12, color: Colors.grey)
                         ),
                       )).toList(),
                     ),
           )
         );
       }
       sections.add(const Divider(height: 1));
     }
     return sections;
   }

  // --- Helper function to build Participle Declension Table ---
  // (Similar structure to _buildDeclensionResults, but parses pact/ppas tags)
  Widget _buildParticipleDeclensionTable(List<ConjugationForm> forms, AppLocalizations l10n) {
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

  // --- Helper functions for tag parsing ---

  Map<String, String> _parseTag(String tagString) {
    final parts = tagString.split(':');
    final Map<String, String> tagMap = {'base': parts.isNotEmpty ? parts[0] : ''}; // Ensure base always exists

    // Enhanced Parsing Logic
    if (parts.length > 1) tagMap['number'] = parts[1];
    if (parts.length > 2) tagMap['case_person'] = parts[2];
    if (parts.length > 3) tagMap['gender_tense_aspect'] = parts[3];
    if (parts.length > 4) tagMap['mood_gender2'] = parts[4];
    if (parts.length > 5) tagMap['aspect_voice'] = parts[5];

    // Specific overrides/corrections based on base tag
    switch (tagMap['base']) {
      case 'fin': // Finite verb
      case 'bedzie': // Future auxiliary
      case 'impt': // Imperative
      case 'impt_periph': // Periphrastic imperative (niech + fin)
        if (parts.length > 1) tagMap['number'] = parts[1];
        if (parts.length > 2) tagMap['person'] = parts[2];
        if (parts.length > 3) tagMap['tense_aspect'] = parts[3]; // Keep original aspect
        // Optional: Add mood specifically if needed
        // if (tagMap['base'] == 'impt_periph') tagMap['mood'] = 'imperative_periphrastic';
        break;
      case 'inf': // Infinitive
        if (parts.length > 1) tagMap['aspect'] = parts[1];
        break;
      case 'praet': // Past tense
        if (parts.length > 1) tagMap['number'] = parts[1];
        if (parts.length > 2) tagMap['gender'] = parts[2];
        if (parts.length > 3) tagMap['aspect'] = parts[3];
        break;
      case 'pcon': // Present Adverbial Participle
      case 'pant': // Anterior Adverbial Participle
        break;
      case 'pact': // Present Active Participle
      case 'ppas': // Past Passive Participle
        if (parts.length > 1) tagMap['number'] = parts[1];
        if (parts.length > 2) tagMap['case'] = parts[2];
        if (parts.length > 3) tagMap['gender'] = parts[3];
        if (parts.length > 4) tagMap['aspect'] = parts[4];
        break;
      case 'subst':
      case 'depr':
      case 'adj':
      case 'adja':
      case 'adjp':
        if (parts.length > 1) tagMap['number'] = parts[1];
        if (parts.length > 2) tagMap['case'] = parts[2];
        if (parts.length > 3) tagMap['gender'] = parts[3];
        break;
    }
    
    // Add the full tag string for reference
    tagMap['full_tag'] = tagString; 

    return tagMap;
  }

  // --- Helper functions for displaying human-readable labels ---

  // Returns the localization KEY for the conjugation category
  String _getConjugationCategoryKey(Map<String, String> tagMap) {
    String base = tagMap['base'] ?? '';
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
    
    // Basic description
    if (aspect.isNotEmpty) {
      if (aspect == 'imperf') return 'imperfective';
      if (aspect == 'perf') return 'perfective';
    }
    
    // Try other common fields
    if (tagMap.containsKey('mood')) return tagMap['mood']!;
    if (tagMap.containsKey('case')) return _getCaseName(tagMap['case'], l10n);

    return tagMap['full_tag'] ?? tag; // Fallback to full tag
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
      case 'conjugationCategoryImperative': return l10n.conjugationCategoryImperative;
      case 'conjugationCategoryInfinitive': return l10n.conjugationCategoryInfinitive;
      case 'conjugationCategoryPresentAdverbialParticiple': return l10n.conjugationCategoryPresentAdverbialParticiple;
      case 'conjugationCategoryAnteriorAdverbialParticiple': return l10n.conjugationCategoryAnteriorAdverbialParticiple;
      case 'conjugationCategoryPresentActiveParticiple': return l10n.conjugationCategoryPresentActiveParticiple;
      case 'conjugationCategoryPastPassiveParticiple': return l10n.conjugationCategoryPastPassiveParticiple;
      case 'conjugationCategoryFiniteVerb': return l10n.conjugationCategoryFiniteVerb;
      case 'conjugationCategoryOtherForms': return l10n.conjugationCategoryOtherForms;
      default: return categoryKey; // Fallback to the key itself if unknown
    }
  }
} 
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
import '../providers/favorites_provider.dart'; // Import favorites provider
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

// --- Add TickerProviderStateMixin for TabController ---
class _SearchScreenState extends ConsumerState<SearchScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  late FlutterTts flutterTts; // Declare FlutterTts instance
  bool _isTtsInitialized = false;
  TabController? _tabController; // Declare TabController

  // --- State variables to control tab visibility reliably ---
  bool _shouldShowDeclensionTab = false;
  bool _shouldShowConjugationTab = false;

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
  // (REMOVED duplicate functions from below)
  bool _isVerbBasedOnAnalysis(List<AnalysisResult> analysisData) {
    if (analysisData.isEmpty) return false; // ADD EMPTY CHECK
    // Check if any analysis result has a verb tag
    // Use startsWith for broader matching (fin:..., praet:...)
    return analysisData.any((result) => result.tag.startsWith('fin') || result.tag.startsWith('praet') || result.tag.startsWith('impt') || result.tag.startsWith('imps') || result.tag.startsWith('inf') || result.tag.startsWith('pcon') || result.tag.startsWith('pant') || result.tag.startsWith('ger') || result.tag.startsWith('pact') || result.tag.startsWith('ppas') || result.tag.startsWith('bedzie') || result.tag.startsWith('cond'));
  }

  bool _isDeclinableBasedOnAnalysis(List<AnalysisResult> analysisData) {
    if (analysisData.isEmpty) return false; // ADD EMPTY CHECK
    // Check if any analysis result has a declinable tag
    // Use startsWith for broader matching
    return analysisData.any((result) =>
        result.tag.startsWith('subst') || // Noun
        result.tag.startsWith('depr') ||  // Depreciative noun
        result.tag.startsWith('adj') ||   // Adjective
        result.tag.startsWith('adja') ||  // Adjectival participle (act)
        result.tag.startsWith('adjp') ||  // Adjectival participle (pass) - often decl like adj
        result.tag.startsWith('num') ||   // Numeral (cardinal, collective) - declined
        result.tag.startsWith('numcol') || // Collective numeral - declined
        result.tag.startsWith('ppron12') || // Personal pronoun 1st/2nd person - declined
        result.tag.startsWith('ppron3') || // Personal pronoun 3rd person - declined
        result.tag.startsWith('siebie') ||   // Reflexive pronoun - declined
        result.tag.startsWith('pact') ||   // Present Active Participle - declines like adj
        result.tag.startsWith('ppas')      // Past Passive Participle - declines like adj
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeTts(); // Initialize TTS
    // Listen to the searchTermProvider and update the text field controller
    ref.listenManual(searchTermProvider, (previous, next) {
       if (next != _controller.text) {
         WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
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
    _tabController?.dispose(); // Dispose TabController
    flutterTts.stop();
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

  // --- Function to update TabController ---
  void _updateTabController(int length) {
    bool controllerChanged = false; // ADD flag back

    // Dispose the old controller if it exists and length changes
    if (_tabController != null && _tabController!.length != length) {
      _tabController!.dispose();
      _tabController = null;
      controllerChanged = true; // ADD flag update back
    }
    // Create a new controller if needed
    if (_tabController == null && length > 0) {
      _tabController = TabController(length: length, vsync: this);
      controllerChanged = true; // ADD flag update back
    }
    // If length becomes 0, dispose the controller
    else if (_tabController != null && length == 0) {
       _tabController!.dispose();
      _tabController = null;
      controllerChanged = true; // ADD flag update back
    }

    // --- ADD setState block back --- 
    if (controllerChanged && mounted) { 
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final submittedWord = ref.watch(submittedWordProvider);
    final l10n = AppLocalizations.of(context)!;
    // Corrected print statement with simpler quoting
    print("[build] Current submittedWord: ${submittedWord == null ? 'null' : '"$submittedWord"'}");

    return Scaffold(
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
      drawer: const AppDrawer(),
      // --- REVERT to Expanded > Consumer > Column(max) layout ---
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column( // Keep the outer Column
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search TextField (remains the same)
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

            // Results area: Wrap the Consumer with Expanded
            Expanded( // Add Expanded back
              child: submittedWord == null
                ? Center(child: Text(l10n.searchHint)) // Initial hint text
                : Consumer(
                    builder: (context, ref, child) {
                      final analysisAsyncValue = ref.watch(analysisProvider(AnalysisParams(word: submittedWord, targetLang: ref.watch(languageCodeProvider))));

                      // --- .when logic ---
                      return analysisAsyncValue.when(
                        data: (analysisResponse) {
                          // --- Handle Suggestion Status ---
                          if (analysisResponse.status == 'suggestion') {
                            if (analysisResponse.suggested_word != null) {
                              final suggested = analysisResponse.suggested_word!;
                              // Simplified suggestion display
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(analysisResponse.message ?? l10n.suggestionDidYouMean(suggested)),
                                    ElevatedButton(
                                      onPressed: () {
                                        ref.read(searchTermProvider.notifier).state = suggested;
                                        _submitSearch(suggested);
                                        print("[Suggestion Accepted] Submitted: \"$suggested\"");
                                      },
                                      child: Text('"$suggested"'),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              return Center(child: Text(analysisResponse.message ?? l10n.suggestionErrorFallback));
                            }
                          }
                          // --- Handle Success Status ---
                          else if (analysisResponse.status == 'success' && analysisResponse.data != null) {
                            final primaryAnalysis = analysisResponse.data!.isNotEmpty ? analysisResponse.data!.first : null;
                            final String? lemma = primaryAnalysis?.lemma;

                            final bool isDeclinable = _isDeclinableBasedOnAnalysis(analysisResponse.data!);
                            final bool isVerb = _isVerbBasedOnAnalysis(analysisResponse.data!);
                            int tabLength = 0;
                            if (isDeclinable) tabLength++;
                            if (isVerb) tabLength++;

                            // Schedule TabController update
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) { _updateTabController(tabLength); }
                            });

                            // <<< REVERT: Use Column > Card > TabBar > Expanded > TabBarView >>>
                            // Remove the outer SingleChildScrollView
                            return SingleChildScrollView(
                              child: Column(
                                children: [
                                  // --- Analysis Info Card (directly in the Column) ---
                                  _buildAnalysisInfoCard(
                                    context, ref, l10n,
                                    submittedWord, // Pass submittedWord directly
                                    analysisResponse, analysisResponse.data!, lemma
                                  ),
                                  // --- TabBar (directly in the Column) ---
                                  if (_tabController != null && _tabController!.length > 0)
                                    TabBar(
                                      controller: _tabController,
                                      tabs: [
                                        if (isDeclinable) Tab(text: l10n.declensionTitle),
                                        if (isVerb) Tab(text: l10n.conjugationTitle),
                                      ],
                                      labelColor: Theme.of(context).colorScheme.primary,
                                      unselectedLabelColor: Colors.grey,
                                      indicatorColor: Theme.of(context).colorScheme.primary,
                                    ),
                                  // --- TabBarView (fixed height container) ---
                                  if (_tabController != null && _tabController!.length > 0)
                                    SizedBox(
                                      height: MediaQuery.of(context).size.height * 0.6, // 화면 높이의 60%로 고정
                                      child: TabBarView(
                                        controller: _tabController,
                                        physics: const NeverScrollableScrollPhysics(), // Keep swipe disabled
                                        children: [
                                          if (isDeclinable) _buildDeclensionTab(submittedWord, l10n),
                                          if (isVerb) _buildConjugationTab(submittedWord, l10n),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ); // <<< End SingleChildScrollView >>>
                          }
                          // --- Handle Error/No Data Status ---
                          else {
                            return Center(child: Text(analysisResponse.message ?? l10n.noAnalysisFound(submittedWord)));
                          }
                        },
                        // --- Loading Callback ---
                        loading: () {
                          return const Center(child: CircularProgressIndicator());
                        },
                        // --- Error Callback ---
                        error: (error, stackTrace) {
                          print("Error in analysisProvider: $error\\n$stackTrace");
                          return Center(child: Text(l10n.loadingError(error.toString())));
                        },
                      );
                    },
                  ),
            ), // End Expanded (This is the outer Expanded for the whole results area)
          ],
        ),
      ),
    );
  }

  // --- _SliverAppBarDelegate for pinning TabBar --- 
  // (Needs to be added to the class)

  // --- Builder for Analysis Info Card ---
  Widget _buildAnalysisInfoCard(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    String word, // Use submitted word passed down
    ApiResponse analysisResponse, // Keep original response for translation
    List<AnalysisResult> displayData, // Use ORIGINAL data for display now
    String? lemma // Lemma for favorites (from original data)
  ) {
    // --- REVERTED: Remove specific check for empty data due to numeral filtering ---
    // if (displayData.isEmpty && analysisResponse.is_numeral_input == true) { // Be specific about the empty case
    //   return Card(
    //     elevation: 2.0,
    //     margin: const EdgeInsets.symmetric(vertical: 8.0),
    //     child: Padding(
    //       padding: const EdgeInsets.all(12.0),
    //       // Use the NEW localization key
    //       child: Text(l10n.noRelevantAnalysisForNumeral, textAlign: TextAlign.center),
    //     ),
    //   );
    // }
    // Handle general empty data case (e.g., API returned success but empty data list)
     if (displayData.isEmpty) { // This check remains, now uses the original data passed in
        return Card(
           elevation: 2.0,
           margin: const EdgeInsets.symmetric(vertical: 8.0),
           child: Padding(
             padding: const EdgeInsets.all(12.0),
             // Use the existing noAnalysisFound key
             child: Text(l10n.noAnalysisFound(word), textAlign: TextAlign.center),
           ),
        );
     }

    // --- ADDED: Check if the input word is a numeral --- 
    final bool isInputNumeral = int.tryParse(word) != null;
    print("[_buildAnalysisInfoCard] Input word: '$word', isInputNumeral: $isInputNumeral");
    // --- END ADDED ---

    // Watch favorite status for the current lemma (only if lemma exists)
    final bool isFavorite = lemma != null ? ref.watch(favoritesProvider).contains(lemma) : false;
    final favoritesNotifier = lemma != null ? ref.read(favoritesProvider.notifier) : null;

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
                        onPressed: () => _speak(word),
                        tooltip: l10n.pronounceWordTooltip,
                        iconSize: 20,
                        padding: const EdgeInsets.only(left: 8),
                        constraints: const BoxConstraints(),
                      ),
                    // Favorite Button (only show if lemma is available)
                    if (lemma != null && favoritesNotifier != null)
                      IconButton(
                        icon: Icon(
                          isFavorite ? Icons.star : Icons.star_border,
                          color: isFavorite ? Colors.amber : null,
                        ),
                        // Use the NEW localization keys
                        tooltip: isFavorite ? l10n.removeFromFavorites : l10n.addToFavorites,
                        onPressed: () {
                           favoritesNotifier.toggleFavorite(lemma);
                        },
                        iconSize: 22,
                        padding: const EdgeInsets.only(left: 8),
                        constraints: const BoxConstraints(),
                      ),
                  ],
                )
              ],
            ),
            // --- MODIFIED: Conditionally display translation --- 
            // Only show translation if the input word is NOT a numeral
            if (!isInputNumeral && analysisResponse.translation_en != null && analysisResponse.translation_en!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                child: Text(
                  "${l10n.translationLabel}: ${analysisResponse.translation_en!}",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic, color: Colors.deepPurple),
                ),
              ),
            // --- END MODIFICATION ---
            const SizedBox(height: 8),
            // Use the helper function to display localized analysis strings using ORIGINAL data
            ...displayData.map((result) {
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
          data: (d) {
            if (d.status == 'success' && d.data != null && d.data!.isNotEmpty) {
              // <<< ADD SingleChildScrollView back INSIDE the tab content >>>
              return SingleChildScrollView(
                 padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                 child: _buildDeclensionResults(d.data!.first, l10n),
              );
            } else {
              return Center(
                  child: Text(d.message ?? l10n.noDeclensionData),
                );
            }
          },
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
              final groupedForms = lemmaData.grouped_forms;

              if (groupedForms.isEmpty) {
                 return Center(child: Text(l10n.noConjugationData));
              }

              // <<< ADD SingleChildScrollView back INSIDE the tab content >>>
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
    // Use the new flag name
    print("[_buildDeclensionResults] is_detailed_numeral_table: ${lemmaData.is_detailed_numeral_table}"); 
    print("[_buildDeclensionResults] grouped_forms type: ${lemmaData.grouped_forms.runtimeType}");
    print("[_buildDeclensionResults] grouped_forms data: ${lemmaData.grouped_forms}");

    // Check the new flag name
    if (lemmaData.is_detailed_numeral_table) { 
      // --- 복합 수사 상세 테이블 생성 (격 x 성별) ---
      // --- Keep existing logic for detailed table ---
      final compositeData = Map<String, Map<String, String>>.from(lemmaData.grouped_forms); 
      // --- DEBUG PRINTS START ---
      print("[_buildDeclensionResults - Detailed Numeral] Attempting to build detailed table.");
      print("[_buildDeclensionResults - Detailed Numeral] compositeData type: ${compositeData.runtimeType}");
      print("[_buildDeclensionResults - Detailed Numeral] compositeData content: $compositeData");
      compositeData.forEach((caseKey, genderMap) {
        print("[_buildDeclensionResults - Detailed Numeral] Case: $caseKey, GenderMap: $genderMap");
        if (genderMap is! Map<String, String>) {
            print("[_buildDeclensionResults - Detailed Numeral] WARNING: GenderMap for case '$caseKey' is NOT Map<String, String>, it is: ${genderMap.runtimeType}");
        }
      });
      // --- DEBUG PRINTS END ---
      final casesOrder = ['nom', 'gen', 'dat', 'acc', 'inst', 'loc', 'voc'];
      final genderOrder = ['m1', 'm2/m3', 'f', 'n']; 
      final genderHeaders = {
        'm1': l10n.tableHeaderM1,
        'm2/m3': l10n.tableHeaderMOther,
        'f': l10n.tableHeaderF,
        'n': l10n.tableHeaderN,
      };

      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Text(
                l10n.declensionTableTitle(lemmaData.lemma), // "{lemma}" 곡용
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              );
            }
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Table(
                  border: TableBorder.all(color: Colors.grey.shade300),
                  // 열 너비 자동 조절 -> 모든 열 내용에 맞게 되돌림
                  columnWidths: Map.fromIterable(
                     [-1, ...genderOrder.asMap().keys], // -1 for Case column index, 0,1,2,3 for gender indices
                     key: (k) => k == -1 ? 0 : k + 1, // Map to actual column indices 0, 1, 2, 3, 4
                     value: (_) => IntrinsicColumnWidth(), // All columns intrinsic
                  ),
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    // 헤더 행
                    TableRow(
                      decoration: BoxDecoration(color: Colors.grey.shade100),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(l10n.tableHeaderCase, style: TextStyle(fontWeight: FontWeight.bold)), // 격
                        ),
                        // 성별 헤더
                        ...genderOrder.map((genderKey) => Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(genderHeaders[genderKey]!, style: TextStyle(fontWeight: FontWeight.bold)),
                            )).toList(),
                      ],
                    ),
                    // 데이터 행
                    ...casesOrder.map((caseCode) {
                      return TableRow(
                        children: [
                          // 격 이름
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(_getCaseName(caseCode, l10n)),
                          ),
                          // 각 성별에 대한 형태
                          ...genderOrder.map((genderKey) {
                            final form = compositeData[caseCode]?[genderKey] ?? '-';
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(form),
                            );
                          }).toList(),
                        ],
                      );
                    }).toList(),
                  ],
                ),
            ),
          ),
        ],
      );
      // --- END 복합 수사 테이블 --- 
    } else {
      // --- 기존 단수/복수 테이블 로직 --- 
        // --- 수정: 형용사 또는 수사인지 확인 (기존 방식) ---
        // grouped_forms는 Map<String, List<DeclensionForm>> 형태여야 함
        bool isAdjectiveOrNumeral = false;
        List<DeclensionForm> formsToDisplay = [];
        // --- DEBUG PRINTS START ---
        print("[_buildDeclensionResults - Standard] Entered standard declension block.");
        print("[_buildDeclensionResults - Standard] grouped_forms type: ${lemmaData.grouped_forms.runtimeType}");
        // --- DEBUG PRINTS END ---
        
        // --- FIX: REMOVE problematic type check and directly cast ---
        // if (lemmaData.grouped_forms is Map<String, List<DeclensionForm>>) { 
        try { // Add try-catch for safety during casting
             final standardGroupedForms = lemmaData.grouped_forms.map(
               (key, value) => MapEntry(key, value as List<DeclensionForm>)
             ); // Cast the values directly
             
             // --- DEBUG PRINT --- 
             print("[_buildDeclensionResults - Standard] Successfully cast to Map<String, List<DeclensionForm>>.");
             print("[_buildDeclensionResults - Standard] Available categories: ${standardGroupedForms.keys.join(', ')}");
             // --- DEBUG PRINT END ---
             isAdjectiveOrNumeral = standardGroupedForms.keys.any((key) => 
                 key.startsWith('declensionCategoryAdjective') || key == 'declensionCategoryNumeral'
             );
            // --- 수정: 표시할 형태 목록 선택 로직 보강 (기존 방식) --- 
            formsToDisplay = 
                standardGroupedForms['declensionCategoryAdjectivePositive'] ??
                standardGroupedForms['declensionCategoryAdjectiveComparative'] ??
                standardGroupedForms['declensionCategoryAdjectiveSuperlative'] ??
                standardGroupedForms['declensionCategoryNoun'] ??
                standardGroupedForms['declensionCategoryPronoun'] ??
                standardGroupedForms['declensionCategoryNumeral'] ??
                [];
             // --- DEBUG PRINT --- 
             print("[_buildDeclensionResults - Standard] formsToDisplay length: ${formsToDisplay.length}");
             // --- DEBUG PRINT END ---
        } catch (e, stacktrace) {
             print("[_buildDeclensionResults - Standard] ERROR casting grouped_forms to Map<String, List<DeclensionForm>>: $e");
             print(stacktrace); // Log stacktrace for detailed error info
             formsToDisplay = []; // Ensure list is empty on error
        }
        // --- END FIX ---

        bool isAdjective = isAdjectiveOrNumeral && lemmaData.grouped_forms.keys.any((key) => key.startsWith('declensionCategoryAdjective'));
        bool isNumeral = isAdjectiveOrNumeral && lemmaData.grouped_forms.keys.any((key) => key == 'declensionCategoryNumeral');
        // -------------------------------------

        // --- 테이블 데이터 구조 (기존 방식: String 저장) ---
        dynamic declensionTable; // Use dynamic to avoid type errors before assignment
        if (isAdjectiveOrNumeral) { // 형용사 또는 수사
          declensionTable = <String, Map<String, Map<String, String>>>{};
        } else { // 명사, 대명사 등
          declensionTable = <String, Map<String, String>>{}; // Case -> Number -> Form
        }
        // --------------------------------------------- 

        final casesOrder = ['nom', 'gen', 'dat', 'acc', 'inst', 'loc', 'voc'];
        final sgGenderOrder = ['m', 'f', 'n', 'all'];
        final plGenderOrder = ['m1pl', 'non_m1', 'all'];

        print("[_buildDeclensionResults - Standard] Found ${formsToDisplay.length} forms to display.");

        // --- 데이터 채우기 (기존 방식: String 저장) ---
        // --- DEBUG PRINT --- 
        print("[_buildDeclensionResults - Standard] Starting loop to populate declensionTable...");
        // --- DEBUG PRINT END ---
        for (var formInfo in formsToDisplay) {
          final tagMap = _parseTag(formInfo.tag);
          final casePart = tagMap['case'];
          final numberCode = tagMap['number'];
          final genderCode = tagMap['gender'];

          if (casePart != null && numberCode != null) {
            final individualCases = casePart.split('.');

            for (var caseCode in individualCases) {
              if (casesOrder.contains(caseCode)) {
                // --- 초기화 (기존 방식) ---
                if (!declensionTable.containsKey(caseCode)) {
                  if (isAdjectiveOrNumeral) {
                    declensionTable[caseCode] = <String, Map<String, String>>{'sg': {}, 'pl': {}};
                  } else {
                    declensionTable[caseCode] = <String, String>{};
                  }
                }
                // ------------------------

                if (numberCode == 'sg') {
                  if (isAdjectiveOrNumeral) {
                      String displayGenderKey = 'all';
                      if (isAdjective || (isNumeral && genderCode != null && genderCode.isNotEmpty)) {
                        if (genderCode != null) {
                           // --- DEBUG PRINT START ---
                           print("[_buildDeclensionResults - Standard Adj/Num SG] Processing form: ${formInfo.form}, genderCode: $genderCode");
                           // --- DEBUG PRINT END ---
                          if (genderCode.contains('.')) {
                            displayGenderKey = 'all';
                          } else if (genderCode.contains('m')) { // Covers m1, m2, m3
                            displayGenderKey = 'm';
                          } else if (genderCode == 'f') {
                            displayGenderKey = 'f';
                          } else if (genderCode.contains('n')) { // Covers n, n1, n2
                            displayGenderKey = 'n';
                          }
                           // --- DEBUG PRINT START ---
                           print("[_buildDeclensionResults - Standard Adj/Num SG] Calculated displayGenderKey: $displayGenderKey");
                           // --- DEBUG PRINT END ---
                        }
                      }
                      declensionTable[caseCode]!['sg'][displayGenderKey] = formInfo.form;
                  } else { 
                      declensionTable[caseCode]!['sg'] = formInfo.form;
                  }
                } else if (numberCode == 'pl') {
                   if (isAdjectiveOrNumeral) {
                      String displayGenderKey = 'all'; // Default to 'all'
                       if (isAdjective || (isNumeral && genderCode != null && genderCode.isNotEmpty)) {
                         if (genderCode != null) {
                           // --- FIX: Map dot-containing plurals (m2.m3.f.n) to non_m1 --- 
                           // Comment out the old logic mapping '.' to 'all'
                           // if (genderCode.contains('.')) {
                           //   displayGenderKey = 'all'; 
                           // }
                           if (genderCode == 'm1') {
                             displayGenderKey = 'm1pl';
                           } else if (genderCode.contains('.') || // Treat m2.m3.f.n etc. as non_m1
                                      genderCode == 'f' || 
                                      genderCode.contains('n') || // Includes n1, n2
                                      genderCode == 'm2' || 
                                      genderCode == 'm3') {
                             displayGenderKey = 'non_m1'; // Map f, n, m2, m3 and composite tags to non_m1
                           } else {
                             // Keep default 'all' only if none of the above match
                             displayGenderKey = 'all'; 
                           }
                           // --- END FIX ---
                         }
                       }
                       // --- DEBUG PRINT for PLURAL --- 
                       print("[_buildDeclensionResults - Standard Adj/Num PL] Processing form: ${formInfo.form}, genderCode: $genderCode, Calculated displayGenderKey: $displayGenderKey"); 
                       // --- END DEBUG PRINT ---
                       declensionTable[caseCode]!['pl'][displayGenderKey] = formInfo.form;
                   } else { 
                       declensionTable[caseCode]!['pl'] = formInfo.form;
                   }
                }
              }
            }
          }
        }
        // --- END 데이터 채우기 ---

        print("[_buildDeclensionResults - Standard] Final declensionTable data: $declensionTable");

        // --- 기존 테이블 UI 생성 --- 
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return Text(
                  l10n.declensionTableTitle(lemmaData.lemma),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                );
              }
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Table(
                    border: TableBorder.all(color: Colors.grey.shade300),
                    columnWidths: const {
                      0: IntrinsicColumnWidth(), // Case column
                      1: IntrinsicColumnWidth(), // Singular column
                      2: IntrinsicColumnWidth(), // Plural column
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.top,
                    children: [
                      // 헤더 행 (기존)
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
                      // 데이터 행 (기존 표시 로직)
                      ...casesOrder.map((caseCode) {
                        final formsMap = declensionTable[caseCode];
                        Widget sgCellContent = const Text('-');
                        Widget plCellContent = const Text('-');

                        if (formsMap != null) {
                          if (isAdjectiveOrNumeral) {
                            List<Widget> sgWidgets = [];
                            // --- Initialize set OUTSIDE the loop --- 
                            Set<String> displayedForms = {}; 
                            // --- DEBUG PRINT START ---
                            print("[_buildDeclensionResults - Standard Adj/Num Build SG Cell] Checking case: $caseCode, sg map: ${formsMap['sg']}");
                            // --- DEBUG PRINT END ---
                            for (var genderKey in sgGenderOrder.where((k) => k != 'all')) {
                              // --- FIX: Check 'all' key as fallback for specific genders ---
                              var form = formsMap['sg']?[genderKey];
                              if (form == null || (form is String && form.isEmpty)) {
                                  if (genderKey == 'm' || genderKey == 'f' || genderKey == 'n') {
                                    form = formsMap['sg']?['all'];
                                    print("[_buildDeclensionResults - Standard Adj/Num Build SG Cell] Fallback check for key '$genderKey', using 'all' key, found form: $form");
                                  }
                              }
                              // --- END FIX ---

                              // --- DEBUG PRINT START ---
                              print("[_buildDeclensionResults - Standard Adj/Num Build SG Cell] Checking genderKey: $genderKey, final form: $form");
                              // --- DEBUG PRINT END ---
                              if (form != null && form is String && form.isNotEmpty) {
                                bool showLabel = ['m', 'f', 'n'].contains(genderKey);
                                // Use a temporary set to avoid duplicate entries 
                                if (!displayedForms.contains(form)) { // Check BEFORE adding
                                  sgWidgets.add(Text(showLabel ? '$form (${_getGenderLabel(genderKey, l10n)})' : form));
                                  displayedForms.add(form); // Add AFTER adding widget
                                }
                              }
                            }
                            if (sgWidgets.isNotEmpty) {
                               sgCellContent = Column(crossAxisAlignment: CrossAxisAlignment.start, children: sgWidgets);
                            }

                            List<Widget> plWidgets = [];
                            for (var genderKey in plGenderOrder.where((k) => k != 'all')) {
                              final form = formsMap['pl']?[genderKey];
                              if (form != null && form is String && form.isNotEmpty) {
                                 bool showLabel = ['m1pl', 'non_m1'].contains(genderKey);
                                plWidgets.add(Text(showLabel ? '$form (${_getGenderLabel(genderKey, l10n)})' : form));
                              }
                            }
                            if (plWidgets.isNotEmpty) {
                               plCellContent = Column(crossAxisAlignment: CrossAxisAlignment.start, children: plWidgets);
                             }
                          } else {
                            // 명사/대명사: 단일 String 표시
                            sgCellContent = Text(formsMap['sg'] ?? '-'); 
                            plCellContent = Text(formsMap['pl'] ?? '-');
                          }
                        }

                        return TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(_getCaseName(caseCode, l10n)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: sgCellContent,
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: plCellContent,
                            ),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
              ),
            ),
          ],
        );
        // --- END 기존 테이블 로직 ---
    }
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
      case 'congr': return l10n.qualifier_congr;
      case 'rec': return l10n.qualifier_rec; 
      case 'ncol': return l10n.qualifier_ncol;
      // --- ADDED: wok/nwok --- 
      case 'wok': return l10n.qualifier_wok;
      case 'nwok': return l10n.qualifier_nwok;
      // --- END ADDED ---
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
          final title = _getLocalizedConjugationCategoryTitle(key, l10n); // Use localized title function
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
              // --- MODIFIED: Wrap title Row children with Flexible/Expanded --- 
              title: isImpersonalCategory ? 
                Row(
                  children: [
                    Expanded( // Wrap title Text with Expanded
                      child: Text(
                        title, 
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: Theme.of(context).textTheme.titleMedium!.fontSize! * ref.watch(fontSizeFactorProvider)
                        ),
                        overflow: TextOverflow.ellipsis, // Add ellipsis for very long titles
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible( // Wrap warning Text with Flexible
                      child: Text(
                        "(${l10n.impersonalAccuracyWarning})",
                        style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: Colors.grey),
                        // overflow: TextOverflow.ellipsis, // Optional: Add ellipsis if warning can also be long
                      ),
                    ),
                  ],
                ) : 
                // --- END MODIFICATION ---
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
          final title = _getLocalizedConjugationCategoryTitle(key, l10n); // Use localized title function
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

    // 모든 형태에 대해 디버그 로깅 추가
    print("=================== 과거 시제 형태 디버깅 ===================");
    for (var form in forms) {
      print("과거 형태: ${form.form}, 태그: ${form.tag}");
    }
    print("===========================================================");

    // 1단계: 기본 형태 수집 (명시적으로 레이블이 지정된 3인칭 형태)
    for (var formInfo in forms) {
      if (formInfo.tag.startsWith('praet')) { // 과거 시제 형태만 처리
        final tagMap = _parseTag(formInfo.tag);
        final person = tagMap['person'];
        final number = tagMap['number'];
        final gender = tagMap['gender'];
        final form = formInfo.form;

        // 디버그 로깅 추가
        print("파싱된 태그: person=$person, number=$number, gender=$gender, form=$form");

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
          } else if (gender == 'n' || gender.contains('n') || gender == 'n1' || gender == 'n2') {
            displayGenderKey = 'n'; // 복수 중성형 - 모든 중성 형태 포함하도록 확장
          } else {
            displayGenderKey = 'non-m1'; // 분류할 수 없는 비남성
          }
        }

        // tableData 채우기, 각 슬롯에 대해 찾은 첫 번째 형태를 취함
        if (tableData.containsKey(person) && tableData[person]!.containsKey(number) && displayGenderKey.isNotEmpty) {
          tableData[person]![number]![displayGenderKey] ??= form;
          // 설정된 값에 대한 디버그 로깅
          print("테이블 항목 설정: tableData[$person][$number][$displayGenderKey] = $form");
        }
      }
    }

    // 테이블 데이터 디버깅 출력
    print("최종 테이블 데이터(누락된 형태 추가 전):");
    personOrder.forEach((person) {
      print("$person: sg=${tableData[person]!['sg']}, pl=${tableData[person]!['pl']}");
    });

    // 2단계: 누락된 1인칭 및 2인칭 형태 채우기
    attemptToAddMissingPersonForms(tableData, forms);

    // 테이블 데이터 디버깅 출력
    print("최종 테이블 데이터(누락된 형태 추가 후):");
    personOrder.forEach((person) {
      print("$person: sg=${tableData[person]!['sg']}, pl=${tableData[person]!['pl']}");
    });

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
            print("==== [DEBUG] sgForms keys: "+sgForms.keys.toString());
            print("==== [DEBUG] sgForms: "+sgForms.toString());
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
    
    // 디버그 로깅 추가
    print("복수 기본 형태: mascPlBaseM1=$mascPlBaseM1, femPlBase=$femPlBase, neutPlBase=$neutPlBase, mascPlBaseNonM1=$mascPlBaseNonM1");
    
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
    
    // 여성 복수 형태에 대한 검사 개선
    femPlBase ??= findFeminineFormFromAPI(forms, 'pl');
    print("찾은 여성형 기본 형태: $femPlBase");

    // 중성 복수 형태에 대한 검사 개선
    neutPlBase ??= findNeuterFormFromAPI(forms, 'pl');
    print("찾은 중성형 기본 형태: $neutPlBase");
    
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
        print("1인칭 복수 여성형 생성: ${tableData['pri']!['pl']!['f']}");
      } else if (mascPlBaseNonM1 != null && mascPlBaseNonM1.isNotEmpty) {
        // non-m1 형태로부터 생성
        String suggestedForm;
        if (mascPlBaseNonM1.endsWith('ły')) {
          suggestedForm = mascPlBaseNonM1.substring(0, mascPlBaseNonM1.length - 2) + "łyśmy";
        } else {
          suggestedForm = mascPlBaseNonM1 + "śmy";
        }
        tableData['pri']!['pl']!['f'] = suggestedForm;
        print("1인칭 복수 여성형 생성(non-m1 기반): ${tableData['pri']!['pl']!['f']}");
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
        print("1인칭 복수 중성형 생성: ${tableData['pri']!['pl']!['n']}");
      } else if (femPlBase != null && femPlBase.isNotEmpty) {
        // 여성 기본형으로부터 생성(중성형 대체)
        String suggestedForm;
        if (femPlBase.endsWith('ły')) {
          suggestedForm = femPlBase.substring(0, femPlBase.length - 2) + "łyśmy";
        } else {
          suggestedForm = femPlBase + "śmy";
        }
        tableData['pri']!['pl']!['n'] = suggestedForm;
        print("1인칭 복수 중성형 생성(여성형 기반): ${tableData['pri']!['pl']!['n']}");
      } else if (mascPlBaseNonM1 != null && mascPlBaseNonM1.isNotEmpty) {
        // non-m1 형태로부터 생성
        String suggestedForm;
        if (mascPlBaseNonM1.endsWith('ły')) {
          suggestedForm = mascPlBaseNonM1.substring(0, mascPlBaseNonM1.length - 2) + "łyśmy";
        } else {
          suggestedForm = mascPlBaseNonM1 + "śmy";
        }
        tableData['pri']!['pl']!['n'] = suggestedForm;
        print("1인칭 복수 중성형 생성(non-m1 기반): ${tableData['pri']!['pl']!['n']}");
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
        print("2인칭 복수 여성형 생성: ${tableData['sec']!['pl']!['f']}");
      } else if (mascPlBaseNonM1 != null && mascPlBaseNonM1.isNotEmpty) {
        // non-m1 형태로부터 생성
        String suggestedForm;
        if (mascPlBaseNonM1.endsWith('ły')) {
          suggestedForm = mascPlBaseNonM1.substring(0, mascPlBaseNonM1.length - 2) + "łyście";
        } else {
          suggestedForm = mascPlBaseNonM1 + "ście";
        }
        tableData['sec']!['pl']!['f'] = suggestedForm;
        print("2인칭 복수 여성형 생성(non-m1 기반): ${tableData['sec']!['pl']!['f']}");
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
        print("2인칭 복수 중성형 생성: ${tableData['sec']!['pl']!['n']}");
      } else if (femPlBase != null && femPlBase.isNotEmpty) {
        // 여성 기본형으로부터 생성(중성형 대체)
        String suggestedForm;
        if (femPlBase.endsWith('ły')) {
          suggestedForm = femPlBase.substring(0, femPlBase.length - 2) + "łyście";
        } else {
          suggestedForm = femPlBase + "ście";
        }
        tableData['sec']!['pl']!['n'] = suggestedForm;
        print("2인칭 복수 중성형 생성(여성형 기반): ${tableData['sec']!['pl']!['n']}");
      } else if (mascPlBaseNonM1 != null && mascPlBaseNonM1.isNotEmpty) {
        // non-m1 형태로부터 생성
        String suggestedForm;
        if (mascPlBaseNonM1.endsWith('ły')) {
          suggestedForm = mascPlBaseNonM1.substring(0, mascPlBaseNonM1.length - 2) + "łyście";
        } else {
          suggestedForm = mascPlBaseNonM1 + "ście";
        }
        tableData['sec']!['pl']!['n'] = suggestedForm;
        print("2인칭 복수 중성형 생성(non-m1 기반): ${tableData['sec']!['pl']!['n']}");
      }
    }
  }
  
  // API 응답에서 특정 성별 및 수의 형태를 찾는 보조 함수
  String? findFeminineFormFromAPI(List<ConjugationForm> forms, String number) {
    for (var form in forms) {
      if (form.tag.startsWith('praet')) {
        final tagMap = _parseTag(form.tag);
        final formNumber = tagMap['number'];
        final gender = tagMap['gender'];
        final person = tagMap['person'];
        
        // 3인칭이고 지정된 수의 여성 형태 찾기
        if (person == 'ter' && formNumber == number && (gender == 'f' || gender?.contains('f') == true)) {
          print("API에서 여성 형태 발견: ${form.form}, 태그: ${form.tag}");
          return form.form;
        }
      }
    }
    return null;
  }
  
  // API 응답에서 중성 형태를 찾는 보조 함수
  String? findNeuterFormFromAPI(List<ConjugationForm> forms, String number) {
    for (var form in forms) {
      if (form.tag.startsWith('praet')) {
        final tagMap = _parseTag(form.tag);
        final formNumber = tagMap['number'];
        final gender = tagMap['gender'];
        final person = tagMap['person'];
        
        // 3인칭이고 지정된 수의 중성 형태 찾기
        if (person == 'ter' && formNumber == number && 
            (gender == 'n' || gender == 'n1' || gender == 'n2' || gender?.contains('n') == true)) {
          print("API에서 중성 형태 발견: ${form.form}, 태그: ${form.tag}");
          return form.form;
        }
      }
    }
    return null;
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
    const sgGenders = ['m1', 'm2', 'm3', 'm1.m2.m3', 'f', 'n']; // 'm1.m2.m3' 추가
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
        // 추가: m1.m2.m3 조합도 인식
        if (part.contains('m1') && part.contains('m2') && part.contains('m3')) gender = 'm1.m2.m3';
      }

      if (number != null && person != null && gender != null) {
        // 복수에서 m2.m3.f.n 태그는 여성/중성 모두에 값 할당
        if (number == 'pl' && gender == 'm2.m3.f.n') {
          if (conditionalForms[person]![number]!['f'] == null) {
            conditionalForms[person]![number]!['f'] = form.form;
          }
          if (conditionalForms[person]![number]!['n'] == null) {
            conditionalForms[person]![number]!['n'] = form.form;
          }
          // 기존 non-m1도 fallback으로 남겨둠
          if (conditionalForms[person]![number]!['non-m1'] == null) {
            conditionalForms[person]![number]!['non-m1'] = form.form;
          }
          continue; // 아래 로직 중복 방지
        }
        // ... existing code ...

        // Normalize singular masculine genders for display grouping if desired
        String displayGenderKey = gender;
        if (number == 'pl' && gender == 'm2.m3.f.n') {
             displayGenderKey = 'non-m1'; // Use a consistent key for non-personal plural
        }
        // Group m1/m2/m3 under 'm' for singular for simpler table display
        if (number == 'sg' && (gender == 'm1' || gender == 'm2' || gender == 'm3' || gender == 'm1.m2.m3')) {
            displayGenderKey = 'm';
            print("남성 단수 변환: 원래 gender=$gender -> displayGenderKey=$displayGenderKey");
        }

         if (conditionalForms.containsKey(person) && conditionalForms[person]!.containsKey(number)) {
          if (conditionalForms[person]![number]![displayGenderKey] == null) {
            conditionalForms[person]![number]![displayGenderKey] = form.form;
            print("테이블에 추가: conditionalForms[$person][$number][$displayGenderKey] = ${form.form}");
          } else {
            print("[경고] 이미 값이 있음: conditionalForms[$person][$number][$displayGenderKey] = ${conditionalForms[person]![number]![displayGenderKey]} (새 값: ${form.form})");
          }
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
            print("==== [DEBUG][COND] sgForms keys: "+sgForms.keys.toString());
            print("==== [DEBUG][COND] sgForms: "+sgForms.toString());
            List<Widget> contentWidgets = [];
            // 남성 단수: m, m1, m2, m3, m1.m2.m3, m1.m2, m2.m3 등 모든 조합을 커버
            final mascKeys = ['m', 'm1', 'm2', 'm3', 'm1.m2.m3', 'm1.m2', 'm2.m3'];
            final foundMasc = mascKeys.where((k) => sgForms[k] != null).toList();
            if (foundMasc.isNotEmpty) {
              for (var k in foundMasc) {
                contentWidgets.add(Text("${sgForms[k]} (${l10n.genderLabelM1}/${l10n.genderLabelM2}/${l10n.genderLabelM3})"));
              }
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
      case 'ppron12': // Personal pronoun (1st/2nd)
      case 'ppron3':  // Personal pronoun (3rd)
      case 'siebie':  // Reflexive pronoun
        if (parts.length > 1) tagMap['number'] = parts[1]; // Usually 'sg' or 'pl'
        if (parts.length > 2) tagMap['case'] = parts[2];   // Case is typically the 3rd part
        if (parts.length > 3) tagMap['gender'] = parts[3]; // Gender/person might be 4th
        if (parts.length > 4) tagMap['person'] = parts[4]; // Or person might be 5th
        // Refine based on specific pronoun if needed
        break;
      case 'num': // Numeral
        if (parts.length > 1) tagMap['number'] = parts[1];
        if (parts.length > 2) tagMap['case'] = parts[2];   // Case is typically 3rd part for numerals
        if (parts.length > 3) tagMap['gender'] = parts[3]; // Gender might be 4th
        // Degree/cardinal/ordinal info might follow
        break;
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
    final String base = tagMap['base'] ?? '';

    switch (base) {
      case 'fin':
        final String tenseAspect = tagMap['tense_aspect'] ?? '';
        if (tenseAspect.contains('imperf')) return 'conjugationCategoryPresentIndicative';
        if (tenseAspect.contains('perf')) return 'conjugationCategoryFuturePerfectiveIndicative';
        return 'conjugationCategoryFiniteVerb'; // Fallback
        
      case 'bedzie': 
        return 'conjugationCategoryFutureImperfectiveIndicative';
        
      case 'praet': 
        return 'conjugationCategoryPastTense';
        
      case 'impt': 
      case 'impt_periph': 
        return 'conjugationCategoryImperative';
        
      case 'inf': 
        return 'conjugationCategoryInfinitive';
        
      case 'pcon': 
        return 'conjugationCategoryPresentAdverbialParticiple';
        
      case 'pant': 
        return 'conjugationCategoryAnteriorAdverbialParticiple';
        
      case 'pact': 
        return 'conjugationCategoryPresentActiveParticiple';
        
      case 'ppas': 
        return 'conjugationCategoryPastPassiveParticiple';
        
      case 'ger': 
        return 'conjugationCategoryVerbalNoun';
        
      case 'imps': {
        final String aspect = tagMap['aspect'] ?? '';
        if (aspect == 'perf' || aspect.contains('perf')) {
          return 'conjugationCategoryPastImpersonal';
        } 
        return 'conjugationCategoryPresentImpersonal';
      }
        
      case 'cond': 
        return 'conjugationCategoryConditional';
        
      case 'conjugationCategoryImperativeImpersonal': 
        return 'conjugationCategoryImperativeImpersonal';
        
      default: 
        return 'conjugationCategoryOtherForms';
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
      // --- 기존 --- 
      case 'm1': return l10n.genderLabelM1;
      case 'm2': return l10n.genderLabelM2;
      case 'm3': return l10n.genderLabelM3;
      case 'f': return l10n.genderLabelF; // 여성은 단/복수 동일 키 사용 가능
      case 'n1': return l10n.genderLabelN1;
      case 'n2': return l10n.genderLabelN2;
      // --- 추가: 형용사 테이블용 단순화된 키 ---
      case 'm': return l10n.genderLabelM; // 단수 남성 통합
      case 'n': return l10n.genderLabelN; // 단수 중성 통합
      case 'm1pl': return l10n.genderLabelM1Pl; // 복수 남성 인격
      case 'non_m1': return l10n.genderLabelNonM1Pl; // 복수 비남성 인격 통합
      // --- Fallback ---
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
          children: forms.map((form) {
            // 태그에서 추출한 정보를 기반으로 형태 설명 생성
            final tagMap = _parseTag(form.tag);
            // Remove the potentially problematic local variable tagAspect
            // final String tagAspect = tagMap['aspect'] ?? '';
            
            // 비인칭 형태에 대한 현지화된 설명 텍스트 생성
            String description = '';
            
            // 태그에 따라 적절한 현지화 키 사용
            if (form.tag.contains('imps:imperf')) {
              description = l10n.impersonalPresentForm;
            } else if (form.tag.contains('imps:perf')) {
              description = l10n.impersonalPastForm;
            } else if (form.tag.contains('fut_imps')) {
              description = l10n.impersonalFutureForm;
            } else if (form.tag.contains('cond_imps')) {
              description = l10n.impersonalConditionalForm;
            } else {
              // 태그 기반 추가 처리 - 직접 tagMap['aspect'] 사용
              if ((tagMap['aspect'] ?? '') == 'imperf') {
                description = l10n.qualifier_imperf;
              } else if ((tagMap['aspect'] ?? '') == 'perf') {
                description = l10n.qualifier_perf;
              } else {
                // 기본 처리: 전체 태그 형식화 시도
                description = _getFormattedTagDescription(form.tag, l10n);
              }
            }
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(form.form, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // 명령법 및 다른 동사 형태에서 태그 표시를 현지화하는 함수
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
    // 특수 케이스 먼저 확인
    if (form.tag.contains('fut_imps')) {
      return l10n.impersonalFutureForm;
    } else if (form.tag.contains('cond_imps')) {
      return l10n.impersonalConditionalForm;
    }
    
    // 그 외 일반적인 태그에 대한 설명 생성
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
} 

// --- Helper class for SliverPersistentHeaderDelegate to pin the TabBar ---
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor, // Match background
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false; // TabBar itself doesn't change
  }
}

// --- Helper Function: Korean Number to Word (1-100) ---
String _getNumberWordKorean(int number) {
  if (number < 1 || number > 100) return "N/A"; // Handle out of range

  const List<String> units = ["", "일", "이", "삼", "사", "오", "육", "칠", "팔", "구"];
  const List<String> tens = ["", "십", "이십", "삼십", "사십", "오십", "육십", "칠십", "팔십", "구십"];
  const String hundred = "백";

  if (number == 100) return hundred;

  int tenDigit = number ~/ 10;
  int unitDigit = number % 10;

  String result = "";
  if (tenDigit > 0) {
    result += (tenDigit == 1 ? "" : tens[tenDigit]); // Handle 10-19 correctly (십, 이십...)
    if (tenDigit == 1) result += tens[1]; // Add "십" for 10-19
  }
  result += units[unitDigit];

  return result.isNotEmpty ? result : "영"; // Should not happen for 1-100, but safe check
}

// --- Helper Function: Polish Number to Word (1-100) ---
String _getNumberWordPolish(int number) {
  if (number < 1 || number > 100) return "N/A";

  const Map<int, String> baseWords = {
    1: "jeden", 2: "dwa", 3: "trzy", 4: "cztery", 5: "pięć", 6: "sześć", 7: "siedem", 8: "osiem", 9: "dziewięć",
    10: "dziesięć", 11: "jedenaście", 12: "dwanaście", 13: "trzynaście", 14: "czternaście", 15: "piętnaście",
    16: "szesnaście", 17: "siedemnaście", 18: "osiemnaście", 19: "dziewiętnaście",
    20: "dwadzieścia", 30: "trzydzieści", 40: "czterdzieści", 50: "pięćdziesiąt", 60: "sześćdziesiąt",
    70: "siedemdziesiąt", 80: "osiemdziesiąt", 90: "dziewięćdziesiąt", 100: "sto"
  };

  if (baseWords.containsKey(number)) {
    return baseWords[number]!;
  }

  int tensDigitVal = number ~/ 10 * 10;
  int onesDigitVal = number % 10;

  String? tensWord = baseWords[tensDigitVal];
  String? onesWord = baseWords[onesDigitVal];

  if (tensWord != null && onesWord != null) {
    return "$tensWord $onesWord";
  }

  return "N/A"; // Fallback if construction fails
}
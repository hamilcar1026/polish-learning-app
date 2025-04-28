import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen_l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
    Locale('ru'),
    Locale('pl')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Polish Learning App'**
  String get appTitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a Polish word'**
  String get searchHint;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @languageSettingTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSettingTitle;

  /// No description provided for @fontSizeSettingTitle.
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get fontSizeSettingTitle;

  /// No description provided for @analysisTitle.
  ///
  /// In en, this message translates to:
  /// **'Analysis'**
  String get analysisTitle;

  /// No description provided for @declensionTitle.
  ///
  /// In en, this message translates to:
  /// **'Declension'**
  String get declensionTitle;

  /// No description provided for @conjugationTitle.
  ///
  /// In en, this message translates to:
  /// **'Conjugation'**
  String get conjugationTitle;

  /// No description provided for @grammarTitle.
  ///
  /// In en, this message translates to:
  /// **'Grammar'**
  String get grammarTitle;

  /// No description provided for @pronounceWordTooltip.
  ///
  /// In en, this message translates to:
  /// **'Pronounce the word'**
  String get pronounceWordTooltip;

  /// No description provided for @searchButtonTooltip.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchButtonTooltip;

  /// Message shown when analysis fails or returns empty.
  ///
  /// In en, this message translates to:
  /// **'No analysis found for \"{word}\".'**
  String noAnalysisFound(String word);

  /// No description provided for @noDeclensionData.
  ///
  /// In en, this message translates to:
  /// **'No declension data found.'**
  String get noDeclensionData;

  /// No description provided for @noConjugationData.
  ///
  /// In en, this message translates to:
  /// **'No conjugation data found.'**
  String get noConjugationData;

  /// No description provided for @loadingError.
  ///
  /// In en, this message translates to:
  /// **'Error loading: {error}'**
  String loadingError(Object error);

  /// No description provided for @tag_subst.
  ///
  /// In en, this message translates to:
  /// **'noun'**
  String get tag_subst;

  /// No description provided for @tag_fin.
  ///
  /// In en, this message translates to:
  /// **'verb (fin)'**
  String get tag_fin;

  /// No description provided for @tag_adj.
  ///
  /// In en, this message translates to:
  /// **'adjective'**
  String get tag_adj;

  /// No description provided for @tag_adv.
  ///
  /// In en, this message translates to:
  /// **'adverb'**
  String get tag_adv;

  /// No description provided for @tag_num.
  ///
  /// In en, this message translates to:
  /// **'numeral'**
  String get tag_num;

  /// No description provided for @tag_ppron12.
  ///
  /// In en, this message translates to:
  /// **'pronoun (1st/2nd)'**
  String get tag_ppron12;

  /// No description provided for @tag_ppron3.
  ///
  /// In en, this message translates to:
  /// **'pronoun (3rd)'**
  String get tag_ppron3;

  /// No description provided for @tag_siebie.
  ///
  /// In en, this message translates to:
  /// **'pronoun (refl)'**
  String get tag_siebie;

  /// No description provided for @tag_inf.
  ///
  /// In en, this message translates to:
  /// **'infinitive'**
  String get tag_inf;

  /// No description provided for @tag_praet.
  ///
  /// In en, this message translates to:
  /// **'verb (past)'**
  String get tag_praet;

  /// No description provided for @tag_impt.
  ///
  /// In en, this message translates to:
  /// **'imperative'**
  String get tag_impt;

  /// No description provided for @tag_pred.
  ///
  /// In en, this message translates to:
  /// **'predicative'**
  String get tag_pred;

  /// No description provided for @tag_prep.
  ///
  /// In en, this message translates to:
  /// **'preposition'**
  String get tag_prep;

  /// No description provided for @tag_conj.
  ///
  /// In en, this message translates to:
  /// **'conjunction'**
  String get tag_conj;

  /// No description provided for @tag_comp.
  ///
  /// In en, this message translates to:
  /// **'comparative marker'**
  String get tag_comp;

  /// No description provided for @tag_interj.
  ///
  /// In en, this message translates to:
  /// **'interjection'**
  String get tag_interj;

  /// No description provided for @tag_pact.
  ///
  /// In en, this message translates to:
  /// **'participle (act)'**
  String get tag_pact;

  /// No description provided for @tag_ppas.
  ///
  /// In en, this message translates to:
  /// **'participle (pass)'**
  String get tag_ppas;

  /// No description provided for @tag_pcon.
  ///
  /// In en, this message translates to:
  /// **'participle (pres adv)'**
  String get tag_pcon;

  /// No description provided for @tag_pant.
  ///
  /// In en, this message translates to:
  /// **'participle (ant adv)'**
  String get tag_pant;

  /// No description provided for @tag_ger.
  ///
  /// In en, this message translates to:
  /// **'gerund'**
  String get tag_ger;

  /// No description provided for @tag_bedzie.
  ///
  /// In en, this message translates to:
  /// **'verb (fut aux)'**
  String get tag_bedzie;

  /// No description provided for @tag_aglt.
  ///
  /// In en, this message translates to:
  /// **'agglutinant'**
  String get tag_aglt;

  /// No description provided for @tag_qub.
  ///
  /// In en, this message translates to:
  /// **'quasilexical unit'**
  String get tag_qub;

  /// No description provided for @tag_depr.
  ///
  /// In en, this message translates to:
  /// **'depreciative noun'**
  String get tag_depr;

  /// No description provided for @tag_adja.
  ///
  /// In en, this message translates to:
  /// **'adj participle (act)'**
  String get tag_adja;

  /// No description provided for @tag_adjp.
  ///
  /// In en, this message translates to:
  /// **'adj participle (pass)'**
  String get tag_adjp;

  /// No description provided for @tag_cond.
  ///
  /// In en, this message translates to:
  /// **'conditional'**
  String get tag_cond;

  /// No description provided for @qualifier_sg.
  ///
  /// In en, this message translates to:
  /// **'sg'**
  String get qualifier_sg;

  /// No description provided for @qualifier_pl.
  ///
  /// In en, this message translates to:
  /// **'pl'**
  String get qualifier_pl;

  /// No description provided for @qualifier_nom.
  ///
  /// In en, this message translates to:
  /// **'nom'**
  String get qualifier_nom;

  /// No description provided for @qualifier_gen.
  ///
  /// In en, this message translates to:
  /// **'gen'**
  String get qualifier_gen;

  /// No description provided for @qualifier_dat.
  ///
  /// In en, this message translates to:
  /// **'dat'**
  String get qualifier_dat;

  /// No description provided for @qualifier_acc.
  ///
  /// In en, this message translates to:
  /// **'acc'**
  String get qualifier_acc;

  /// No description provided for @qualifier_inst.
  ///
  /// In en, this message translates to:
  /// **'inst'**
  String get qualifier_inst;

  /// No description provided for @qualifier_loc.
  ///
  /// In en, this message translates to:
  /// **'loc'**
  String get qualifier_loc;

  /// No description provided for @qualifier_voc.
  ///
  /// In en, this message translates to:
  /// **'voc'**
  String get qualifier_voc;

  /// No description provided for @qualifier_m1.
  ///
  /// In en, this message translates to:
  /// **'m1'**
  String get qualifier_m1;

  /// No description provided for @qualifier_m2.
  ///
  /// In en, this message translates to:
  /// **'m2'**
  String get qualifier_m2;

  /// No description provided for @qualifier_m3.
  ///
  /// In en, this message translates to:
  /// **'m3'**
  String get qualifier_m3;

  /// No description provided for @qualifier_f.
  ///
  /// In en, this message translates to:
  /// **'f'**
  String get qualifier_f;

  /// No description provided for @qualifier_n.
  ///
  /// In en, this message translates to:
  /// **'n'**
  String get qualifier_n;

  /// No description provided for @qualifier_n1.
  ///
  /// In en, this message translates to:
  /// **'n1'**
  String get qualifier_n1;

  /// No description provided for @qualifier_n2.
  ///
  /// In en, this message translates to:
  /// **'n2'**
  String get qualifier_n2;

  /// No description provided for @qualifier_p1.
  ///
  /// In en, this message translates to:
  /// **'p1'**
  String get qualifier_p1;

  /// No description provided for @qualifier_p2.
  ///
  /// In en, this message translates to:
  /// **'p2'**
  String get qualifier_p2;

  /// No description provided for @qualifier_p3.
  ///
  /// In en, this message translates to:
  /// **'p3'**
  String get qualifier_p3;

  /// No description provided for @qualifier_pri.
  ///
  /// In en, this message translates to:
  /// **'1st'**
  String get qualifier_pri;

  /// No description provided for @qualifier_sec.
  ///
  /// In en, this message translates to:
  /// **'2nd'**
  String get qualifier_sec;

  /// No description provided for @qualifier_ter.
  ///
  /// In en, this message translates to:
  /// **'3rd'**
  String get qualifier_ter;

  /// No description provided for @qualifier_imperf.
  ///
  /// In en, this message translates to:
  /// **'imperf'**
  String get qualifier_imperf;

  /// No description provided for @qualifier_perf.
  ///
  /// In en, this message translates to:
  /// **'perf'**
  String get qualifier_perf;

  /// No description provided for @qualifier_nazwa_pospolita.
  ///
  /// In en, this message translates to:
  /// **'common'**
  String get qualifier_nazwa_pospolita;

  /// No description provided for @qualifier_imie.
  ///
  /// In en, this message translates to:
  /// **'name'**
  String get qualifier_imie;

  /// No description provided for @qualifier_nazwisko.
  ///
  /// In en, this message translates to:
  /// **'surname'**
  String get qualifier_nazwisko;

  /// No description provided for @qualifier_nazwa_geograficzna.
  ///
  /// In en, this message translates to:
  /// **'geo.'**
  String get qualifier_nazwa_geograficzna;

  /// No description provided for @qualifier_skrot.
  ///
  /// In en, this message translates to:
  /// **'abbr.'**
  String get qualifier_skrot;

  /// No description provided for @qualifier_pos.
  ///
  /// In en, this message translates to:
  /// **'pos'**
  String get qualifier_pos;

  /// No description provided for @qualifier_com.
  ///
  /// In en, this message translates to:
  /// **'com'**
  String get qualifier_com;

  /// No description provided for @qualifier_sup.
  ///
  /// In en, this message translates to:
  /// **'superlative'**
  String get qualifier_sup;

  /// No description provided for @qualifier_congr.
  ///
  /// In en, this message translates to:
  /// **'congruence'**
  String get qualifier_congr;

  /// Qualifier: non-collective (e.g., for numerals not requiring genitive plural)
  ///
  /// In en, this message translates to:
  /// **'non-collective'**
  String get qualifier_ncol;

  /// Qualifier: rective/governing (e.g., numerals governing the case of the noun)
  ///
  /// In en, this message translates to:
  /// **'governing'**
  String get qualifier_rec;

  /// No description provided for @conjugationCategoryPresentIndicative.
  ///
  /// In en, this message translates to:
  /// **'Present Indicative'**
  String get conjugationCategoryPresentIndicative;

  /// No description provided for @conjugationCategoryFuturePerfectiveIndicative.
  ///
  /// In en, this message translates to:
  /// **'Future Perfective Indicative'**
  String get conjugationCategoryFuturePerfectiveIndicative;

  /// No description provided for @conjugationCategoryFutureImperfectiveIndicative.
  ///
  /// In en, this message translates to:
  /// **'Future Imperfective Indicative'**
  String get conjugationCategoryFutureImperfectiveIndicative;

  /// No description provided for @conjugationCategoryPastTense.
  ///
  /// In en, this message translates to:
  /// **'Past Tense'**
  String get conjugationCategoryPastTense;

  /// No description provided for @conjugationCategoryImperative.
  ///
  /// In en, this message translates to:
  /// **'Imperative'**
  String get conjugationCategoryImperative;

  /// No description provided for @conjugationCategoryInfinitive.
  ///
  /// In en, this message translates to:
  /// **'Infinitive'**
  String get conjugationCategoryInfinitive;

  /// No description provided for @conjugationCategoryPresentAdverbialParticiple.
  ///
  /// In en, this message translates to:
  /// **'Present Adverbial Participle'**
  String get conjugationCategoryPresentAdverbialParticiple;

  /// No description provided for @conjugationCategoryAnteriorAdverbialParticiple.
  ///
  /// In en, this message translates to:
  /// **'Anterior Adverbial Participle'**
  String get conjugationCategoryAnteriorAdverbialParticiple;

  /// No description provided for @conjugationCategoryPresentActiveParticiple.
  ///
  /// In en, this message translates to:
  /// **'Present Active Participle'**
  String get conjugationCategoryPresentActiveParticiple;

  /// No description provided for @conjugationCategoryPastPassiveParticiple.
  ///
  /// In en, this message translates to:
  /// **'Past Passive Participle'**
  String get conjugationCategoryPastPassiveParticiple;

  /// No description provided for @conjugationCategoryFiniteVerb.
  ///
  /// In en, this message translates to:
  /// **'Finite Verb'**
  String get conjugationCategoryFiniteVerb;

  /// No description provided for @conjugationCategoryOtherForms.
  ///
  /// In en, this message translates to:
  /// **'Other Forms'**
  String get conjugationCategoryOtherForms;

  /// No description provided for @conjugationCategoryImpersonal.
  ///
  /// In en, this message translates to:
  /// **'Impersonal'**
  String get conjugationCategoryImpersonal;

  /// No description provided for @conjugationCategoryVerbalNoun.
  ///
  /// In en, this message translates to:
  /// **'Verbal Noun'**
  String get conjugationCategoryVerbalNoun;

  /// No description provided for @conjugationCategoryConditional.
  ///
  /// In en, this message translates to:
  /// **'Conditional'**
  String get conjugationCategoryConditional;

  /// No description provided for @conjugationCategoryPresentImpersonal.
  ///
  /// In en, this message translates to:
  /// **'Present Impersonal'**
  String get conjugationCategoryPresentImpersonal;

  /// No description provided for @conjugationCategoryPastImpersonal.
  ///
  /// In en, this message translates to:
  /// **'Past Impersonal'**
  String get conjugationCategoryPastImpersonal;

  /// Title for the Future Impersonal verb form category
  ///
  /// In en, this message translates to:
  /// **'Future Impersonal'**
  String get conjugationCategoryFutureImpersonal;

  /// Title for the Conditional Impersonal verb form category
  ///
  /// In en, this message translates to:
  /// **'Conditional Impersonal'**
  String get conjugationCategoryConditionalImpersonal;

  /// No description provided for @conjugationCategoryImperativeImpersonal.
  ///
  /// In en, this message translates to:
  /// **'Impersonal Imperative'**
  String get conjugationCategoryImperativeImpersonal;

  /// No description provided for @drawerRecentSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent Searches'**
  String get drawerRecentSearches;

  /// No description provided for @drawerClearRecentSearchesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear Recent Searches'**
  String get drawerClearRecentSearchesTooltip;

  /// No description provided for @drawerClearRecentSearchesDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear Recent Searches?'**
  String get drawerClearRecentSearchesDialogTitle;

  /// No description provided for @drawerClearDialogContent.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get drawerClearDialogContent;

  /// No description provided for @drawerCancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get drawerCancelButton;

  /// No description provided for @drawerClearButton.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get drawerClearButton;

  /// No description provided for @drawerNoRecentSearches.
  ///
  /// In en, this message translates to:
  /// **'No recent searches.'**
  String get drawerNoRecentSearches;

  /// No description provided for @drawerFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get drawerFavorites;

  /// No description provided for @drawerNoFavorites.
  ///
  /// In en, this message translates to:
  /// **'No favorites added yet.'**
  String get drawerNoFavorites;

  /// Label for the system theme option
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get settingsThemeSystem;

  /// Header for the Case column in declension/participle tables
  ///
  /// In en, this message translates to:
  /// **'Case'**
  String get tableHeaderCase;

  /// Header for the Singular column in tables
  ///
  /// In en, this message translates to:
  /// **'Singular'**
  String get tableHeaderSingular;

  /// No description provided for @tableHeaderPlural.
  ///
  /// In en, this message translates to:
  /// **'Plural'**
  String get tableHeaderPlural;

  /// No description provided for @tableHeaderM1.
  ///
  /// In en, this message translates to:
  /// **'Masc. Pers.'**
  String get tableHeaderM1;

  /// No description provided for @tableHeaderMOther.
  ///
  /// In en, this message translates to:
  /// **'Masc. Other'**
  String get tableHeaderMOther;

  /// No description provided for @tableHeaderF.
  ///
  /// In en, this message translates to:
  /// **'Feminine'**
  String get tableHeaderF;

  /// No description provided for @tableHeaderN.
  ///
  /// In en, this message translates to:
  /// **'Neuter'**
  String get tableHeaderN;

  /// Header for the Person column in conjugation tables
  ///
  /// In en, this message translates to:
  /// **'Person'**
  String get tableHeaderPerson;

  /// Nominative case name
  ///
  /// In en, this message translates to:
  /// **'Nominative'**
  String get caseNominative;

  /// Genitive case name
  ///
  /// In en, this message translates to:
  /// **'Genitive'**
  String get caseGenitive;

  /// Dative case name
  ///
  /// In en, this message translates to:
  /// **'Dative'**
  String get caseDative;

  /// Accusative case name
  ///
  /// In en, this message translates to:
  /// **'Accusative'**
  String get caseAccusative;

  /// Instrumental case name
  ///
  /// In en, this message translates to:
  /// **'Instrumental'**
  String get caseInstrumental;

  /// Locative case name
  ///
  /// In en, this message translates to:
  /// **'Locative'**
  String get caseLocative;

  /// Vocative case name
  ///
  /// In en, this message translates to:
  /// **'Vocative'**
  String get caseVocative;

  /// Menu item text for Contributors
  ///
  /// In en, this message translates to:
  /// **'Contributors'**
  String get settingsContributors;

  /// Label for the first person in conjugation tables
  ///
  /// In en, this message translates to:
  /// **'1st (I/we)'**
  String get personLabelFirst;

  /// Label for the second person in conjugation tables
  ///
  /// In en, this message translates to:
  /// **'2nd (you/you)'**
  String get personLabelSecond;

  /// Label for the third person in conjugation tables
  ///
  /// In en, this message translates to:
  /// **'3rd (he/she/it/they)'**
  String get personLabelThird;

  /// Label for masculine personal gender (m1)
  ///
  /// In en, this message translates to:
  /// **'Masc. Personal'**
  String get genderLabelM1;

  /// Label for masculine animate gender (m2)
  ///
  /// In en, this message translates to:
  /// **'Masc. Animate'**
  String get genderLabelM2;

  /// Label for masculine inanimate gender (m3)
  ///
  /// In en, this message translates to:
  /// **'Masc. Inanimate'**
  String get genderLabelM3;

  /// Label for feminine gender (f)
  ///
  /// In en, this message translates to:
  /// **'Feminine'**
  String get genderLabelF;

  /// Label for neuter gender type 1 (n1)
  ///
  /// In en, this message translates to:
  /// **'Neuter 1'**
  String get genderLabelN1;

  /// Label for neuter gender type 2 (n2)
  ///
  /// In en, this message translates to:
  /// **'Neuter 2'**
  String get genderLabelN2;

  /// Title format for the declension table, includes lemma placeholder
  ///
  /// In en, this message translates to:
  /// **'Declension for \"{lemma}\"'**
  String declensionTableTitle(String lemma);

  /// Title format for the conjugation table, includes lemma placeholder
  ///
  /// In en, this message translates to:
  /// **'Conjugation for \"{lemma}\"'**
  String conjugationTableTitle(String lemma);

  /// No description provided for @translationLabel.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get translationLabel;

  /// Suggestion message shown when the user might have misspelled a diacritic.
  ///
  /// In en, this message translates to:
  /// **'Did you mean \"{suggestedWord}\"?'**
  String suggestionDidYouMean(String suggestedWord);

  /// Fallback message if suggestion status received but word is null.
  ///
  /// In en, this message translates to:
  /// **'Suggestion could not be loaded.'**
  String get suggestionErrorFallback;

  /// Message shown when a numeral is detected but no 'num' tagged analysis is found after filtering.
  ///
  /// In en, this message translates to:
  /// **'No relevant analysis for numeral found.'**
  String get noRelevantAnalysisForNumeral;

  /// Tooltip for the button to remove a word from favorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFromFavorites;

  /// Tooltip for the button to add a word to favorites.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get addToFavorites;

  /// Warning text displayed next to impersonal conjugation titles.
  ///
  /// In en, this message translates to:
  /// **'Impersonal forms may be less accurate'**
  String get impersonalAccuracyWarning;

  /// Description for the impersonal present form
  ///
  /// In en, this message translates to:
  /// **'Impersonal present form (imperf)'**
  String get impersonalPresentForm;

  /// Description for the impersonal past form
  ///
  /// In en, this message translates to:
  /// **'Impersonal past form (perf)'**
  String get impersonalPastForm;

  /// Description for the impersonal future form
  ///
  /// In en, this message translates to:
  /// **'Impersonal future form'**
  String get impersonalFutureForm;

  /// Description for the impersonal conditional form
  ///
  /// In en, this message translates to:
  /// **'Impersonal conditional form'**
  String get impersonalConditionalForm;

  /// Label for language selection in settings
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// Label for singular masculine gender (combines m1, m2, m3)
  ///
  /// In en, this message translates to:
  /// **'masculine'**
  String get genderLabelM;

  /// Label for singular neuter gender (combines n, n1, n2)
  ///
  /// In en, this message translates to:
  /// **'neuter'**
  String get genderLabelN;

  /// Label for plural masculine personal gender (m1)
  ///
  /// In en, this message translates to:
  /// **'masc. pers.'**
  String get genderLabelM1Pl;

  /// Label for plural non-masculine personal gender (combines f, n, m2, m3)
  ///
  /// In en, this message translates to:
  /// **'non-masc. pers.'**
  String get genderLabelNonM1Pl;

  /// No description provided for @copyrightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Copyrights'**
  String get copyrightsTitle;

  /// No description provided for @fontSizeSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get fontSizeSmall;

  /// No description provided for @fontSizeMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get fontSizeMedium;

  /// No description provided for @fontSizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get fontSizeLarge;

  /// No description provided for @copyrightNotice.
  ///
  /// In en, this message translates to:
  /// **'This program was created using the morfeusz2 api.'**
  String get copyrightNotice;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ko', 'pl', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ko': return AppLocalizationsKo();
    case 'pl': return AppLocalizationsPl();
    case 'ru': return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}

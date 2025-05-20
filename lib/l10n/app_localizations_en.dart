import 'app_localizations.dart';

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Polish Learning App';

  @override
  String get searchHint => 'Enter a Polish word';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get languageSettingTitle => 'Language';

  @override
  String get fontSizeSettingTitle => 'Font Size';

  @override
  String get analysisTitle => 'Analysis';

  @override
  String get declensionTitle => 'Declension';

  @override
  String get conjugationTitle => 'Conjugation';

  @override
  String get grammarTitle => 'Grammar';

  @override
  String get pronounceWordTooltip => 'Pronounce the word';

  @override
  String get searchButtonTooltip => 'Search for the word';

  @override
  String noAnalysisFound(String word) {
    return 'No analysis found for \"$word\".';
  }

  @override
  String get noDeclensionData => 'No declension data found.';

  @override
  String get noConjugationData => 'No conjugation data found.';

  @override
  String loadingError(Object error) {
    return 'Error loading: $error';
  }

  @override
  String get tag_subst => 'noun';

  @override
  String get tag_fin => 'verb (fin)';

  @override
  String get tag_adj => 'adjective';

  @override
  String get tag_adv => 'adverb';

  @override
  String get tag_num => 'numeral';

  @override
  String get tag_ppron12 => 'pronoun (1st/2nd)';

  @override
  String get tag_ppron3 => 'pronoun (3rd)';

  @override
  String get tag_siebie => 'pronoun (refl)';

  @override
  String get tag_inf => 'infinitive';

  @override
  String get tag_praet => 'verb (past)';

  @override
  String get tag_impt => 'imperative';

  @override
  String get tag_pred => 'predicative';

  @override
  String get tag_prep => 'preposition';

  @override
  String get tag_conj => 'conjunction';

  @override
  String get tag_comp => 'comparative marker';

  @override
  String get tag_interj => 'interjection';

  @override
  String get tag_pact => 'participle (act)';

  @override
  String get tag_ppas => 'participle (pass)';

  @override
  String get tag_pcon => 'participle (pres adv)';

  @override
  String get tag_pant => 'participle (ant adv)';

  @override
  String get tag_ger => 'gerund';

  @override
  String get tag_bedzie => 'verb (fut aux)';

  @override
  String get tag_aglt => 'agglutinant';

  @override
  String get tag_qub => 'quasilexical unit';

  @override
  String get tag_depr => 'depreciative noun';

  @override
  String get tag_adja => 'adj participle (act)';

  @override
  String get tag_adjp => 'adj participle (pass)';

  @override
  String get tag_cond => 'conditional';

  @override
  String get qualifier_sg => 'sg';

  @override
  String get qualifier_pl => 'pl';

  @override
  String get qualifier_nom => 'nom';

  @override
  String get qualifier_gen => 'gen';

  @override
  String get qualifier_dat => 'dat';

  @override
  String get qualifier_acc => 'acc';

  @override
  String get qualifier_inst => 'inst';

  @override
  String get qualifier_loc => 'loc';

  @override
  String get qualifier_voc => 'voc';

  @override
  String get qualifier_m1 => 'm1';

  @override
  String get qualifier_m2 => 'm2';

  @override
  String get qualifier_m3 => 'm3';

  @override
  String get qualifier_f => 'f';

  @override
  String get qualifier_n => 'n';

  @override
  String get qualifier_n1 => 'n1';

  @override
  String get qualifier_n2 => 'n2';

  @override
  String get qualifier_p1 => 'p1';

  @override
  String get qualifier_p2 => 'p2';

  @override
  String get qualifier_p3 => 'p3';

  @override
  String get qualifier_pri => '1st';

  @override
  String get qualifier_sec => '2nd';

  @override
  String get qualifier_ter => '3rd';

  @override
  String get qualifier_imperf => 'imperf';

  @override
  String get qualifier_perf => 'perf';

  @override
  String get qualifier_nazwa_pospolita => 'common';

  @override
  String get qualifier_imie => 'name';

  @override
  String get qualifier_nazwisko => 'surname';

  @override
  String get qualifier_nazwa_geograficzna => 'geo.';

  @override
  String get qualifier_skrot => 'abbr.';

  @override
  String get qualifier_pos => 'pos';

  @override
  String get qualifier_com => 'com';

  @override
  String get qualifier_sup => 'superlative';

  @override
  String get qualifier_congr => 'congruence';

  @override
  String get qualifier_ncol => 'non-collective';

  @override
  String get qualifier_rec => 'governing';

  @override
  String get conjugationCategoryPresentIndicative => 'Present Indicative';

  @override
  String get conjugationCategoryFuturePerfectiveIndicative => 'Future Perfective Indicative';

  @override
  String get conjugationCategoryFutureImperfectiveIndicative => 'Future Imperfective Indicative';

  @override
  String get conjugationCategoryPastTense => 'Past Tense';

  @override
  String get conjugationCategoryImperative => 'Imperative';

  @override
  String get conjugationCategoryInfinitive => 'Infinitive';

  @override
  String get conjugationCategoryPresentAdverbialParticiple => 'Present Adverbial Participle';

  @override
  String get conjugationCategoryAnteriorAdverbialParticiple => 'Anterior Adverbial Participle';

  @override
  String get conjugationCategoryPresentActiveParticiple => 'Present Active Participle';

  @override
  String get conjugationCategoryPastPassiveParticiple => 'Past Passive Participle';

  @override
  String get conjugationCategoryFiniteVerb => 'Finite Verb';

  @override
  String get conjugationCategoryOtherForms => 'Other Forms';

  @override
  String get conjugationCategoryImpersonal => 'Impersonal';

  @override
  String get conjugationCategoryVerbalNoun => 'Verbal Noun';

  @override
  String get conjugationCategoryConditional => 'Conditional';

  @override
  String get conjugationCategoryPresentImpersonal => 'Present Impersonal';

  @override
  String get conjugationCategoryPastImpersonal => 'Past Impersonal';

  @override
  String get conjugationCategoryFutureImpersonal => 'Future Impersonal';

  @override
  String get conjugationCategoryConditionalImpersonal => 'Conditional Impersonal';

  @override
  String get conjugationCategoryImperativeImpersonal => 'Impersonal Imperative';

  @override
  String get drawerRecentSearches => 'Recent Searches';

  @override
  String get drawerClearRecentSearchesTooltip => 'Clear Recent Searches';

  @override
  String get drawerClearRecentSearchesDialogTitle => 'Clear Recent Searches?';

  @override
  String get drawerClearDialogContent => 'This action cannot be undone.';

  @override
  String get drawerCancelButton => 'Cancel';

  @override
  String get drawerClearButton => 'Clear';

  @override
  String get drawerNoRecentSearches => 'No recent searches.';

  @override
  String get drawerFavorites => 'Favorites';

  @override
  String get drawerNoFavorites => 'No favorites added yet.';

  @override
  String get settingsThemeSystem => 'System Default';

  @override
  String get tableHeaderCase => 'Case';

  @override
  String get tableHeaderSingular => 'Singular';

  @override
  String get tableHeaderPlural => 'Plural';

  @override
  String get tableHeaderM1 => 'Masc. Pers.';

  @override
  String get tableHeaderMOther => 'Masc. Other';

  @override
  String get tableHeaderF => 'Feminine';

  @override
  String get tableHeaderN => 'Neuter';

  @override
  String get tableHeaderPerson => 'Person';

  @override
  String get caseNominative => 'Nominative';

  @override
  String get caseGenitive => 'Genitive';

  @override
  String get caseDative => 'Dative';

  @override
  String get caseAccusative => 'Accusative';

  @override
  String get caseInstrumental => 'Instrumental';

  @override
  String get caseLocative => 'Locative';

  @override
  String get caseVocative => 'Vocative';

  @override
  String get settingsContributors => 'Contributors';

  @override
  String get personLabelFirst => '1st\n(I/we)';

  @override
  String get personLabelSecond => '2nd\n(you/you)';

  @override
  String get personLabelThird => '3rd\n(he/she/it/they)';

  @override
  String get genderLabelM1 => 'Masc. Personal';

  @override
  String get genderLabelM2 => 'Masc. Animate';

  @override
  String get genderLabelM3 => 'Masc. Inanimate';

  @override
  String get genderLabelF => 'Feminine';

  @override
  String get genderLabelN1 => 'Neuter 1';

  @override
  String get genderLabelN2 => 'Neuter 2';

  @override
  String declensionTableTitle(String lemma) {
    return 'Declension for \"$lemma\"';
  }

  @override
  String conjugationTableTitle(String lemma) {
    return 'Conjugation for \"$lemma\"';
  }

  @override
  String get translationLabel => 'Translation';

  @override
  String suggestionDidYouMean(String word) {
    return 'Did you mean \'$word\'?';
  }

  @override
  String get suggestionErrorFallback => 'Could not fetch suggestion.';

  @override
  String get noRelevantAnalysisForNumeral => 'No relevant analysis for numeral found.';

  @override
  String get removeFromFavorites => 'Remove from favorites';

  @override
  String get addToFavorites => 'Add to favorites';

  @override
  String get impersonalAccuracyWarning => 'Impersonal forms may be less accurate';

  @override
  String get impersonalPresentForm => 'Impersonal present form';

  @override
  String get impersonalPastForm => 'Impersonal past form';

  @override
  String get impersonalFutureForm => 'Impersonal future form';

  @override
  String get impersonalConditionalForm => 'Impersonal conditional form';

  @override
  String get impersonalImperativeForm => 'Impersonal imperative form';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get genderLabelM => 'masculine';

  @override
  String get genderLabelN => 'neuter';

  @override
  String get genderLabelM1Pl => 'masc. pers.';

  @override
  String get genderLabelNonM1Pl => 'non-masc. pers.';

  @override
  String get copyrightsTitle => 'Copyrights';

  @override
  String get fontSizeSmall => 'Small';

  @override
  String get fontSizeMedium => 'Medium';

  @override
  String get fontSizeLarge => 'Large';

  @override
  String get copyrightNotice => 'This program was created using the morfeusz2 api.';

  @override
  String settingsFontSizeCurrentScale(String scaleValue) {
    return 'Current Scale: ${scaleValue}x';
  }

  @override
  String get qualifier_wok => 'clitic (vocalic)';

  @override
  String get qualifier_nwok => 'clitic (non-vocalic)';

  @override
  String get searchErrorFallback => 'Could not perform search.';

  @override
  String get clearTooltip => 'Clear search text';
}

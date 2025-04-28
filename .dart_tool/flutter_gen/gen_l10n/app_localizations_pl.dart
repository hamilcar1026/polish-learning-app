// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'Aplikacja do nauki polskiego';

  @override
  String get searchHint => 'Wpisz polskie słowo';

  @override
  String get settingsTitle => 'Ustawienia';

  @override
  String get languageSettingTitle => 'Język';

  @override
  String get fontSizeSettingTitle => 'Rozmiar czcionki';

  @override
  String get analysisTitle => 'Analiza';

  @override
  String get declensionTitle => 'Deklinacja';

  @override
  String get conjugationTitle => 'Koniugacja';

  @override
  String get grammarTitle => 'Gramatyka';

  @override
  String get pronounceWordTooltip => 'Wymów słowo';

  @override
  String get searchButtonTooltip => 'Szukaj';

  @override
  String noAnalysisFound(String word) {
    return 'Nie znaleziono analizy dla \"$word\".';
  }

  @override
  String get noDeclensionData => 'Nie znaleziono danych deklinacji.';

  @override
  String get noConjugationData => 'Nie znaleziono danych koniugacji.';

  @override
  String loadingError(Object error) {
    return 'Błąd ładowania: $error';
  }

  @override
  String get tag_subst => 'rzeczownik';

  @override
  String get tag_fin => 'czasownik (os.)';

  @override
  String get tag_adj => 'przymiotnik';

  @override
  String get tag_adv => 'przysłówek';

  @override
  String get tag_num => 'liczebnik';

  @override
  String get tag_ppron12 => 'zaimek (1/2 os.)';

  @override
  String get tag_ppron3 => 'zaimek (3 os.)';

  @override
  String get tag_siebie => 'zaimek (zwrot.)';

  @override
  String get tag_inf => 'bezokolicznik';

  @override
  String get tag_praet => 'czasownik (przesz.)';

  @override
  String get tag_impt => 'tryb rozkazujący';

  @override
  String get tag_pred => 'predykatyw';

  @override
  String get tag_prep => 'przyimek';

  @override
  String get tag_conj => 'spójnik';

  @override
  String get tag_comp => 'wskaźnik stopnia';

  @override
  String get tag_interj => 'wykrzyknik';

  @override
  String get tag_pact => 'imiesłów (czynn.)';

  @override
  String get tag_ppas => 'imiesłów (biern.)';

  @override
  String get tag_pcon => 'imiesłów (współ.)';

  @override
  String get tag_pant => 'imiesłów (uprz.)';

  @override
  String get tag_ger => 'rzeczownik odsł.';

  @override
  String get tag_bedzie => 'czasownik (przysz. aux)';

  @override
  String get tag_aglt => 'aglutynant';

  @override
  String get tag_qub => 'quasi-leksem';

  @override
  String get tag_depr => 'rzeczownik depr.';

  @override
  String get tag_adja => 'przym. czynny';

  @override
  String get tag_adjp => 'przym. bierny';

  @override
  String get tag_cond => 'tryb warunkowy';

  @override
  String get qualifier_sg => 'lp';

  @override
  String get qualifier_pl => 'lm';

  @override
  String get qualifier_nom => 'mian.';

  @override
  String get qualifier_gen => 'dop.';

  @override
  String get qualifier_dat => 'cel.';

  @override
  String get qualifier_acc => 'bier.';

  @override
  String get qualifier_inst => 'narz.';

  @override
  String get qualifier_loc => 'miejsc.';

  @override
  String get qualifier_voc => 'woł.';

  @override
  String get qualifier_m1 => 'm1';

  @override
  String get qualifier_m2 => 'm2';

  @override
  String get qualifier_m3 => 'm3';

  @override
  String get qualifier_f => 'ż';

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
  String get qualifier_pri => '1.';

  @override
  String get qualifier_sec => '2.';

  @override
  String get qualifier_ter => '3.';

  @override
  String get qualifier_imperf => 'ndk.';

  @override
  String get qualifier_perf => 'dk.';

  @override
  String get qualifier_nazwa_pospolita => 'posp.';

  @override
  String get qualifier_imie => 'imię';

  @override
  String get qualifier_nazwisko => 'nazwisko';

  @override
  String get qualifier_nazwa_geograficzna => 'geogr.';

  @override
  String get qualifier_skrot => 'skrót';

  @override
  String get qualifier_pos => 'st. równy';

  @override
  String get qualifier_com => 'st. wyższy';

  @override
  String get qualifier_sup => 'stopień najwyższy';

  @override
  String get qualifier_congr => 'kongruencja';

  @override
  String get qualifier_ncol => 'niezbiorowy';

  @override
  String get qualifier_rec => 'rządzący';

  @override
  String get conjugationCategoryPresentIndicative => 'Czas teraźniejszy';

  @override
  String get conjugationCategoryFuturePerfectiveIndicative => 'Czas przyszły dokonany';

  @override
  String get conjugationCategoryFutureImperfectiveIndicative => 'Czas przyszły niedokonany';

  @override
  String get conjugationCategoryPastTense => 'Czas przeszły';

  @override
  String get conjugationCategoryImperative => 'Tryb rozkazujący';

  @override
  String get conjugationCategoryInfinitive => 'Bezokolicznik';

  @override
  String get conjugationCategoryPresentAdverbialParticiple => 'Imiesłów przysłówkowy współczesny';

  @override
  String get conjugationCategoryAnteriorAdverbialParticiple => 'Imiesłów przysłówkowy uprzedni';

  @override
  String get conjugationCategoryPresentActiveParticiple => 'Imiesłów przymiotnikowy czynny';

  @override
  String get conjugationCategoryPastPassiveParticiple => 'Imiesłów przymiotnikowy bierny';

  @override
  String get conjugationCategoryFiniteVerb => 'Forma osobowa';

  @override
  String get conjugationCategoryOtherForms => 'Inne formy';

  @override
  String get conjugationCategoryImpersonal => 'Impersonal';

  @override
  String get conjugationCategoryVerbalNoun => 'Verbal Noun';

  @override
  String get conjugationCategoryConditional => 'Conditional';

  @override
  String get conjugationCategoryPresentImpersonal => 'Bezosobowa teraźniejsza';

  @override
  String get conjugationCategoryPastImpersonal => 'Bezosobowa przeszła';

  @override
  String get conjugationCategoryFutureImpersonal => 'Bezosobowa przyszła';

  @override
  String get conjugationCategoryConditionalImpersonal => 'Bezosobowa trybu warunkowego';

  @override
  String get conjugationCategoryImperativeImpersonal => 'Tryb rozkazujący nieosobowy';

  @override
  String get drawerRecentSearches => 'Ostatnie wyszukiwania';

  @override
  String get drawerClearRecentSearchesTooltip => 'Wyczyść ostatnie wyszukiwania';

  @override
  String get drawerClearRecentSearchesDialogTitle => 'Wyczyścić ostatnie wyszukiwania?';

  @override
  String get drawerClearDialogContent => 'Tej operacji nie można cofnąć.';

  @override
  String get drawerCancelButton => 'Anuluj';

  @override
  String get drawerClearButton => 'Wyczyść';

  @override
  String get drawerNoRecentSearches => 'Brak ostatnich wyszukiwań.';

  @override
  String get drawerFavorites => 'Ulubione';

  @override
  String get drawerNoFavorites => 'Nie dodano jeszcze ulubionych.';

  @override
  String get settingsThemeSystem => 'Domyślny systemowy';

  @override
  String get tableHeaderCase => 'Przypadek';

  @override
  String get tableHeaderSingular => 'Liczba pojedyncza';

  @override
  String get tableHeaderPlural => 'Liczba mnoga';

  @override
  String get tableHeaderM1 => 'Męskoos.';

  @override
  String get tableHeaderMOther => 'Inne męskie';

  @override
  String get tableHeaderF => 'Żeński';

  @override
  String get tableHeaderN => 'Nijaki';

  @override
  String get tableHeaderPerson => 'Osoba';

  @override
  String get caseNominative => 'Mianownik';

  @override
  String get caseGenitive => 'Dopełniacz';

  @override
  String get caseDative => 'Celownik';

  @override
  String get caseAccusative => 'Biernik';

  @override
  String get caseInstrumental => 'Narzędnik';

  @override
  String get caseLocative => 'Miejscownik';

  @override
  String get caseVocative => 'Wołacz';

  @override
  String get settingsContributors => 'Współtwórcy';

  @override
  String get personLabelFirst => '1. os. (ja/my)';

  @override
  String get personLabelSecond => '2. os. (ty/wy)';

  @override
  String get personLabelThird => '3. os. (on/ona/ono/oni/one)';

  @override
  String get genderLabelM1 => 'Męskoosobowy';

  @override
  String get genderLabelM2 => 'Męskożywotny';

  @override
  String get genderLabelM3 => 'Męskorzeczowy';

  @override
  String get genderLabelF => 'Żeński';

  @override
  String get genderLabelN1 => 'Nijaki 1';

  @override
  String get genderLabelN2 => 'Nijaki 2';

  @override
  String declensionTableTitle(String lemma) {
    return 'Deklinacja dla \"$lemma\"';
  }

  @override
  String conjugationTableTitle(String lemma) {
    return 'Koniugacja dla \"$lemma\"';
  }

  @override
  String get translationLabel => 'Tłumaczenie';

  @override
  String suggestionDidYouMean(String suggestedWord) {
    return 'Did you mean \"$suggestedWord\"?';
  }

  @override
  String get suggestionErrorFallback => 'Nie można załadować sugestii.';

  @override
  String get noRelevantAnalysisForNumeral => 'Nie znaleziono odpowiedniej analizy dla liczebnika.';

  @override
  String get removeFromFavorites => 'Usuń z ulubionych';

  @override
  String get addToFavorites => 'Dodaj do ulubionych';

  @override
  String get impersonalAccuracyWarning => 'Formy bezosobowe mogą być mniej dokładne';

  @override
  String get impersonalPresentForm => 'Impersonal present form (imperf)';

  @override
  String get impersonalPastForm => 'Impersonal past form (perf)';

  @override
  String get impersonalFutureForm => 'Impersonal future form';

  @override
  String get impersonalConditionalForm => 'Impersonal conditional form';

  @override
  String get settingsLanguage => 'Język';

  @override
  String get genderLabelM => 'męski';

  @override
  String get genderLabelN => 'nijaki';

  @override
  String get genderLabelM1Pl => 'męskoosob.';

  @override
  String get genderLabelNonM1Pl => 'niemęskoosob.';

  @override
  String get copyrightsTitle => 'Prawa autorskie';

  @override
  String get fontSizeSmall => 'Mały';

  @override
  String get fontSizeMedium => 'Średni';

  @override
  String get fontSizeLarge => 'Duży';

  @override
  String get copyrightNotice => 'Ten program został stworzony przy użyciu API morfeusz2.';
}

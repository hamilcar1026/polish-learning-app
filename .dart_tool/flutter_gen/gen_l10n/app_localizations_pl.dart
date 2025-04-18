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
  String get qualifier_sup => 'st. najwyższy';

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
}

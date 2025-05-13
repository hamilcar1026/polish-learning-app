// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get appTitle => 'Польський додаток для навчання';

  @override
  String get searchHint => 'Введіть слово для пошуку...';

  @override
  String get settingsTitle => 'Налаштування';

  @override
  String get languageSettingTitle => 'Мова';

  @override
  String get fontSizeSettingTitle => 'Розмір шрифту';

  @override
  String get analysisTitle => 'Аналіз';

  @override
  String get declensionTitle => 'Відмінювання';

  @override
  String get conjugationTitle => 'Дієвідміна';

  @override
  String get grammarTitle => 'Граматика';

  @override
  String get pronounceWordTooltip => 'Вимовити слово';

  @override
  String get searchButtonTooltip => 'Шукати слово';

  @override
  String noAnalysisFound(String word) {
    return 'Аналіз не знайдено для \"$word\"';
  }

  @override
  String get noDeclensionData => 'Дані про відмінювання не знайдено.';

  @override
  String get noConjugationData => 'Дані про дієвідміну не знайдено.';

  @override
  String loadingError(Object error) {
    return 'Помилка завантаження: $error';
  }

  @override
  String get tag_subst => 'іменник';

  @override
  String get tag_fin => 'дієслово (фінітне)';

  @override
  String get tag_adj => 'прикметник';

  @override
  String get tag_adv => 'прислівник';

  @override
  String get tag_num => 'числівник';

  @override
  String get tag_ppron12 => 'займенник (1/2 ос.)';

  @override
  String get tag_ppron3 => 'займенник (3 ос.)';

  @override
  String get tag_siebie => 'займенник (зворотний)';

  @override
  String get tag_inf => 'інфінітив';

  @override
  String get tag_praet => 'дієслово (мин. час)';

  @override
  String get tag_impt => 'наказовий спосіб';

  @override
  String get tag_pred => 'предикатив';

  @override
  String get tag_prep => 'прийменник';

  @override
  String get tag_conj => 'сполучник';

  @override
  String get tag_comp => 'компаративний маркер';

  @override
  String get tag_interj => 'вигук';

  @override
  String get tag_pact => 'дієприкметник (активний)';

  @override
  String get tag_ppas => 'дієприкметник (пасивний)';

  @override
  String get tag_pcon => 'дієприслівник (тепер. час)';

  @override
  String get tag_pant => 'дієприслівник (мин. час)';

  @override
  String get tag_ger => 'герундій';

  @override
  String get tag_bedzie => 'дієслово (майб. час, доп.)';

  @override
  String get tag_aglt => 'аглютинант';

  @override
  String get tag_qub => 'квазілексемна одиниця';

  @override
  String get tag_depr => 'іменник (зневажливий)';

  @override
  String get tag_adja => 'прикметник (дієприкм. акт.)';

  @override
  String get tag_adjp => 'прикметник (дієприкм. пас.)';

  @override
  String get tag_cond => 'умовний спосіб';

  @override
  String get qualifier_sg => 'одн.';

  @override
  String get qualifier_pl => 'мн.';

  @override
  String get qualifier_nom => 'наз.';

  @override
  String get qualifier_gen => 'род.';

  @override
  String get qualifier_dat => 'дав.';

  @override
  String get qualifier_acc => 'знах.';

  @override
  String get qualifier_inst => 'оруд.';

  @override
  String get qualifier_loc => 'місц.';

  @override
  String get qualifier_voc => 'клич.';

  @override
  String get qualifier_m1 => 'ч1';

  @override
  String get qualifier_m2 => 'ч2';

  @override
  String get qualifier_m3 => 'ч3';

  @override
  String get qualifier_f => 'ж';

  @override
  String get qualifier_n => 'с';

  @override
  String get qualifier_n1 => 'с1';

  @override
  String get qualifier_n2 => 'с2';

  @override
  String get qualifier_p1 => '1ос';

  @override
  String get qualifier_p2 => '2ос';

  @override
  String get qualifier_p3 => '3ос';

  @override
  String get qualifier_pri => '1-й';

  @override
  String get qualifier_sec => '2-й';

  @override
  String get qualifier_ter => '3-й';

  @override
  String get qualifier_imperf => 'недок.';

  @override
  String get qualifier_perf => 'док.';

  @override
  String get qualifier_nazwa_pospolita => 'загальна назва';

  @override
  String get qualifier_imie => 'ім\'я';

  @override
  String get qualifier_nazwisko => 'прізвище';

  @override
  String get qualifier_nazwa_geograficzna => 'геогр.';

  @override
  String get qualifier_skrot => 'скор.';

  @override
  String get qualifier_pos => 'ствердж.';

  @override
  String get qualifier_com => 'порівн.';

  @override
  String get qualifier_sup => 'найвищ.';

  @override
  String get qualifier_congr => 'узгодження';

  @override
  String get qualifier_ncol => 'незбірний';

  @override
  String get qualifier_rec => 'керуючий';

  @override
  String get conjugationCategoryPresentIndicative => 'Теперішній час, дійсний спосіб';

  @override
  String get conjugationCategoryFuturePerfectiveIndicative => 'Майбутній доконаний час, дійсний спосіб';

  @override
  String get conjugationCategoryFutureImperfectiveIndicative => 'Майбутній недоконаний час, дійсний спосіб';

  @override
  String get conjugationCategoryPastTense => 'Минулий час';

  @override
  String get conjugationCategoryImperative => 'Наказовий спосіб';

  @override
  String get conjugationCategoryInfinitive => 'Інфінітив';

  @override
  String get conjugationCategoryPresentAdverbialParticiple => 'Дієприслівник теперішнього часу';

  @override
  String get conjugationCategoryAnteriorAdverbialParticiple => 'Дієприслівник минулого часу (попередній)';

  @override
  String get conjugationCategoryPresentActiveParticiple => 'Активний дієприкметник теперішнього часу';

  @override
  String get conjugationCategoryPastPassiveParticiple => 'Пасивний дієприкметник минулого часу';

  @override
  String get conjugationCategoryFiniteVerb => 'Фінітне дієслово';

  @override
  String get conjugationCategoryOtherForms => 'Інші форми';

  @override
  String get conjugationCategoryImpersonal => 'Безособові форми';

  @override
  String get conjugationCategoryVerbalNoun => 'Віддієслівний іменник';

  @override
  String get conjugationCategoryConditional => 'Умовний спосіб';

  @override
  String get conjugationCategoryPresentImpersonal => 'Безособова форма теперішнього часу';

  @override
  String get conjugationCategoryPastImpersonal => 'Безособова форма минулого часу';

  @override
  String get conjugationCategoryFutureImpersonal => 'Безособова форма майбутнього часу';

  @override
  String get conjugationCategoryConditionalImpersonal => 'Безособова форма умовного способу';

  @override
  String get conjugationCategoryImperativeImpersonal => 'Безособовий наказовий спосіб';

  @override
  String get drawerRecentSearches => 'Останні пошуки';

  @override
  String get drawerClearRecentSearchesTooltip => 'Очистити останні пошуки';

  @override
  String get drawerClearRecentSearchesDialogTitle => 'Очистити останні пошуки?';

  @override
  String get drawerClearDialogContent => 'Цю дію неможливо скасувати.';

  @override
  String get drawerCancelButton => 'Скасувати';

  @override
  String get drawerClearButton => 'Очистити все';

  @override
  String get drawerNoRecentSearches => 'Немає останніх пошуків.';

  @override
  String get drawerFavorites => 'Обране';

  @override
  String get drawerNoFavorites => 'Ще не додано до обраного.';

  @override
  String get settingsThemeSystem => 'Системна тема за замовчуванням';

  @override
  String get tableHeaderCase => 'Відмінок';

  @override
  String get tableHeaderSingular => 'Однина';

  @override
  String get tableHeaderPlural => 'Множина';

  @override
  String get tableHeaderM1 => 'Чол. ос.';

  @override
  String get tableHeaderMOther => 'Чол. ін.';

  @override
  String get tableHeaderF => 'Жін. ос.';

  @override
  String get tableHeaderN => 'Сер. ос.';

  @override
  String get tableHeaderPerson => 'Особа';

  @override
  String get caseNominative => 'Називний';

  @override
  String get caseGenitive => 'Родовий';

  @override
  String get caseDative => 'Давальний';

  @override
  String get caseAccusative => 'Знахідний';

  @override
  String get caseInstrumental => 'Орудний';

  @override
  String get caseLocative => 'Місцевий';

  @override
  String get caseVocative => 'Кличний';

  @override
  String get settingsContributors => 'Автори';

  @override
  String get personLabelFirst => '1-а ос.\n(я/ми)';

  @override
  String get personLabelSecond => '2-а ос.\n(ти/ви)';

  @override
  String get personLabelThird => '3-я ос.\n(він/вона/воно/вони)';

  @override
  String get genderLabelM1 => 'Чоловічий особовий';

  @override
  String get genderLabelM2 => 'Чоловічий живий';

  @override
  String get genderLabelM3 => 'Чоловічий неживий';

  @override
  String get genderLabelF => 'Жіночий';

  @override
  String get genderLabelN1 => 'Середній 1';

  @override
  String get genderLabelN2 => 'Середній 2';

  @override
  String declensionTableTitle(String lemma) {
    return 'Відмінювання для \"$lemma\"';
  }

  @override
  String conjugationTableTitle(String lemma) {
    return 'Дієвідміна для \"$lemma\"';
  }

  @override
  String get translationLabel => 'Переклад';

  @override
  String suggestionDidYouMean(String word) {
    return 'Можливо, ви мали на увазі \'$word\'?';
  }

  @override
  String get suggestionErrorFallback => 'Не вдалося завантажити пропозицію.';

  @override
  String get noRelevantAnalysisForNumeral => 'Не знайдено відповідного аналізу для числівника.';

  @override
  String get removeFromFavorites => 'Видалити з обраного';

  @override
  String get addToFavorites => 'Додати до обраного';

  @override
  String get impersonalAccuracyWarning => 'Безособові форми можуть бути менш точними';

  @override
  String get impersonalPresentForm => 'Безособова форма теперішнього часу';

  @override
  String get impersonalPastForm => 'Безособова форма минулого часу';

  @override
  String get impersonalFutureForm => 'Безособова форма майбутнього часу';

  @override
  String get impersonalConditionalForm => 'Безособова умовна форма';

  @override
  String get impersonalImperativeForm => 'Безособова наказова форма';

  @override
  String get settingsLanguage => 'Мова';

  @override
  String get genderLabelM => 'чоловічий';

  @override
  String get genderLabelN => 'середній';

  @override
  String get genderLabelM1Pl => 'чол. ос. (мн.)';

  @override
  String get genderLabelNonM1Pl => 'не чол. ос. (мн.)';

  @override
  String get copyrightsTitle => 'Авторські права';

  @override
  String get fontSizeSmall => 'Малий';

  @override
  String get fontSizeMedium => 'Середній';

  @override
  String get fontSizeLarge => 'Великий';

  @override
  String get copyrightNotice => 'Ця програма створена з використанням morfeusz2 api.';

  @override
  String settingsFontSizeCurrentScale(String scaleValue) {
    return 'Поточний масштаб: ${scaleValue}x';
  }

  @override
  String get qualifier_wok => 'клітика (голосна)';

  @override
  String get qualifier_nwok => 'клітика (приголосна)';

  @override
  String get searchErrorFallback => 'Не вдалося виконати пошук.';

  @override
  String get clearTooltip => 'Очистити текст пошуку';
}

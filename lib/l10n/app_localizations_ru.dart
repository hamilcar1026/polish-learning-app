import 'app_localizations.dart';

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Приложение для изучения польского';

  @override
  String get searchHint => 'Введите польское слово';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get languageSettingTitle => 'Язык';

  @override
  String get fontSizeSettingTitle => 'Размер шрифта';

  @override
  String get analysisTitle => 'Анализ';

  @override
  String get declensionTitle => 'Склонение';

  @override
  String get conjugationTitle => 'Спряжение';

  @override
  String get grammarTitle => 'Грамматика';

  @override
  String get pronounceWordTooltip => 'Произнести слово';

  @override
  String get searchButtonTooltip => 'Поиск';

  @override
  String noAnalysisFound(String word) {
    return 'Анализ для \"$word\" не найден.';
  }

  @override
  String get noDeclensionData => 'Данные склонения не найдены.';

  @override
  String get noConjugationData => 'Данные спряжения не найдены.';

  @override
  String loadingError(Object error) {
    return 'Ошибка загрузки: $error';
  }

  @override
  String get tag_subst => 'существительное';

  @override
  String get tag_fin => 'глагол (fin)';

  @override
  String get tag_adj => 'прилагательное';

  @override
  String get tag_adv => 'наречие';

  @override
  String get tag_num => 'числительное';

  @override
  String get tag_ppron12 => 'местоимение (1/2 л.)';

  @override
  String get tag_ppron3 => 'местоимение (3 л.)';

  @override
  String get tag_siebie => 'местоимение (возвр.)';

  @override
  String get tag_inf => 'инфинитив';

  @override
  String get tag_praet => 'глагол (прош.)';

  @override
  String get tag_impt => 'повелительное накл.';

  @override
  String get tag_pred => 'предикатив';

  @override
  String get tag_prep => 'предлог';

  @override
  String get tag_conj => 'союз';

  @override
  String get tag_comp => 'маркер сравн. степени';

  @override
  String get tag_interj => 'междометие';

  @override
  String get tag_pact => 'причастие (действ.)';

  @override
  String get tag_ppas => 'причастие (страд.)';

  @override
  String get tag_pcon => 'деепричастие (наст.)';

  @override
  String get tag_pant => 'деепричастие (прош.)';

  @override
  String get tag_ger => 'герундий';

  @override
  String get tag_bedzie => 'глагол (буд. всп.)';

  @override
  String get tag_aglt => 'агглютинант';

  @override
  String get tag_qub => 'квазилексическая ед.';

  @override
  String get tag_depr => 'уничижительное сущ.';

  @override
  String get tag_adja => 'прил. причастие (действ.)';

  @override
  String get tag_adjp => 'прил. причастие (страд.)';

  @override
  String get tag_cond => 'условное наклонение';

  @override
  String get qualifier_sg => 'ед.';

  @override
  String get qualifier_pl => 'мн.';

  @override
  String get qualifier_nom => 'им.';

  @override
  String get qualifier_gen => 'род.';

  @override
  String get qualifier_dat => 'дат.';

  @override
  String get qualifier_acc => 'вин.';

  @override
  String get qualifier_inst => 'тв.';

  @override
  String get qualifier_loc => 'пр.';

  @override
  String get qualifier_voc => 'зв.';

  @override
  String get qualifier_m1 => 'м1';

  @override
  String get qualifier_m2 => 'м2';

  @override
  String get qualifier_m3 => 'м3';

  @override
  String get qualifier_f => 'ж';

  @override
  String get qualifier_n => 'с';

  @override
  String get qualifier_n1 => 'с1';

  @override
  String get qualifier_n2 => 'с2';

  @override
  String get qualifier_p1 => 'л1';

  @override
  String get qualifier_p2 => 'л2';

  @override
  String get qualifier_p3 => 'л3';

  @override
  String get qualifier_pri => '1л';

  @override
  String get qualifier_sec => '2л';

  @override
  String get qualifier_ter => '3л';

  @override
  String get qualifier_imperf => 'несов.';

  @override
  String get qualifier_perf => 'сов.';

  @override
  String get qualifier_nazwa_pospolita => 'нариц.';

  @override
  String get qualifier_imie => 'имя';

  @override
  String get qualifier_nazwisko => 'фамилия';

  @override
  String get qualifier_nazwa_geograficzna => 'геогр.';

  @override
  String get qualifier_skrot => 'сокр.';

  @override
  String get qualifier_pos => 'положит.';

  @override
  String get qualifier_com => 'сравн.';

  @override
  String get qualifier_sup => 'превосходная степень';

  @override
  String get qualifier_congr => 'согласование';

  @override
  String get qualifier_ncol => 'несобирательное';

  @override
  String get qualifier_rec => 'управляющий';

  @override
  String get conjugationCategoryPresentIndicative => 'Настоящее время (изъяв.)';

  @override
  String get conjugationCategoryFuturePerfectiveIndicative => 'Будущее время (соверш., изъяв.)';

  @override
  String get conjugationCategoryFutureImperfectiveIndicative => 'Будущее время (несоверш., изъяв.)';

  @override
  String get conjugationCategoryPastTense => 'Прошедшее время';

  @override
  String get conjugationCategoryImperative => 'Повелительное наклонение';

  @override
  String get conjugationCategoryInfinitive => 'Инфинитив';

  @override
  String get conjugationCategoryPresentAdverbialParticiple => 'Деепричастие настоящего времени';

  @override
  String get conjugationCategoryAnteriorAdverbialParticiple => 'Деепричастие прошедшего времени';

  @override
  String get conjugationCategoryPresentActiveParticiple => 'Действительное причастие настоящего времени';

  @override
  String get conjugationCategoryPastPassiveParticiple => 'Страдательное причастие прошедшего времени';

  @override
  String get conjugationCategoryFiniteVerb => 'Личный глагол';

  @override
  String get conjugationCategoryOtherForms => 'Другие формы';

  @override
  String get conjugationCategoryImpersonal => 'Impersonal';

  @override
  String get conjugationCategoryVerbalNoun => 'Verbal Noun';

  @override
  String get conjugationCategoryConditional => 'Conditional';

  @override
  String get conjugationCategoryPresentImpersonal => 'Настоящее безличное';

  @override
  String get conjugationCategoryPastImpersonal => 'Прошедшее безличное';

  @override
  String get conjugationCategoryFutureImpersonal => 'Будущее безличное';

  @override
  String get conjugationCategoryConditionalImpersonal => 'Условное безличное';

  @override
  String get conjugationCategoryImperativeImpersonal => 'Безличная форма повелительного наклонения';

  @override
  String get drawerRecentSearches => 'Недавние поиски';

  @override
  String get drawerClearRecentSearchesTooltip => 'Очистить недавние поиски';

  @override
  String get drawerClearRecentSearchesDialogTitle => 'Очистить недавние поиски?';

  @override
  String get drawerClearDialogContent => 'Это действие нельзя отменить.';

  @override
  String get drawerCancelButton => 'Отмена';

  @override
  String get drawerClearButton => 'Очистить';

  @override
  String get drawerNoRecentSearches => 'Нет недавних поисков.';

  @override
  String get drawerFavorites => 'Избранное';

  @override
  String get drawerNoFavorites => 'В избранное ничего не добавлено.';

  @override
  String get settingsThemeSystem => 'По умолчанию';

  @override
  String get tableHeaderCase => 'Падеж';

  @override
  String get tableHeaderSingular => 'Ед. ч.';

  @override
  String get tableHeaderPlural => 'Мн. ч.';

  @override
  String get tableHeaderM1 => 'Муж. лиц.';

  @override
  String get tableHeaderMOther => 'Муж. др.';

  @override
  String get tableHeaderF => 'Женский';

  @override
  String get tableHeaderN => 'Средний';

  @override
  String get tableHeaderPerson => 'Лицо';

  @override
  String get caseNominative => 'Именительный падеж';

  @override
  String get caseGenitive => 'Родительный';

  @override
  String get caseDative => 'Дательный';

  @override
  String get caseAccusative => 'Винительный';

  @override
  String get caseInstrumental => 'Творительный';

  @override
  String get caseLocative => 'Предложный';

  @override
  String get caseVocative => 'Звательный';

  @override
  String get settingsContributors => 'Участники';

  @override
  String get personLabelFirst => '1-е\\n(я/мы)';

  @override
  String get personLabelSecond => '2-е\\n(ты/вы)';

  @override
  String get personLabelThird => '3-е\\n(он/она/оно/они)';

  @override
  String get genderLabelM1 => 'Мужской личный';

  @override
  String get genderLabelM2 => 'Мужской одушевленный';

  @override
  String get genderLabelM3 => 'Мужской неодушевленный';

  @override
  String get genderLabelF => 'женский';

  @override
  String get genderLabelN1 => 'Средний 1';

  @override
  String get genderLabelN2 => 'Средний 2';

  @override
  String declensionTableTitle(String lemma) {
    return 'Склонение для \"$lemma\"';
  }

  @override
  String conjugationTableTitle(String lemma) {
    return 'Спряжение для \"$lemma\"';
  }

  @override
  String get translationLabel => 'Перевод';

  @override
  String suggestionDidYouMean(String word) {
    return 'Возможно, вы имели в виду \'$word\'?';
  }

  @override
  String get suggestionErrorFallback => 'Не удалось загрузить подсказку.';

  @override
  String get noRelevantAnalysisForNumeral => 'Не найдено подходящего анализа для числительного.';

  @override
  String get removeFromFavorites => 'Удалить из избранного';

  @override
  String get addToFavorites => 'Добавить в избранное';

  @override
  String get impersonalAccuracyWarning => 'Безличные формы могут быть менее точными';

  @override
  String get impersonalPresentForm => 'Безличная форма настоящего времени';

  @override
  String get impersonalPastForm => 'Безличная форма прошедшего времени';

  @override
  String get impersonalFutureForm => 'Безличная форма будущего времени';

  @override
  String get impersonalConditionalForm => 'Безличная форма условного наклонения';

  @override
  String get impersonalImperativeForm => 'Безличная форма повелительного наклонения';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get genderLabelM => 'мужской';

  @override
  String get genderLabelN => 'средний';

  @override
  String get genderLabelM1Pl => 'муж. лиц.';

  @override
  String get genderLabelNonM1Pl => 'не-муж. лиц.';

  @override
  String get copyrightsTitle => 'Авторские права';

  @override
  String get fontSizeSmall => 'Маленький';

  @override
  String get fontSizeMedium => 'Средний';

  @override
  String get fontSizeLarge => 'Большой';

  @override
  String get copyrightNotice => 'Эта программа была создана с использованием API morfeusz2.';

  @override
  String settingsFontSizeCurrentScale(String scaleValue) {
    return 'Текущий масштаб: ${scaleValue}x';
  }

  @override
  String get qualifier_wok => 'клитика (гласн.)';

  @override
  String get qualifier_nwok => 'клитика (согл.)';

  @override
  String get searchErrorFallback => 'Не удалось выполнить поиск.';

  @override
  String get clearTooltip => 'Очистить поле поиска';
}

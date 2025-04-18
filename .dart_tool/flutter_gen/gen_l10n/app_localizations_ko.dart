// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '폴란드어 학습 앱';

  @override
  String get searchHint => '폴란드어 단어를 입력하세요';

  @override
  String get settingsTitle => '설정';

  @override
  String get languageSettingTitle => '언어';

  @override
  String get fontSizeSettingTitle => '글꼴 크기';

  @override
  String get analysisTitle => '분석';

  @override
  String get declensionTitle => '곡용';

  @override
  String get conjugationTitle => '활용';

  @override
  String get grammarTitle => '문법';

  @override
  String get pronounceWordTooltip => '단어 발음 듣기';

  @override
  String get searchButtonTooltip => '검색';

  @override
  String noAnalysisFound(String word) {
    return '\"$word\"에 대한 분석을 찾을 수 없습니다.';
  }

  @override
  String get noDeclensionData => '곡용 데이터를 찾을 수 없습니다.';

  @override
  String get noConjugationData => '활용 데이터를 찾을 수 없습니다.';

  @override
  String loadingError(Object error) {
    return '로딩 오류: $error';
  }

  @override
  String get tag_subst => '명사';

  @override
  String get tag_fin => '동사 (정형)';

  @override
  String get tag_adj => '형용사';

  @override
  String get tag_adv => '부사';

  @override
  String get tag_num => '수사';

  @override
  String get tag_ppron12 => '대명사 (1/2인칭)';

  @override
  String get tag_ppron3 => '대명사 (3인칭)';

  @override
  String get tag_siebie => '대명사 (재귀)';

  @override
  String get tag_inf => '부정사';

  @override
  String get tag_praet => '동사 (과거)';

  @override
  String get tag_impt => '명령법';

  @override
  String get tag_pred => '술어사';

  @override
  String get tag_prep => '전치사';

  @override
  String get tag_conj => '접속사';

  @override
  String get tag_comp => '비교 표지';

  @override
  String get tag_interj => '감탄사';

  @override
  String get tag_pact => '분사 (능동)';

  @override
  String get tag_ppas => '분사 (수동)';

  @override
  String get tag_pcon => '분사 (현재 부사)';

  @override
  String get tag_pant => '분사 (선행 부사)';

  @override
  String get tag_ger => '동명사';

  @override
  String get tag_bedzie => '동사 (미래 조동사)';

  @override
  String get tag_aglt => '교착소';

  @override
  String get tag_qub => '준어휘 단위';

  @override
  String get tag_depr => '경멸 명사';

  @override
  String get tag_adja => '형용사적 분사 (능동)';

  @override
  String get tag_adjp => '형용사적 분사 (수동)';

  @override
  String get qualifier_sg => '단수';

  @override
  String get qualifier_pl => '복수';

  @override
  String get qualifier_nom => '주격';

  @override
  String get qualifier_gen => '생격';

  @override
  String get qualifier_dat => '여격';

  @override
  String get qualifier_acc => '대격';

  @override
  String get qualifier_inst => '조격';

  @override
  String get qualifier_loc => '처격';

  @override
  String get qualifier_voc => '호격';

  @override
  String get qualifier_m1 => '남성 인물';

  @override
  String get qualifier_m2 => '남성 동물';

  @override
  String get qualifier_m3 => '남성 사물';

  @override
  String get qualifier_f => '여성';

  @override
  String get qualifier_n => '중성';

  @override
  String get qualifier_n1 => '중성1';

  @override
  String get qualifier_n2 => '중성2';

  @override
  String get qualifier_p1 => '복수 남성 인물';

  @override
  String get qualifier_p2 => '복수 남성 비인물';

  @override
  String get qualifier_p3 => '복수 비남성';

  @override
  String get qualifier_pri => '1인칭';

  @override
  String get qualifier_sec => '2인칭';

  @override
  String get qualifier_ter => '3인칭';

  @override
  String get qualifier_imperf => '미완료';

  @override
  String get qualifier_perf => '완료';

  @override
  String get qualifier_nazwa_pospolita => '보통명사';

  @override
  String get qualifier_imie => '이름';

  @override
  String get qualifier_nazwisko => '성';

  @override
  String get qualifier_nazwa_geograficzna => '지명';

  @override
  String get qualifier_skrot => '약어';

  @override
  String get qualifier_pos => '원급';

  @override
  String get qualifier_com => '비교급';

  @override
  String get qualifier_sup => '최상급';

  @override
  String get conjugationCategoryPresentIndicative => '현재 시제 (직설법)';

  @override
  String get conjugationCategoryFuturePerfectiveIndicative => '미래 완료 시제 (직설법)';

  @override
  String get conjugationCategoryFutureImperfectiveIndicative => '미래 미완료 시제 (직설법)';

  @override
  String get conjugationCategoryPastTense => '과거 시제';

  @override
  String get conjugationCategoryImperative => '명령법';

  @override
  String get conjugationCategoryInfinitive => '부정사';

  @override
  String get conjugationCategoryPresentAdverbialParticiple => '현재 부사 분사';

  @override
  String get conjugationCategoryAnteriorAdverbialParticiple => '선행 부사 분사';

  @override
  String get conjugationCategoryPresentActiveParticiple => '현재 능동 분사';

  @override
  String get conjugationCategoryPastPassiveParticiple => '과거 수동 분사';

  @override
  String get conjugationCategoryFiniteVerb => '정형 동사';

  @override
  String get conjugationCategoryOtherForms => '기타 형태';

  @override
  String get drawerRecentSearches => '최근 검색어';

  @override
  String get drawerClearRecentSearchesTooltip => '최근 검색어 지우기';

  @override
  String get drawerClearRecentSearchesDialogTitle => '최근 검색어를 지우시겠습니까?';

  @override
  String get drawerClearDialogContent => '이 작업은 되돌릴 수 없습니다.';

  @override
  String get drawerCancelButton => '취소';

  @override
  String get drawerClearButton => '지우기';

  @override
  String get drawerNoRecentSearches => '최근 검색어가 없습니다.';

  @override
  String get drawerFavorites => '즐겨찾기';

  @override
  String get drawerNoFavorites => '즐겨찾기에 추가된 단어가 없습니다.';
}

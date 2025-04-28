import 'package:flutter/foundation.dart';
// import 'declension_form.dart'; // REMOVED: Class is defined below

// Note: This structure is very similar to ConjugationForm.
// Consider creating a shared 'WordForm' model if desired.
@immutable
class DeclensionForm {
  final String form;
  final String tag;
  final List<String> qualifiers;

  const DeclensionForm({
    required this.form,
    required this.tag,
    required this.qualifiers,
  });

  factory DeclensionForm.fromJson(Map<String, dynamic> json) {
    return DeclensionForm(
      form: json['form'] as String? ?? '',
      tag: json['tag'] as String? ?? '',
      qualifiers: (json['qualifiers'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
    );
  }

   @override
  String toString() {
    return 'DeclensionForm(form: $form, tag: $tag, qualifiers: $qualifiers)';
  }
}

// Note: This structure is very similar to ConjugationResult.
// Consider creating a shared 'GeneratedFormsResult' model if desired.
@immutable
class DeclensionResult {
  final String lemma;
  final Map<String, dynamic> grouped_forms;
  final bool is_detailed_numeral_table;

  const DeclensionResult({
    required this.lemma,
    required this.grouped_forms,
    required this.is_detailed_numeral_table,
  });

  factory DeclensionResult.fromJson(Map<String, dynamic> json) {
    print("[DeclensionResult.fromJson] Parsing JSON: $json");
    
    dynamic rawGroupedForms = json['grouped_forms'];
    Map<String, dynamic> parsedGroupedForms;

    bool isDetailed = json['is_detailed_numeral_table'] ?? false;
    print("[DeclensionResult.fromJson] is_detailed_numeral_table: $isDetailed");

    if (isDetailed) {
      if (rawGroupedForms is Map<String, dynamic>) {
         try {
             parsedGroupedForms = rawGroupedForms.map(
                 (caseKey, genderMap) => MapEntry(
                     caseKey,
                     Map<String, String>.from(genderMap as Map)
                 )
             );
              print("[DeclensionResult.fromJson] Parsed detailed numeral table forms: $parsedGroupedForms");
         } catch (e) {
             print("[DeclensionResult.fromJson] Error parsing detailed numeral table forms: $e. Falling back to empty map.");
             parsedGroupedForms = {};
         }
      } else {
          print("[DeclensionResult.fromJson] Unexpected format for detailed numeral table forms. Expected Map<String, dynamic>, got ${rawGroupedForms.runtimeType}. Falling back to empty map.");
          parsedGroupedForms = {};
      }
    } else {
      if (rawGroupedForms is Map<String, dynamic>) {
        parsedGroupedForms = rawGroupedForms.map(
          (category, formsJson) => MapEntry(
            category,
            formsJson is List
                ? formsJson.map((formJson) => DeclensionForm.fromJson(formJson as Map<String, dynamic>)).toList()
                : <DeclensionForm>[],
          ),
        );
         print("[DeclensionResult.fromJson] Parsed standard forms: Keys=${parsedGroupedForms.keys}");
      } else {
         print("[DeclensionResult.fromJson] Unexpected format for standard forms. Expected Map<String, dynamic>, got ${rawGroupedForms.runtimeType}. Falling back to empty map.");
         parsedGroupedForms = {};
      }
    }

    return DeclensionResult(
      lemma: json['lemma'] as String,
      grouped_forms: parsedGroupedForms,
      is_detailed_numeral_table: isDetailed,
    );
  }

  @override
  String toString() {
    return 'DeclensionResult(lemma: $lemma, grouped_forms: ${grouped_forms.keys.length} categories)';
  }
}

// Optional: Model for the overall API response
/*
@immutable
class DeclensionApiResponse {
  final String status;
  final String word;
  final List<DeclensionResult> data;
  final String? message;

  const DeclensionApiResponse({
    required this.status,
    required this.word,
    required this.data,
    this.message,
  });

  factory DeclensionApiResponse.fromJson(Map<String, dynamic> json) {
    return DeclensionApiResponse(
      status: json['status'] as String? ?? 'error',
      word: json['word'] as String? ?? '',
      data: (json['data'] as List<dynamic>? ?? [])
          .map((item) => DeclensionResult.fromJson(item as Map<String, dynamic>))
          .toList(),
      message: json['message'] as String?,
    );
  }
}
*/ 
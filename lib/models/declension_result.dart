import 'package:flutter/foundation.dart';

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
  final Map<String, List<DeclensionForm>> grouped_forms;

  const DeclensionResult({
    required this.lemma,
    required this.grouped_forms,
  });

  factory DeclensionResult.fromJson(Map<String, dynamic> json) {
    final Map<String, List<DeclensionForm>> parsedGroupedForms = {};
    final Map<String, dynamic> rawGroupedForms = json['grouped_forms'] as Map<String, dynamic>? ?? {};

    rawGroupedForms.forEach((categoryKey, formList) {
      if (formList is List) {
        parsedGroupedForms[categoryKey] = formList
            .map((item) => DeclensionForm.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    });

    return DeclensionResult(
      lemma: json['lemma'] as String? ?? '',
      grouped_forms: parsedGroupedForms,
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
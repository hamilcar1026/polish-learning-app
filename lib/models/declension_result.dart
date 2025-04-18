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
  final List<DeclensionForm> forms;

  const DeclensionResult({
    required this.lemma,
    required this.forms,
  });

  factory DeclensionResult.fromJson(Map<String, dynamic> json) {
    return DeclensionResult(
      lemma: json['lemma'] as String? ?? '',
      forms: (json['forms'] as List<dynamic>? ?? [])
          .map((item) => DeclensionForm.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  String toString() {
    return 'DeclensionResult(lemma: $lemma, forms: ${forms.length} forms)';
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
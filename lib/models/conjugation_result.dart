import 'package:flutter/foundation.dart';

@immutable
class ConjugationForm {
  final String form;
  final String tag;
  final List<String> qualifiers;

  const ConjugationForm({
    required this.form,
    required this.tag,
    required this.qualifiers,
  });

  factory ConjugationForm.fromJson(Map<String, dynamic> json) {
    return ConjugationForm(
      form: json['form'] as String? ?? '',
      tag: json['tag'] as String? ?? '',
      qualifiers: (json['qualifiers'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
    );
  }

  @override
  String toString() {
    return 'ConjugationForm(form: $form, tag: $tag, qualifiers: $qualifiers)';
  }
}

@immutable
class ConjugationResult {
  final String lemma;
  final List<ConjugationForm> forms;

  const ConjugationResult({
    required this.lemma,
    required this.forms,
  });

  factory ConjugationResult.fromJson(Map<String, dynamic> json) {
    return ConjugationResult(
      lemma: json['lemma'] as String? ?? '',
      forms: (json['forms'] as List<dynamic>? ?? [])
          .map((item) => ConjugationForm.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

   @override
  String toString() {
    return 'ConjugationResult(lemma: $lemma, forms: ${forms.length} forms)';
  }
}

// Optional: Model for the overall API response
/*
@immutable
class ConjugationApiResponse {
  final String status;
  final String word;
  final List<ConjugationResult> data;
  final String? message;

  const ConjugationApiResponse({
    required this.status,
    required this.word,
    required this.data,
    this.message,
  });

  factory ConjugationApiResponse.fromJson(Map<String, dynamic> json) {
    return ConjugationApiResponse(
      status: json['status'] as String? ?? 'error',
      word: json['word'] as String? ?? '',
      data: (json['data'] as List<dynamic>? ?? [])
          .map((item) => ConjugationResult.fromJson(item as Map<String, dynamic>))
          .toList(),
      message: json['message'] as String?,
    );
  }
}
*/ 
import 'package:flutter/foundation.dart';

@immutable
class AnalysisResult {
  final String lemma;
  final String tag;
  final List<String> qualifiers;

  const AnalysisResult({
    required this.lemma,
    required this.tag,
    required this.qualifiers,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    // Defensive parsing: Check types before casting
    final String parsedLemma = json['lemma'] is String ? json['lemma'] : '';
    final String parsedTag = json['tag'] is String ? json['tag'] : '';
    final List<String> parsedQualifiers;

    if (json['qualifiers'] is List) {
      parsedQualifiers = (json['qualifiers'] as List)
          .map((e) => e.toString()) // Convert each element to string
          .toList();
    } else {
      parsedQualifiers = []; // Default to empty list if not a list
    }

    // Debug print to see what's being parsed
    // print('Parsing AnalysisResult: lemma=$parsedLemma, tag=$parsedTag, qualifiers=$parsedQualifiers');

    return AnalysisResult(
      lemma: parsedLemma,
      tag: parsedTag,
      qualifiers: parsedQualifiers,
    );
  }

  // Optional: Add methods like toString for debugging
  @override
  String toString() {
    return 'AnalysisResult(lemma: $lemma, tag: $tag, qualifiers: $qualifiers)';
  }
}

// Optional: Model for the overall API response if needed elsewhere,
// but ApiService currently returns Map<String, dynamic> directly.
/*
@immutable
class AnalysisApiResponse {
  final String status;
  final String word;
  final List<AnalysisResult> data;
  final String? message; // For errors or info messages

  const AnalysisApiResponse({
    required this.status,
    required this.word,
    required this.data,
    this.message,
  });

  factory AnalysisApiResponse.fromJson(Map<String, dynamic> json) {
    return AnalysisApiResponse(
      status: json['status'] as String? ?? 'error',
      word: json['word'] as String? ?? '',
      data: (json['data'] as List<dynamic>? ?? [])
          .map((item) => AnalysisResult.fromJson(item as Map<String, dynamic>))
          .toList(),
      message: json['message'] as String?,
    );
  }
}
*/ 
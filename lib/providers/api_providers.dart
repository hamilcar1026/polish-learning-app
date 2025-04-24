import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import '../services/api_service.dart';
import '../models/analysis_result.dart';
import '../models/conjugation_result.dart';
import '../models/declension_result.dart';

// Provider for the ApiService instance
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// Define a class to hold parameters for analysisProvider family
// This makes it easier to pass multiple arguments
@immutable
class AnalysisParams {
  final String word;
  final String targetLang;

  const AnalysisParams({required this.word, required this.targetLang});

  // Override == and hashCode for correct provider behavior
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalysisParams &&
          runtimeType == other.runtimeType &&
          word == other.word &&
          targetLang == other.targetLang;

  @override
  int get hashCode => word.hashCode ^ targetLang.hashCode;
}

// FutureProvider family for fetching analysis results
// Takes AnalysisParams (word and targetLang) as a parameter
final analysisProvider = FutureProvider.family<ApiResponse<List<AnalysisResult>>, AnalysisParams>((ref, params) async {
  // Watch the apiServiceProvider to get the ApiService instance
  final apiService = ref.watch(apiServiceProvider);
  // Call the fetchAnalysis method with both word and target language
  return await apiService.fetchAnalysis(params.word, params.targetLang);
});

// FutureProvider family for fetching conjugation results
final conjugationProvider = FutureProvider.family<ApiResponse<List<ConjugationResult>>, String>((ref, word) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.fetchConjugations(word);
});

// FutureProvider family for fetching declension results
final declensionProvider = FutureProvider.family<ApiResponse<List<DeclensionResult>>, String>((ref, word) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.fetchDeclensions(word);
}); 
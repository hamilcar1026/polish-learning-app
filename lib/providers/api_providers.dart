import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/analysis_result.dart';
import '../models/conjugation_result.dart';
import '../models/declension_result.dart';

// Provider for the ApiService instance
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// FutureProvider family for fetching analysis results
// Takes a String (word) as a parameter
final analysisProvider = FutureProvider.family<ApiResponse<List<AnalysisResult>>, String>((ref, word) async {
  // Watch the apiServiceProvider to get the ApiService instance
  final apiService = ref.watch(apiServiceProvider);
  // Call the fetchAnalysis method
  return await apiService.fetchAnalysis(word);
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
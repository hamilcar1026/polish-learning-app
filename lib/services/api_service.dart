import 'dart:convert';
import 'dart:io'; // Import dart:io for Platform checks
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:http/http.dart' as http;
import '../models/analysis_result.dart';
import '../models/conjugation_result.dart';
import '../models/declension_result.dart';

/// A simple wrapper for API responses that includes status and optional message.
/// This helps differentiate between successful data and API-level errors/messages.
class ApiResponse<T> {
  final String status;
  final T? data; // Make data nullable
  final String? message;
  final String? translation_en; // Add translation field
  final String? suggested_word; // Field for suggestion status
  final String? original_word; // Field for suggestion status
  final bool? is_numeral_input; // Field to indicate if the input was a numeral

  ApiResponse({
    required this.status,
    this.data,
    this.message,
    this.translation_en,
    this.suggested_word, // Add to constructor
    this.original_word, // Add to constructor
    this.is_numeral_input // Add to constructor
  });
}

class ApiService {
  
  // --- Updated Base URL Logic ---
  static String getBaseUrl() {
    // Check for environment variable first
    const backendUrl = String.fromEnvironment('BACKEND_URL', defaultValue: '');
    if (backendUrl.isNotEmpty) {
      return backendUrl;
    }

    // Fallback to hardcoded URLs depending on the platform or a global default
    if (kIsWeb) {
      // For web, it might be a relative path or a specific URL for web deployment
      // return 'http://localhost:8080'; // Example for local web development
      return 'https://polish-learning-app.onrender.com';
    } else if (Platform.isAndroid) {
      // For Android emulator, 10.0.2.2 typically refers to the host machine
      // return 'http://10.0.2.2:8080';
      return 'https://polish-learning-app.onrender.com';
    } else if (Platform.isIOS || Platform.isMacOS) {
      // For iOS simulator and macOS, localhost or 127.0.0.1 should work for local server
      // return 'http://localhost:8080';
      return 'https://polish-learning-app.onrender.com';
    }
    // Default fallback if no other condition met (should ideally not be reached if covered above)
    // return 'http://192.168.0.8:8080'; // Or try localhost as a fallback
    return 'https://polish-learning-app.onrender.com';
  }

  static final String _baseUrl = getBaseUrl();
  // -------------------------------

  /// Fetches analysis results for a given word.
  Future<ApiResponse<List<AnalysisResult>>> fetchAnalysis(String word, String targetLang) async {
    final encodedWord = Uri.encodeComponent(word);
    final Uri url = Uri.parse('$_baseUrl/analyze/$encodedWord?target_lang=$targetLang');
    print("[fetchAnalysis] Attempting to send GET request to: $url");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(utf8.decode(response.bodyBytes));
        final String status = decodedJson['status'] as String? ?? 'error';
        final String? message = decodedJson['message'] as String?;
        final String? translationEn = decodedJson['translation_en'] as String?;
        final String? suggestedWord = decodedJson['suggested_word'] as String?;
        final String? originalWord = decodedJson['original_word'] as String?;
        final bool? isNumeralInput = decodedJson['is_numeral_input'] as bool?;

        if (status == 'success') {
          final List<dynamic> dataList = decodedJson['data'] as List<dynamic>? ?? [];
          final List<AnalysisResult> parsedData = dataList
              .map((item) => AnalysisResult.fromJson(item as Map<String, dynamic>))
              .toList();
          return ApiResponse(
              status: status,
              data: parsedData,
              message: message,
              translation_en: translationEn,
              is_numeral_input: isNumeralInput
          );
        } else if (status == 'suggestion') {
             // Return suggestion response
             return ApiResponse(
               status: status, 
               message: message, 
               suggested_word: suggestedWord,
               original_word: originalWord
             );
        } else { // Handle other statuses like 'error' or unexpected ones
          return ApiResponse(status: status, message: message);
        }
      } else {
        print('HTTP Error: ${response.statusCode} for endpoint analyze/$encodedWord?target_lang=$targetLang');
        throw HttpException('Failed to load analysis: ${response.statusCode}');
      }
    } on SocketException {
      print('Network Error: Failed to connect to $_baseUrl/analyze/$encodedWord?target_lang=$targetLang');
      throw const SocketException('Could not connect to the server. Please check your network connection.');
    } on HttpException catch (e) {
      throw HttpException('An HTTP error occurred during analysis: ${e.message}');
    } catch (e) {
      print('Unknown Error fetching analysis for $word (lang: $targetLang): $e');
      throw Exception('An unknown error occurred during analysis: $e');
    }
  }

  /// Fetches conjugation forms for a given verb.
  Future<ApiResponse<List<ConjugationResult>>> fetchConjugations(String word) async {
    final encodedWord = Uri.encodeComponent(word);
    final Uri url = Uri.parse('$_baseUrl/conjugate/$encodedWord');
     print("[fetchConjugations] Attempting to send GET request to: $url");
     try {
       final response = await http.get(url);
       if (response.statusCode == 200) {
         final Map<String, dynamic> decodedJson = json.decode(utf8.decode(response.bodyBytes));
         final String status = decodedJson['status'] as String? ?? 'error';
         final String? message = decodedJson['message'] as String?;
         if (status == 'success') {
           final List<dynamic> dataList = decodedJson['data'] as List<dynamic>? ?? [];
           final List<ConjugationResult> parsedData = dataList
               .map((item) => ConjugationResult.fromJson(item as Map<String, dynamic>))
               .toList();
           return ApiResponse(status: status, data: parsedData, message: message);
         } else {
           return ApiResponse(status: status, message: message);
         }
       } else {
          print('HTTP Error: ${response.statusCode} for endpoint conjugate/$encodedWord');
          throw HttpException('Failed to load conjugations: ${response.statusCode}');
       }
     } on SocketException { // Add specific error handling for consistency
        print('Network Error: Failed to connect to $_baseUrl/conjugate/$encodedWord');
        throw const SocketException('Could not connect to the server. Please check your network connection.');
     } on HttpException catch (e) {
        throw HttpException('An HTTP error occurred during conjugation: ${e.message}');
     } catch (e) {
       print('Unknown Error fetching conjugations for $word: $e');
       throw Exception('An unknown error occurred during conjugation: $e');
     }
  }

  /// Fetches declension forms for a given noun/adjective.
  Future<ApiResponse<List<DeclensionResult>>> fetchDeclensions(String word) async {
    final encodedWord = Uri.encodeComponent(word);
    final Uri url = Uri.parse('$_baseUrl/decline/$encodedWord');
    print("[fetchDeclensions] Attempting to send GET request to: $url");
    try {
       final response = await http.get(url);
       if (response.statusCode == 200) {
         final Map<String, dynamic> decodedJson = json.decode(utf8.decode(response.bodyBytes));
         final String status = decodedJson['status'] as String? ?? 'error';
         final String? message = decodedJson['message'] as String?;
         if (status == 'success') {
           final List<dynamic> dataList = decodedJson['data'] as List<dynamic>? ?? [];
           final List<DeclensionResult> parsedData = dataList
               .map((item) => DeclensionResult.fromJson(item as Map<String, dynamic>))
               .toList();
           return ApiResponse(status: status, data: parsedData, message: message);
         } else {
           return ApiResponse(status: status, message: message);
         }
       } else {
          print('HTTP Error: ${response.statusCode} for endpoint decline/$encodedWord');
          throw HttpException('Failed to load declensions: ${response.statusCode}');
       }
     } on SocketException { // Add specific error handling for consistency
        print('Network Error: Failed to connect to $_baseUrl/decline/$encodedWord');
        throw const SocketException('Could not connect to the server. Please check your network connection.');
     } on HttpException catch (e) {
        throw HttpException('An HTTP error occurred during declension: ${e.message}');
     } catch (e) {
       print('Unknown Error fetching declensions for $word: $e');
       throw Exception('An unknown error occurred during declension: $e');
     }
  }
} 
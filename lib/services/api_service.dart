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
    // 1. --dart-define으로 전달된 BACKEND_URL 값을 먼저 확인
    const backendUrlFromEnv = String.fromEnvironment('BACKEND_URL');

    // 2. 전달된 값이 있다면 그 값을 사용
    if (backendUrlFromEnv.isNotEmpty) {
      // Ensure the URL doesn't end with a slash
      return backendUrlFromEnv.endsWith('/') 
             ? backendUrlFromEnv.substring(0, backendUrlFromEnv.length - 1) 
             : backendUrlFromEnv;
    }

    // 3. 전달된 값이 없다면 (예: 로컬 개발 환경) 기존 로직 사용
    print("Warning: BACKEND_URL environment variable not set. Falling back to default URLs."); // 로그 추가
    if (kIsWeb) {
      return 'http://localhost:8080';
    } else if (Platform.isAndroid) {
      // Use 10.0.2.2 for Android emulators
      return 'http://10.0.2.2:8080';
    } else if (Platform.isIOS) {
      // Use localhost for iOS simulators
      return 'http://localhost:8080';
    } else {
      // Default for other platforms (like desktop) or physical devices 
      // Might need adjustment based on actual network setup for physical devices
      // Consider making this 'http://localhost:8080' as a more universal fallback?
      return 'http://192.168.0.8:8080'; // Or try localhost as a fallback 
    }
  }

  static final String _baseUrl = getBaseUrl();
  // -------------------------------

  // Updated helper function to parse into a generic ApiResponse
  Future<ApiResponse<List<R>>> _getRequest<R>(
      String endpoint,
      R Function(Map<String, dynamic>) fromJsonParser
  ) async {
    final Uri url = Uri.parse('$_baseUrl/$endpoint');
    print("[_getRequest] Attempting to send GET request to: $url");
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(utf8.decode(response.bodyBytes));
        final String status = decodedJson['status'] as String? ?? 'error';
        final String? message = decodedJson['message'] as String?;

        if (status == 'success') {
          // Parse the 'data' list using the provided parser
          final List<dynamic> dataList = decodedJson['data'] as List<dynamic>? ?? [];
          final List<R> parsedData = dataList
              .map((item) => fromJsonParser(item as Map<String, dynamic>))
              .toList();
          return ApiResponse(status: status, data: parsedData, message: message);
        } else {
          // Return API-level error/message without data
          return ApiResponse(status: status, message: message);
        }
      } else {
        // Handle HTTP errors (e.g., 404, 500)
        print('HTTP Error: ${response.statusCode} for endpoint $endpoint');
        throw HttpException('Failed to load data: ${response.statusCode}');
      }
    } on SocketException {
      print('Network Error: Failed to connect to $_baseUrl/$endpoint');
      throw const SocketException('Could not connect to the server. Please check your network connection.');
    } on HttpException catch (e) {
      throw HttpException('An HTTP error occurred: ${e.message}');
    } catch (e) {
      print('Unknown Error fetching $endpoint: $e');
      throw Exception('An unknown error occurred: $e');
    }
  }

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
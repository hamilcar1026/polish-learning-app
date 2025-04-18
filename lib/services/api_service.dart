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

  ApiResponse({required this.status, this.data, this.message});
}

class ApiService {
  
  // --- Updated Base URL Logic ---
  static String getBaseUrl() {
    if (kIsWeb) {
      // Use the deployed Cloud Run URL for web
      return 'https://polish-learning-backend-service-529152975346.asia-northeast3.run.app'; 
    } else if (Platform.isAndroid) {
      // Use 10.0.2.2 for Android emulators
      return 'http://10.0.2.2:8080';
    } else if (Platform.isIOS) {
      // Use localhost for iOS simulators
      return 'http://localhost:8080';
    } else {
      // Default for other platforms (like desktop) or physical devices 
      // Might need adjustment based on actual network setup for physical devices
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
  Future<ApiResponse<List<AnalysisResult>>> fetchAnalysis(String word) async {
    final encodedWord = Uri.encodeComponent(word);
    // Pass the fromJson factory of AnalysisResult
    return await _getRequest('analyze/$encodedWord', AnalysisResult.fromJson);
  }

  /// Fetches conjugation forms for a given verb.
  Future<ApiResponse<List<ConjugationResult>>> fetchConjugations(String word) async {
    final encodedWord = Uri.encodeComponent(word);
    // Pass the fromJson factory of ConjugationResult
    return await _getRequest('conjugate/$encodedWord', ConjugationResult.fromJson);
  }

  /// Fetches declension forms for a given noun/adjective.
  Future<ApiResponse<List<DeclensionResult>>> fetchDeclensions(String word) async {
    final encodedWord = Uri.encodeComponent(word);
    // Pass the fromJson factory of DeclensionResult
    return await _getRequest('decline/$encodedWord', DeclensionResult.fromJson);
  }
} 
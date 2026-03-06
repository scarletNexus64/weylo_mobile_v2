import 'dart:io';
import 'package:dio/dio.dart';
import 'api_config.dart';
import '../services/storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final Dio _dio;
  final _storage = StorageService();

  /// Initialize Dio with configuration
  void init() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        sendTimeout: ApiConfig.sendTimeout,
        headers: {
          // Don't set Content-Type here - it will be set in the interceptor
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add authorization header if token exists
          final authHeader = _storage.getAuthHeader();
          if (authHeader != null) {
            options.headers['Authorization'] = authHeader;
          }

          // Set Content-Type only for non-FormData requests
          // For FormData, Dio will automatically set multipart/form-data with boundary
          if (options.data is! FormData) {
            options.headers['Content-Type'] = 'application/json';
          }

          // Log request for debugging
          print('🚀 REQUEST[${options.method}] => ${options.path}');
          print('📦 Data: ${options.data}');
          print('🔑 Headers: ${options.headers}');

          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Log response for debugging
          print('✅ RESPONSE[${response.statusCode}] => ${response.requestOptions.path}');

          // Check if response is JSON
          if (response.data is String && (response.data as String).startsWith('<')) {
            print('⚠️ Response is HTML instead of JSON:');
            print((response.data as String).substring(0, (response.data as String).length > 500 ? 500 : (response.data as String).length));
          } else {
            print('📥 Data: ${response.data}');
          }

          return handler.next(response);
        },
        onError: (error, handler) {
          // Log error for debugging
          print('❌ ERROR[${error.response?.statusCode}] => ${error.requestOptions.path}');
          print('💥 Message: ${error.message}');

          // Check if response data is HTML
          if (error.response?.data is String) {
            final responseData = error.response!.data as String;
            if (responseData.startsWith('<')) {
              print('⚠️ Response is HTML instead of JSON (probably a server error):');
              print(responseData.substring(0, responseData.length > 500 ? 500 : responseData.length));
            } else {
              print('📛 Response: ${error.response?.data}');
            }
          } else {
            print('📛 Response: ${error.response?.data}');
          }

          return handler.next(error);
        },
      ),
    );
  }

  /// GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PATCH request
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Upload file (multipart/form-data)
  Future<Response> uploadFile(
    String path, {
    required FormData formData,
    ProgressCallback? onSendProgress,
    Options? options,
  }) async {
    try {
      // The interceptor will detect FormData and NOT set Content-Type,
      // allowing Dio to automatically set multipart/form-data with boundary
      final response = await _dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle Dio errors and convert to app-specific exceptions
  ApiException _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Délai d\'attente dépassé. Veuillez réessayer.',
          statusCode: 408,
        );

      case DioExceptionType.badResponse:
        final response = error.response;
        if (response != null) {
          final data = response.data;
          String message = 'Une erreur est survenue';

          if (data is Map<String, dynamic>) {
            message = data['message'] ?? message;

            // Handle validation errors
            if (data['errors'] != null) {
              final errors = data['errors'] as Map<String, dynamic>;
              final firstError = errors.values.first;
              if (firstError is List && firstError.isNotEmpty) {
                message = firstError.first.toString();
              }
            }
          }

          return ApiException(
            message: message,
            statusCode: response.statusCode,
            data: data,
          );
        }
        return ApiException(
          message: 'Erreur de réponse du serveur',
          statusCode: error.response?.statusCode,
        );

      case DioExceptionType.cancel:
        return ApiException(
          message: 'Requête annulée',
          statusCode: 0,
        );

      case DioExceptionType.unknown:
        // Log detailed error for debugging
        print('🔍 DioException.unknown details:');
        print('   Error type: ${error.type}');
        print('   Error message: ${error.message}');
        print('   Error: ${error.error}');

        if (error.message?.contains('SocketException') ?? false) {
          return ApiException(
            message: 'Pas de connexion Internet',
            statusCode: 0,
          );
        }

        // Check if it's a file-related error
        if (error.error is FileSystemException) {
          final fileError = error.error as FileSystemException;
          return ApiException(
            message: 'Erreur fichier: ${fileError.message} - ${fileError.path}',
            statusCode: 0,
          );
        }

        // Check for other IO errors
        if (error.error is IOException) {
          return ApiException(
            message: 'Erreur d\'entrée/sortie: ${error.error}',
            statusCode: 0,
          );
        }

        // Provide more context about unknown errors
        final errorMessage = error.error?.toString() ?? error.message ?? 'Une erreur inattendue est survenue';
        return ApiException(
          message: errorMessage,
          statusCode: 0,
        );

      default:
        return ApiException(
          message: error.message ?? 'Une erreur est survenue',
          statusCode: 0,
        );
    }
  }

  /// Get Dio instance for advanced usage
  Dio get dio => _dio;
}

/// Custom API exception class
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => message;
}

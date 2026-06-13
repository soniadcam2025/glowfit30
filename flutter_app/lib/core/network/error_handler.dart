import 'package:dio/dio.dart';
import '../constants/app_strings.dart';

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  ApiException({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => message;
}

/// Error handler for API responses
class ErrorHandler {
  ErrorHandler._();

  /// Handle DioException and return ApiException
  static ApiException handleDioException(DioException error) {
    int? statusCode;
    String message;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        statusCode = -1;
        message = AppStrings.networkError;
        break;

      case DioExceptionType.sendTimeout:
        statusCode = -2;
        message = 'Request timeout. Please try again.';
        break;

      case DioExceptionType.receiveTimeout:
        statusCode = -3;
        message = 'Response timeout. Please try again.';
        break;

      case DioExceptionType.badResponse:
        statusCode = error.response?.statusCode;
        message = _getMessageFromStatusCode(statusCode);

        // Try to extract error message from response
        if (error.response?.data != null) {
          final responseData = error.response!.data;
          if (responseData is Map<String, dynamic>) {
            if (responseData.containsKey('message')) {
              message = responseData['message'] ?? message;
            }
            if (responseData.containsKey('error')) {
              message = responseData['error'] ?? message;
            }
          }
        }
        break;

      case DioExceptionType.cancel:
        statusCode = -4;
        message = 'Request cancelled';
        break;

      case DioExceptionType.unknown:
        statusCode = -5;
        message = AppStrings.unknownError;
        break;

      case DioExceptionType.badCertificate:
        statusCode = -6;
        message = 'SSL certificate error';
        break;

      case DioExceptionType.connectionError:
        statusCode = -7;
        message = AppStrings.networkError;
        break;
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      originalError: error,
    );
  }

  /// Handle general exceptions
  static ApiException handleException(dynamic error) {
    if (error is ApiException) {
      return error;
    }

    if (error is DioException) {
      return handleDioException(error);
    }

    return ApiException(
      message: error.toString().isEmpty ? AppStrings.unknownError : error.toString(),
      originalError: error,
    );
  }

  /// Get error message based on status code
  static String _getMessageFromStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request. Please check your input.';
      case 401:
        return AppStrings.unauthorized;
      case 403:
        return 'Access forbidden.';
      case 404:
        return 'Resource not found.';
      case 409:
        return 'Conflict with existing data.';
      case 422:
        return 'Validation failed. Please check your input.';
      case 429:
        return 'Too many requests. Please try again later.';
      case 500:
        return AppStrings.serverError;
      case 502:
        return 'Bad gateway. Please try again.';
      case 503:
        return 'Service unavailable. Please try again later.';
      case 504:
        return 'Gateway timeout. Please try again.';
      default:
        return AppStrings.unknownError;
    }
  }

  /// Check if error is network related
  static bool isNetworkError(ApiException exception) {
    final statusCode = exception.statusCode;
    return statusCode == -1 || statusCode == -2 || statusCode == -3 || statusCode == -7;
  }

  /// Check if error is authentication related
  static bool isAuthError(ApiException exception) {
    return exception.statusCode == 401 || exception.statusCode == 403;
  }

  /// Check if error is validation related
  static bool isValidationError(ApiException exception) {
    return exception.statusCode == 400 || exception.statusCode == 422;
  }

  /// Check if error is server related
  static bool isServerError(ApiException exception) {
    final statusCode = exception.statusCode;
    return statusCode != null && statusCode >= 500 && statusCode < 600;
  }

  /// Check if error is timeout
  static bool isTimeoutError(ApiException exception) {
    final statusCode = exception.statusCode;
    return statusCode == -2 || statusCode == -3 || statusCode == 504;
  }

  /// Check if error is retryable
  static bool isRetryable(ApiException exception) {
    return isNetworkError(exception) ||
        isTimeoutError(exception) ||
        isServerError(exception) ||
        exception.statusCode == 429; // Rate limited
  }
}

/// Result wrapper for operations
class Result<T> {
  final T? data;
  final ApiException? error;

  Result({
    this.data,
    this.error,
  });

  /// Success result
  factory Result.success(T data) {
    return Result(data: data);
  }

  /// Error result
  factory Result.error(ApiException error) {
    return Result(error: error);
  }

  /// Check if result is success
  bool get isSuccess => error == null && data != null;

  /// Check if result is error
  bool get isError => error != null;

  /// Get result or null
  T? getOrNull() => data;

  /// Get error or null
  ApiException? getErrorOrNull() => error;

  /// Fold result
  R fold<R>(
    R Function(ApiException) onError,
    R Function(T) onSuccess,
  ) {
    if (isError) {
      return onError(error!);
    }
    return onSuccess(data as T);
  }

  /// Map data
  Result<U> map<U>(U Function(T) transform) {
    if (isError) {
      return Result<U>(error: error);
    }
    return Result<U>(data: transform(data as T));
  }
}

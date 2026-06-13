import 'package:dio/dio.dart';
import 'package:get/get.dart' as getx;
import '../constants/app_constants.dart';
import '../storage/preferences.dart';

class ApiClient {
  late Dio _dio;
  final Preferences _preferences = getx.Get.find<Preferences>();

  ApiClient() {
    _initializeDio();
  }

  /// Initialize Dio with interceptors
  void _initializeDio() {
    final baseOptions = BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(milliseconds: 30000),
      receiveTimeout: const Duration(milliseconds: 30000),
      contentType: 'application/json',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    _dio = Dio(baseOptions);

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );

    // Add retry interceptor for 401 errors
    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onError: (error, handler) async {
          // Handle 401 unauthorized - refresh token and retry
          if (error.response?.statusCode == 401) {
            try {
              await _refreshToken();
              // Retry the original request with new token
              return handler.resolve(await _dio.request(
                error.requestOptions.path,
                data: error.requestOptions.data,
                queryParameters: error.requestOptions.queryParameters,
                options: Options(
                  method: error.requestOptions.method,
                  headers: error.requestOptions.headers,
                ),
              ));
            } catch (e) {
              return handler.reject(error);
            }
          }
          return handler.reject(error);
        },
      ),
    );
  }

  /// Request interceptor
  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Add authorization token if available
    final token = await _preferences.getAccessToken();
    if (token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    print('🔵 API Request: ${options.method.toUpperCase()} ${options.path}');
    return handler.next(options);
  }

  /// Response interceptor
  void _onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    print('🟢 API Response: ${response.statusCode} ${response.requestOptions.path}');
    return handler.next(response);
  }

  /// Error interceptor
  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    print('🔴 API Error: ${error.response?.statusCode} ${error.message}');
    return handler.next(error);
  }

  /// Refresh access token using refresh token
  Future<void> _refreshToken() async {
    try {
      final refreshToken = await _preferences.getRefreshToken();

      if (refreshToken.isEmpty) {
        throw DioException(
          requestOptions: RequestOptions(path: ''),
          message: 'No refresh token available',
        );
      }

      final response = await _dio.post(
        AppConstants.tokenRefreshUrl,
        data: {'refreshToken': refreshToken},
        options: Options(
          headers: {
            'Authorization': 'Bearer $refreshToken',
          },
        ),
      );

      final newAccessToken = response.data['data']['accessToken'];
      final newRefreshToken = response.data['data']['refreshToken'];

      // Save new tokens
      await _preferences.setAccessToken(newAccessToken);
      await _preferences.setRefreshToken(newRefreshToken);
    } catch (e) {
      // Clear tokens and logout on failure
      await _preferences.clear();
      rethrow;
    }
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
    } on DioException {
      rethrow;
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
    } on DioException {
      rethrow;
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
    } on DioException {
      rethrow;
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
    } on DioException {
      rethrow;
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
    } on DioException {
      rethrow;
    }
  }

  /// Upload file
  Future<Response> uploadFile(
    String path,
    String filePath, {
    String fieldName = 'file',
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final file = await MultipartFile.fromFile(filePath);
      final formData = FormData.fromMap({
        fieldName: file,
        if (additionalData != null) ...additionalData,
      });

      final response = await _dio.post(
        path,
        data: formData,
      );
      return response;
    } on DioException {
      rethrow;
    }
  }

  /// Upload multiple files
  Future<Response> uploadFiles(
    String path,
    List<String> filePaths, {
    String fieldName = 'files',
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final files = <MultipartFile>[];
      for (final filePath in filePaths) {
        files.add(await MultipartFile.fromFile(filePath));
      }

      final formData = FormData.fromMap({
        fieldName: files,
        if (additionalData != null) ...additionalData,
      });

      final response = await _dio.post(
        path,
        data: formData,
      );
      return response;
    } on DioException {
      rethrow;
    }
  }

  /// Dispose resources
  void dispose() {
    _dio.close();
  }
}

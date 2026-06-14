import 'package:dio/dio.dart';
import 'package:get/get.dart' as getx;
import '../constants/app_constants.dart';
import '../storage/preferences.dart';
import '../../routes/app_pages.dart';

class ApiClient {
  late Dio _dio;
  final Preferences _preferences = getx.Get.find<Preferences>();

  ApiClient() {
    _initializeDio();
  }

  void _initializeDio() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(milliseconds: 30000),
      receiveTimeout: const Duration(milliseconds: 30000),
      contentType: 'application/json',
      headers: {'Accept': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: _onRequest,
      onError: _onError,
    ));
  }

  Future<void> _onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _preferences.getAccessToken();
    if (token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  Future<void> _onError(DioException error, ErrorInterceptorHandler handler) async {
    if (error.response?.statusCode == 401) {
      await _preferences.clearAuthTokens();
      getx.Get.offAllNamed(Routes.splash);
    }
    return handler.next(error);
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters, Options? options}) =>
      _dio.get(path, queryParameters: queryParameters, options: options);

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) =>
      _dio.post(path, data: data, queryParameters: queryParameters, options: options);

  Future<Response> patch(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) =>
      _dio.patch(path, data: data, queryParameters: queryParameters, options: options);

  Future<Response> put(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) =>
      _dio.put(path, data: data, queryParameters: queryParameters, options: options);

  Future<Response> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) =>
      _dio.delete(path, data: data, queryParameters: queryParameters, options: options);

  void dispose() => _dio.close();
}

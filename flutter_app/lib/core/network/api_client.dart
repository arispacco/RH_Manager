import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

import '../constants/app_constants.dart';

/// Configures the global [Dio] instance with interceptors for
/// authentication, logging, and error handling.
class ApiClient {
  ApiClient({
    required FlutterSecureStorage secureStorage,
  }) : _secureStorage = secureStorage {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
        receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(secureStorage: _secureStorage),
      _LoggingInterceptor(),
    ]);
  }

  late final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  Dio get dio => _dio;
}

/// Injects the stored access token into every outgoing request.
class _AuthInterceptor extends Interceptor {
  _AuthInterceptor({required FlutterSecureStorage secureStorage})
      : _secureStorage = secureStorage;

  final FlutterSecureStorage _secureStorage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _secureStorage.read(key: AppConstants.accessTokenKey);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // TODO: Implement token refresh on 401
    handler.next(err);
  }
}

/// Logs requests and responses for debugging.
class _LoggingInterceptor extends Interceptor {
  final _logger = Logger(
    printer: PrettyPrinter(methodCount: 0, dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart),
  );

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.i('→ ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logger.i('← ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.e('✖ ${err.response?.statusCode} ${err.requestOptions.uri}',
        error: err.message);
    handler.next(err);
  }
}

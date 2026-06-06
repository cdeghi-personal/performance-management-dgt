import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_interceptor.dart';
import '../auth/session_manager.dart';
import '../config/app_config.dart';
import '../error/sydle_exception.dart';

final sydleClientProvider = Provider<SydleClient>(
  (ref) => SydleClient(ref.read(sessionManagerProvider)),
);

/// Camada HTTP central do SYDLE ONE.
///
/// Todas as chamadas de negócio são POST para:
///   POST <baseUrl>/main/<pacote>/<classe>/<metodo>
///
/// Headers fixos em toda requisição:
///   Authorization: Bearer <token>   ← injetado pelo AuthInterceptor
///   X-Explorer-Account-Token: <org>
class SydleClient {
  late final Dio _dio;

  SydleClient(SessionManager session) {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      contentType: 'application/json',
      headers: {
        'X-Explorer-Account-Token': AppConfig.organization,
      },
    ));

    _dio.interceptors.add(AuthInterceptor(session));
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));
  }

  /// Executa POST para /<package>/<class>/<method> com body opcional.
  Future<dynamic> call(
    String package,
    String className,
    String method, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final resp = await _dio.post(
        '/$package/$className/$method',
        data: body ?? {},
      );
      return resp.data;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  SydleException _mapError(DioException e) {
    final status = e.response?.statusCode;
    final msg = e.response?.data?.toString() ?? e.message ?? 'Erro desconhecido';
    if (status == 401 || status == 403) return SydleAuthException(msg);
    if (status == 404) return SydleNotFoundException(msg);
    return SydleException(msg, statusCode: status, raw: e.response?.data);
  }
}

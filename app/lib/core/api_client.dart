import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'config.dart';

final secureStorageProvider = Provider((_) => const FlutterSecureStorage());

/// Cliente HTTP que anexa o token JWT salvo em toda requisição.
final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: apiUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.read(key: tokenKey);
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
    ),
  );
  return dio;
});

const tokenKey = 'access_token';

/// Extrai uma mensagem amigável de um erro da API.
String apiErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      final msg = data['message'];
      return msg is List ? msg.join('\n') : msg.toString();
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return 'Não foi possível conectar ao servidor.';
    }
  }
  return 'Algo deu errado. Tente novamente.';
}

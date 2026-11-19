import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/api_client.dart';
import 'auth_user.dart';

final authRepositoryProvider = Provider(
  (ref) =>
      AuthRepository(ref.watch(dioProvider), ref.watch(secureStorageProvider)),
);

class AuthRepository {
  AuthRepository(this._dio, this._storage);

  final Dio _dio;
  final FlutterSecureStorage _storage;

  Future<AuthUser> login(String email, String password) =>
      _session('/auth/login', {'email': email, 'password': password});

  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    required UserRole role,
  }) => _session('/auth/register', {
    'name': name,
    'email': email,
    'password': password,
    if (phone != null && phone.isNotEmpty) 'phone': phone,
    'role': role == UserRole.owner ? 'OWNER' : 'CLIENT',
  });

  /// Restaura a sessão a partir do token salvo. Retorna null se não houver.
  Future<AuthUser?> currentUser() async {
    if (await _storage.read(key: tokenKey) == null) return null;
    try {
      final res = await _dio.get<Map<String, dynamic>>('/auth/me');
      return AuthUser.fromJson(res.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await logout();
        return null;
      }
      rethrow;
    }
  }

  Future<void> logout() => _storage.delete(key: tokenKey);

  Future<AuthUser> _session(String path, Map<String, dynamic> body) async {
    final res = await _dio.post<Map<String, dynamic>>(path, data: body);
    await _storage.write(
      key: tokenKey,
      value: res.data!['accessToken'] as String,
    );
    return AuthUser.fromJson(res.data!['user'] as Map<String, dynamic>);
  }
}

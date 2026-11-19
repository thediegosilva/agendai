import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/auth_repository.dart';
import 'data/auth_user.dart';

/// Estado global de autenticação: `null` = deslogado.
final authControllerProvider = AsyncNotifierProvider<AuthController, AuthUser?>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<AuthUser?> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  Future<AuthUser?> build() => _repo.currentUser();

  Future<void> login(String email, String password) async {
    state = await AsyncValue.guard(() => _repo.login(email, password));
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    required UserRole role,
  }) async {
    state = await AsyncValue.guard(
      () => _repo.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        role: role,
      ),
    );
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AsyncData(null);
  }
}

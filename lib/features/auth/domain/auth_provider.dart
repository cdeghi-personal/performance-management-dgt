import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../../../core/error/sydle_exception.dart';
import 'auth_model.dart';

final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final user = await ref.read(authRepositoryProvider).restoreSession();
    return AuthState(isAuthenticated: user != null, user: user);
  }

  Future<void> login({required String username, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = await ref
          .read(authRepositoryProvider)
          .login(username: username, password: password);
      return AuthState(isAuthenticated: true, user: user);
    });
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(AuthState(isAuthenticated: false));
  }

  /// Chama após login para atualizar nome/role vindos do perfil SYDLE.
  void updateUser(AuthUser user) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(AuthState(isAuthenticated: true, user: user));
  }

  bool get hasError => state.hasError;
  SydleAuthException? get authError {
    final err = state.error;
    return err is SydleAuthException ? err : null;
  }
}

final currentUserProvider = Provider<AuthUser?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.user;
});

final isManagerProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.isManager ?? false;
});
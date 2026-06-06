import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_interceptor.dart';
import '../../../core/auth/session_manager.dart';
import '../data/auth_repository.dart';
import 'auth_model.dart';

final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    // Ouve 401/403 do interceptor — faz logout local sem nova requisição
    final sub = authErrorStream.listen((_) {
      ref.read(sessionManagerProvider).clear();
      state = const AsyncData(AuthState(isAuthenticated: false));
    });
    ref.onDispose(sub.cancel);

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
}

// Usuário atual
final currentUserProvider = Provider<AuthUser?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.user;
});

// ID do colaborador no SYDLE — usado em queries
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider)?.colaboradorId;
});

// Perfil do usuário — usado em guards e visibilidade
final currentProfileProvider = Provider<UserProfile?>((ref) {
  return ref.watch(currentUserProvider)?.profile;
});

// Compat: true para leader e HR (acesso à equalização e time)
final isManagerProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.isManager ?? false;
});

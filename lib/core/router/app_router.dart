import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/domain/auth_model.dart';
import '../../features/auth/domain/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/goals/presentation/goals_screen.dart';
import '../../features/evaluations/presentation/evaluations_screen.dart';
import '../../features/evaluations/presentation/cycle_journey_page.dart';
import '../../features/evaluations/presentation/self_evaluation_page.dart';
import '../../features/evaluations/presentation/manager_evaluation_page.dart';
import '../../features/evaluations/presentation/equalization_page.dart';
import '../../features/evaluations/presentation/received_evaluation_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../shell/main_shell.dart';

/// ChangeNotifier que escuta authStateProvider e notifica o GoRouter para
/// re-avaliar os redirects sem recriar a instância do router (e sem destruir
/// o widget tree — evita sumir SnackBars da LoginScreen ao falhar o login).
class _AuthRouterNotifier extends ChangeNotifier {
  _AuthRouterNotifier(this._ref) {
    _ref.listen<AsyncValue<AuthState>>(
      authStateProvider,
      (_, __) => notifyListeners(),
    );
  }

  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final isAuthenticated =
        _ref.read(authStateProvider).valueOrNull?.isAuthenticated ?? false;
    final loc = state.matchedLocation;
    final isSplash = loc == '/splash';
    final isLogin  = loc == '/login';

    if (isSplash) return null; // splash gerencia sua própria navegação
    if (!isAuthenticated && !isLogin) return '/login';
    if (isAuthenticated && isLogin) return '/dashboard';
    return null;
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthRouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (ctx, _) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (ctx, _) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (ctx, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (ctx, _) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/avaliacoes',
            builder: (ctx, _) => const EvaluationsScreen(),
            routes: [
              GoRoute(
                path: 'jornada',
                builder: (ctx, _) => const CycleJourneyPage(),
              ),
              GoRoute(
                path: 'auto',
                builder: (ctx, _) => const SelfEvaluationPage(),
              ),
              GoRoute(
                path: 'auto/:evalId',
                builder: (ctx, s) => SelfEvaluationPage(
                  evalId: s.pathParameters['evalId'],
                ),
              ),
              GoRoute(
                path: 'recebida/:evalId',
                builder: (ctx, s) => ReceivedEvaluationPage(
                  evalId: s.pathParameters['evalId']!,
                ),
              ),
              GoRoute(
                path: 'gestor/:employeeId',
                builder: (ctx, s) => ManagerEvaluationPage(
                  employeeId: s.pathParameters['employeeId']!,
                ),
              ),
              GoRoute(
                path: 'gestor/historico/:evalId',
                builder: (ctx, s) => ManagerEvaluationPage(
                  evalId: s.pathParameters['evalId']!,
                ),
              ),
              GoRoute(
                path: 'equalizacao',
                builder: (ctx, _) => const EqualizationPage(),
              ),
            ],
          ),
          GoRoute(
            path: '/metas',
            builder: (ctx, _) => const GoalsScreen(),
          ),
          GoRoute(
            path: '/perfil',
            builder: (ctx, _) => const ProfilePage(),
          ),
        ],
      ),
    ],
  );
});
